FROM node:16

ENV ACCEPT_HIGHCHARTS_LICENSE 1
ENV HIGHCHARTS_VERSION "latest"
ENV HIGHCHARTS_USE_STYLED 1
ENV HIGHCHARTS_USE_MAPS 0
ENV HIGHCHARTS_MOMENT 0
ENV HIGHCHARTS_USE_GANTT 0

# Use a specific user to do these actions
ARG UID=12000
ARG GID=12001
ARG UNAME=highcharts
# Add the user with a static UID and statid GID
RUN groupadd --gid $GID $UNAME && useradd --uid $UID --gid $UNAME $UNAME
RUN mkdir /home/highcharts
RUN chown -R $UID:$GID /home/highcharts

# Log in as the newly created user
USER $UNAME

WORKDIR /home/highcharts

RUN npm install highcharts-export-server

RUN node ./node_modules/highcharts-export-server/build.js

EXPOSE 7801

# Migrate and start webserver
CMD ["sh","-c","./node_modules/.bin/highcharts-export-server --enableServer 1 --workLimit 20"]