# Doesn't work above Node 14
FROM node:14

ENV ACCEPT_HIGHCHARTS_LICENSE 1
ENV HIGHCHARTS_VERSION "9.2.2"
ENV HIGHCHARTS_USE_STYLED 1
ENV HIGHCHARTS_USE_MAPS 0
ENV HIGHCHARTS_MOMENT 0
ENV HIGHCHARTS_USE_GANTT 0

ENV OPENSSL_CONF=/etc/ssl/

# Use a specific user to do these actions
ARG UID=12000
ARG GID=12001
ARG UNAME=highcharts

# Add the user with a static UID and statid GID
RUN groupadd --gid $GID $UNAME && useradd --uid $UID --gid $UNAME $UNAME && \ 
	mkdir /home/highcharts && \
	chown -R $UID:$GID /home/highcharts

# Log in as the newly created user
USER $UNAME

WORKDIR /home/highcharts

RUN git clone https://github.com/highcharts/node-export-server.git --depth 1 . && \
	git fetch --depth=1 origin 14d94276c06bca38741f259625cefd7bbd9d6dae && \
	git checkout 14d94276c06bca38741f259625cefd7bbd9d6dae && \
	npm install --production && \
	node build.js

EXPOSE 7801

# Migrate and start webserver
CMD ["sh","-c","./bin/cli.js --enableServer 1 --logLevel 4 --workLimit 20"]
