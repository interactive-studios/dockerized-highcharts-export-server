FROM node:23-alpine

# Installs Chromium (100) package.
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

RUN npm install

EXPOSE 7801

# Migrate and start webserver
CMD ["./node_modules/.bin/highcharts-export-server", "--enableServer" ,"true"]
