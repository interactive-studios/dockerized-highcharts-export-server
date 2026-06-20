#!/bin/sh
set -e

# Chromium's namespace sandbox needs kernel features some hosts don't expose (e.g. Docker Desktop's
# VM, or hosts without SYS_ADMIN). When opted in, run with the no-sandbox config baked at build time.
EXTRA_ARGS=""
if [ "$DISABLE_CHROMIUM_SANDBOX" = "true" ]; then
	if [ ! -f puppeteer-no-sandbox.json ]; then
		echo "DISABLE_CHROMIUM_SANDBOX=true but puppeteer-no-sandbox.json is missing" >&2
		exit 1
	fi
	EXTRA_ARGS="--loadConfig puppeteer-no-sandbox.json"
fi

exec ./node_modules/.bin/highcharts-export-server --enableServer true $EXTRA_ARGS "$@"
