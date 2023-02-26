FROM node:18@sha256:586cdef48f920dea2f47a954b8717601933aa1daa0a08264abf9144789abf8ae

ENV OPENSSL_CONF=/etc/ssl/

# Use a specific user to do these actions
ARG UID=12000
ARG GID=12001
ARG UNAME=highcharts

# We don't need the standalone Chromium
ENV PUPPETEER_SKIP_CHROMIUM_DOWNLOAD true
ENV PUPPETEER_EXECUTABLE_PATH /usr/bin/chromium

# Install Chromium Stable and fonts
# Note: this installs the necessary libs to make the browser work with Puppeteer.
RUN apt-get update && apt-get install -y \
  chromium \
  chromium-l10n \
  fonts-liberation \
  fonts-roboto \
  hicolor-icon-theme \
  libcanberra-gtk-module \
  libexif-dev \
  libgl1-mesa-dri \
  libgl1-mesa-glx \
  libpangox-1.0-0 \
  libv4l-0 \
  fonts-symbola \
  --no-install-recommends \
  && rm -rf /var/lib/apt/lists/* \
  && mkdir -p /etc/chromium.d/ 

ADD https://github.com/Yelp/dumb-init/releases/download/v1.2.2/dumb-init_1.2.2_x86_64 /usr/local/bin/dumb-init
RUN chmod +x /usr/local/bin/dumb-init

ENTRYPOINT ["dumb-init", "--"]

# Add the user with a static UID and statid GID
RUN groupadd --gid $GID $UNAME && useradd --uid $UID --gid $UNAME $UNAME && \ 
  mkdir /home/highcharts && \
  chown -R $UID:$GID /home/highcharts

# Log in as the newly created user
USER $UNAME

ENV ACCEPT_HIGHCHARTS_LICENSE 1
ENV HIGHCHARTS_USE_STYLED 0
ENV HIGHCHARTS_MOMENT 1
ENV HIGHCHARTS_USE_NPM 1
ENV HIGHCHARTS_VERSION 'latest'

WORKDIR /home/highcharts

RUN git clone https://github.com/highcharts/node-export-server.git . && \
  git checkout enhancement/puppeteer && \
  npm install 

EXPOSE 7801

COPY --chown=$UID:$GUID ./.hcexport ./.hcexport

# Migrate and start webserver
CMD ["npm", "run", "start", "--", "--loadConfig", ".hcexport"]
