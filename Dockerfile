FROM node:12

ENV ACCEPT_HIGHCHARTS_LICENSE 1
ENV HIGHCHARTS_VERSION "latest"
ENV HIGHCHARTS_USE_STYLED 1
ENV HIGHCHARTS_USE_MAPS 0
ENV HIGHCHARTS_MOMENT 0
ENV HIGHCHARTS_USE_GANTT 0

WORKDIR /server

RUN npm install highcharts-export-server

RUN node ./node_modules/highcharts-export-server/build.js

EXPOSE 7801

# Migrate and start webserver
CMD ["sh","-c","./node_modules/.bin/highcharts-export-server --enableServer 1"]
