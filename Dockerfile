# Keep this version the same as the one used in highcharts-export-server
FROM node:22

ENV \
    # Configure default locale (important for chrome-headless-shell).
    LANG=en_US.UTF-8 \
    # UID of the non-root user 'pptruser'
    PPTRUSER_UID=10042

# Install latest chrome dev package and fonts to support major charsets (Chinese, Japanese, Arabic, Hebrew, Thai and a few others)
# Note: this installs the necessary libs to make the bundled version of Chrome that Puppeteer
# installs, work.
RUN apt-get update \
    && apt-get install -y --no-install-recommends fonts-ipafont-gothic fonts-wqy-zenhei fonts-thai-tlwg fonts-khmeros \
    fonts-kacst fonts-freefont-ttf dbus dbus-x11 ca-certificates fonts-liberation libasound2 libatk-bridge2.0-0 libatk1.0-0 libc6 libcairo2 \
    libcups2 libdbus-1-3 libexpat1 libfontconfig1 libgbm1 libgcc1 libglib2.0-0 libgtk-3-0 libnspr4 libnss3 libpango-1.0-0 libpangocairo-1.0-0 \
    libstdc++6 libx11-6 libx11-xcb1 libxcb1 libxcomposite1 libxcursor1 libxdamage1 libxext6 libxfixes3 libxi6 libxrandr2 libxrender1 \
    libxss1 libxtst6 lsb-release wget xdg-utils

# Add pptruser.
RUN groupadd -r pptruser && useradd -u $PPTRUSER_UID -rm -g pptruser -G audio,video pptruser

USER $PPTRUSER_UID

WORKDIR /home/pptruser

ENV DBUS_SESSION_BUS_ADDRESS autolaunch:

WORKDIR /home/pptruser
VOLUME /home/pptruser/highcharts-cache

ENV HIGHCHARTS_CACHE_PATH '../../highcharts-cache'
ENV PUPPETEER_CACHE_DIR '/home/pptruser/.cache/puppeteer'
ENV PUPPETEER_SKIP_DOWNLOAD 'true'

RUN mkdir -p /home/pptruser/highcharts-cache && \
    npm install highcharts-export-server

USER root
RUN npx puppeteer browsers install chrome-headless-shell --install-deps
USER $PPTRUSER_UID

EXPOSE 7801

# Migrate and start webserver
#CMD ["bash"]
CMD ["./node_modules/.bin/highcharts-export-server", "--enableServer" ,"true"]
