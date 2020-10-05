# Dockerized export server for Highcharts

![Build Status](https://img.shields.io/docker/build/interactivestudios/dockerized-highcharts-export-server)
 
An image to run a Highcharts export server.

See the [Docker hub](https://hub.docker.com/repository/docker/interactivestudios/dockerized-highcharts-export-server) for more information.

## Requirements

 * Docker 19.03.8+
 * Compose 1.24.1+

 ## Setup

To run the server simply run
```console
docker run --rm -p 7801:7801 interactivestudios/dockerized-highcharts-export-server:latest
```

And you can connect to `localhost:7801` to generate any charts.
