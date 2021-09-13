# Dockerized export server for Highcharts

An image to run a Highcharts export server.

```
ghcr.io/interactive-studios/dockerized-highcharts-export-server:main
```

## Requirements

 * Docker 19.03.8+
 * Compose 1.24.1+

 ## Setup

To run the server simply run
```console
docker run --rm -p 7801:7801 ghcr.io/interactive-studios/dockerized-highcharts-export-server:main
```

And you can connect to `localhost:7801` to generate any charts.

## License
When running this image, you're automatically accepting the license terms of Highcharts.js.
