import { execFileSync } from "node:child_process";
import { readFileSync, writeFileSync, mkdirSync } from "node:fs";
import { dirname, join } from "node:path";
import { fileURLToPath } from "node:url";
import { after, before, describe, test } from "node:test";
import assert from "node:assert/strict";
import { PNG } from "pngjs";
import pixelmatch from "pixelmatch";

const testDir = dirname(fileURLToPath(import.meta.url));
const repoRoot = join(testDir, "..");

const IMAGE = "highcharts-export-test";
const CONTAINER = "hc-export-test";
const BASE_URL = "http://localhost:7801";
const HEALTH_TIMEOUT_MS = 60_000;
const UPDATE_BASELINES = process.env.UPDATE_BASELINES === "1";

// Generous tolerance: anti-aliasing and font hinting differ across Chromium/Highcharts bumps and
// CPU architectures, so we only want to catch gross rendering breakage (blank/garbage output).
const VR_MISMATCH_TOLERANCE = 0.02;

// How to run the container. Each mode reflects a different security posture, exercised in CI to find
// which sandboxed configuration actually renders on a real Linux host:
//   no-sandbox — Chromium sandbox off (works on any host, incl. Docker Desktop); the local default
//   default    — sandbox on, no extra privilege (relies on the host's default seccomp + user namespaces)
//   sys-admin  — sandbox on, granted CAP_SYS_ADMIN
const RUN_MODE = process.env.RUN_MODE || "no-sandbox";

const RUN_ARGS_BY_MODE = {
	"no-sandbox": ["-e", "DISABLE_CHROMIUM_SANDBOX=true"],
	default: [],
	"sys-admin": ["--cap-add=SYS_ADMIN"],
};

const chartConfig = JSON.parse(readFileSync(join(testDir, "fixtures", "chart.json"), "utf8"));

function docker(args, options = {}) {
	return execFileSync("docker", args, { encoding: "buffer", ...options });
}

async function waitForHealth(deadline) {
	while (Date.now() < deadline) {
		try {
			const response = await fetch(`${BASE_URL}/health`);
			if (response.ok) return;
		} catch {
			// Server not up yet — keep polling.
		}
		await new Promise((resolve) => setTimeout(resolve, 1_000));
	}
	throw new Error("Container did not become healthy within timeout");
}

async function render(body) {
	const response = await fetch(BASE_URL, {
		method: "POST",
		headers: { "Content-Type": "application/json" },
		body: JSON.stringify(body),
	});
	assert.equal(response.status, 200, `expected 200, got ${response.status}`);
	return Buffer.from(await response.arrayBuffer());
}

describe("dockerized highcharts export server", () => {
	before(async () => {
		const modeArgs = RUN_ARGS_BY_MODE[RUN_MODE];
		if (!modeArgs) throw new Error(`Unknown RUN_MODE: ${RUN_MODE}`);

		docker(["build", "-t", IMAGE, "."], { cwd: repoRoot, stdio: "inherit" });
		docker(["rm", "-f", CONTAINER], { stdio: "ignore" }); // clear any stale container
		docker(["run", "-d", "--name", CONTAINER, ...modeArgs, "-p", "7801:7801", IMAGE]);
		await waitForHealth(Date.now() + HEALTH_TIMEOUT_MS);
	}, { timeout: 300_000 });

	after(() => {
		docker(["rm", "-f", CONTAINER], { stdio: "ignore" });
	});

	test("GET /health returns 200", async () => {
		const response = await fetch(`${BASE_URL}/health`);
		assert.equal(response.status, 200);
	});

	const renderFormats = [
		{
			type: "png",
			verify: (buffer) => {
				assert.ok(buffer.length > 1_000, `PNG too small: ${buffer.length} bytes`);
				assert.deepEqual([...buffer.subarray(0, 4)], [0x89, 0x50, 0x4e, 0x47]);
			},
		},
		{
			type: "svg",
			verify: (buffer) => assert.ok(buffer.toString("utf8").includes("<svg")),
		},
		{
			type: "pdf",
			verify: (buffer) => assert.equal(buffer.subarray(0, 4).toString("ascii"), "%PDF"),
		},
		{
			type: "jpeg",
			verify: (buffer) => assert.deepEqual([...buffer.subarray(0, 3)], [0xff, 0xd8, 0xff]),
		},
	];

	for (const { type, verify } of renderFormats) {
		test(`renders a valid ${type.toUpperCase()}`, async () => {
			verify(await render({ type, infile: chartConfig }));
		});
	}

	test("runs as a non-root user", () => {
		const uid = docker(["exec", CONTAINER, "id", "-u"]).toString().trim();
		assert.notEqual(uid, "0", "container should not run as root");
	});

	test("PNG matches visual baseline within tolerance", async () => {
		const png = await render({ type: "png", scale: 1, width: 600, infile: chartConfig });
		const baselinePath = join(testDir, "baselines", "chart.png");

		if (UPDATE_BASELINES) {
			mkdirSync(dirname(baselinePath), { recursive: true });
			writeFileSync(baselinePath, png);
			return;
		}

		// Persist the render so CI can surface it as an artifact when the comparison fails (e.g. to
		// recover an architecture-specific baseline).
		const outputDir = join(testDir, "__output__");
		mkdirSync(outputDir, { recursive: true });
		writeFileSync(join(outputDir, "chart.actual.png"), png);

		const candidate = PNG.sync.read(png);
		const baseline = PNG.sync.read(readFileSync(baselinePath));

		assert.equal(candidate.width, baseline.width, "width differs from baseline");
		assert.equal(candidate.height, baseline.height, "height differs from baseline");

		const mismatched = pixelmatch(
			candidate.data,
			baseline.data,
			null,
			candidate.width,
			candidate.height,
			{ threshold: 0.1 },
		);
		const ratio = mismatched / (candidate.width * candidate.height);
		assert.ok(
			ratio <= VR_MISMATCH_TOLERANCE,
			`visual mismatch ${(ratio * 100).toFixed(2)}% exceeds ${VR_MISMATCH_TOLERANCE * 100}%`,
		);
	});
});
