FROM ghcr.io/puppeteer/puppeteer:24

USER pptruser
WORKDIR /home/pptruser

VOLUME /home/pptruser/highcharts-cache

ENV HIGHCHARTS_CACHE_PATH '../../highcharts-cache'
ENV PUPPETEER_CACHE_DIR='/home/pptruser/.cache/puppeteer'

COPY package.json /home/pptruser/package.json

EXPOSE 7801

# Migrate and start webserver
CMD ["./node_modules/.bin/highcharts-export-server", "--enableServer" ,"true"]
