FROM node:26-alpine

# Installs Chromium package.
RUN apk add --no-cache \
      chromium \
      nss \
      freetype \
      harfbuzz \
      ca-certificates \
      ttf-freefont

# Tell Puppeteer to skip installing Chrome. We'll be using the installed package.
ENV PUPPETEER_EXECUTABLE_PATH=/usr/bin/chromium-browser
ENV PUPPETEER_SKIP_DOWNLOAD=true
ENV HIGHCHARTS_CACHE_PATH=../../../../cache

VOLUME /cache

RUN addgroup -S highcharts &&  \
    adduser -S highcharts -G highcharts && \
    mkdir -p /cache &&  \
    chown -R highcharts:highcharts /cache

WORKDIR /home/highcharts
USER highcharts

COPY package.json package.json

RUN npm install --omit=dev

# Pre-build a config that mirrors the installed default Puppeteer args plus the no-sandbox flags,
# so DISABLE_CHROMIUM_SANDBOX=true keeps every default hardening flag and stays in sync on bumps.
RUN node -e 'import("./node_modules/highcharts-export-server/lib/schemas/config.js").then(({ defaultConfig }) => { const args = [...defaultConfig.puppeteer.args.value, "--no-sandbox", "--disable-setuid-sandbox"]; require("fs").writeFileSync("puppeteer-no-sandbox.json", JSON.stringify({ puppeteer: { args } })); })'

COPY --chmod=755 docker-entrypoint.sh docker-entrypoint.sh

EXPOSE 7801

# Reduce number of workers for low-memory environments
ENV POOL_MIN_WORKERS=1
ENV POOL_MAX_WORKERS=4

HEALTHCHECK --interval=30s --timeout=10s --start-period=30s --retries=3 \
    CMD wget --quiet --tries=1 --spider http://127.0.0.1:7801/health || exit 1

ENTRYPOINT ["./docker-entrypoint.sh"]
