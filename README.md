# Dockerized Export Server for Highcharts

A Docker image to run a Highcharts export server using [node-export-server](https://github.com/highcharts/node-export-server).

## Features

- Multi-architecture support (amd64, arm64)
- Runs as non-root user for security
- Persistent caching for improved performance
- Configurable worker pool for memory optimization

## Requirements

- Docker 20.10+

## Quick Start

```shell
docker run -d \
    --name highcharts-export \
    -v highcharts-cache:/cache \
    -p 7801:7801 \
    ghcr.io/interactive-studios/dockerized-highcharts-export-server
```

The server is now available at `http://localhost:7801`.

> If charts fail to render with a sandbox error, your host restricts the
> unprivileged user namespaces Chromium's sandbox needs (common on Ubuntu 23.10+
> and Docker Desktop). See [Security](#security) for how to enable the sandbox or
> disable it as a fallback.

## Usage

### Docker Compose

```yaml
services:
  highcharts:
    image: ghcr.io/interactive-studios/dockerized-highcharts-export-server
    restart: unless-stopped
    volumes:
      - highcharts-cache:/cache
    ports:
      - 7801:7801
    environment:
      - POOL_MIN_WORKERS=1
      - POOL_MAX_WORKERS=4

volumes:
  highcharts-cache:
```

### Export a Chart

```shell
curl \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"infile":{"title": {"text": "Steep Chart"}, "xAxis": {"categories": ["Jan", "Feb", "Mar"]}, "series": [{"data": [29.9, 71.5, 106.4]}]}}' \
    localhost:7801 \
    -o chart.png
```

### Export Formats

Specify the output format using the `type` parameter:

```shell
# PNG (default)
curl -X POST -H "Content-Type: application/json" \
    -d '{"type": "png", "infile": {...}}' \
    localhost:7801 -o chart.png

# SVG
curl -X POST -H "Content-Type: application/json" \
    -d '{"type": "svg", "infile": {...}}' \
    localhost:7801 -o chart.svg

# PDF
curl -X POST -H "Content-Type: application/json" \
    -d '{"type": "pdf", "infile": {...}}' \
    localhost:7801 -o chart.pdf
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `POOL_MIN_WORKERS` | `1` | Minimum number of worker processes |
| `POOL_MAX_WORKERS` | `4` | Maximum number of worker processes |
| `HIGHCHARTS_CACHE_PATH` | `../../../../cache` | Path to cache directory |
| `DISABLE_CHROMIUM_SANDBOX` | `false` | Set to `true` to run Chromium without its sandbox (see [Security](#security)) |

### Performance Tuning

Adjust worker pool size based on your workload and available memory:

```shell
docker run -d \
    -e POOL_MIN_WORKERS=2 \
    -e POOL_MAX_WORKERS=8 \
    -v highcharts-cache:/cache \
    -p 7801:7801 \
    ghcr.io/interactive-studios/dockerized-highcharts-export-server
```

**Memory guidelines:**
- Each worker uses approximately 100-200 MB of memory
- For 1 GB available: use 2-4 workers
- For 2 GB available: use 4-8 workers
- For 4 GB+ available: use 8-16 workers

### Resource Limits

For production deployments, set resource limits:

```yaml
services:
  highcharts:
    image: ghcr.io/interactive-studios/dockerized-highcharts-export-server
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 512M
    # ... other settings
```

## Security

The server renders chart configurations in a real Chromium instance, so the
browser sandbox is a meaningful defense-in-depth layer. Whether it can run is
decided by the **host**, not by flags baked into this image: Chromium's sandbox
requires **unprivileged user namespaces**.

### Choosing a configuration

**1. Sandbox on, no extra privilege (most secure — preferred).** On hosts that
allow unprivileged user namespaces, the sandbox works with the default Docker
seccomp profile and no added capabilities:

```shell
docker run -d \
    -v highcharts-cache:/cache \
    -p 7801:7801 \
    ghcr.io/interactive-studios/dockerized-highcharts-export-server
```

**2. Sandbox off (`DISABLE_CHROMIUM_SANDBOX=true`) — fallback.** When the host
restricts user namespaces and you can't change it, disable the sandbox. This
removes a security layer, so lean on the other controls below (non-root, dropped
capabilities, read-only filesystem, the default seccomp profile):

```shell
docker run -d \
    -e DISABLE_CHROMIUM_SANDBOX=true \
    -v highcharts-cache:/cache \
    -p 7801:7801 \
    ghcr.io/interactive-studios/dockerized-highcharts-export-server
```

> `--cap-add=SYS_ADMIN` is **not** a reliable way to enable the sandbox. On hosts
> that restrict unprivileged user namespaces it does not help — verified on
> GitHub's Ubuntu 24.04 runners, where the sandbox fails to render even with
> `SYS_ADMIN`. Earlier versions of this image documented it as required; it isn't.

### Hosts that restrict user namespaces

Ubuntu 23.10+ (including 24.04 and GitHub Actions runners) and Docker Desktop's
VM restrict unprivileged user namespaces by default, which blocks the sandbox. To
keep the sandbox on such a host, relax the restriction at the **host** level —
for example:

```shell
sudo sysctl -w kernel.apparmor_restrict_unprivileged_userns=0
```

(or install an AppArmor profile that grants the container user-namespace access).
If you can't change the host, use `DISABLE_CHROMIUM_SANDBOX=true`.

You can check what your own host supports by cloning this repo and running the
test suite against each mode: `RUN_MODE=default npm test`, `RUN_MODE=sys-admin
npm test`, `RUN_MODE=no-sandbox npm test`.

### Non-Root Execution

The server runs as a non-root `highcharts` user inside the container for improved security.

## Troubleshooting

### Container fails to start

1. Ensure Docker has enough memory allocated (minimum 512 MB)
2. If logs show a Chromium sandbox error, see [Security](#security) — your host likely restricts unprivileged user namespaces
3. Check logs: `docker logs <container-id>`

### Out of memory errors

- Reduce `POOL_MAX_WORKERS` value
- Increase Docker memory limits
- Monitor memory usage: `docker stats <container-id>`

### Slow chart generation

- Increase `POOL_MIN_WORKERS` to keep workers warm
- Ensure the cache volume is mounted for persistent caching
- Check if the container has sufficient CPU resources

### Permission denied errors

- Verify the cache volume has correct permissions
- The container runs as UID 1000 (highcharts user)

## API Reference

For full API documentation, see the [node-export-server documentation](https://github.com/highcharts/node-export-server#readme).

Common request parameters:

| Parameter | Type | Description |
|-----------|------|-------------|
| `infile` | object | Highcharts configuration object |
| `type` | string | Output format: `png`, `svg`, `pdf`, `jpeg` |
| `width` | number | Output width in pixels |
| `scale` | number | Scale factor for the output |
| `constr` | string | Chart constructor: `Chart`, `StockChart`, `MapChart`, `GanttChart` |

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

When running this image, you're automatically accepting the [Highcharts license terms](https://www.highcharts.com/license).
