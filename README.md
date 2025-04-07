# Dockerized export server for Highcharts

An image to run a Highcharts export server.

```
ghcr.io/interactive-studios/dockerized-highcharts-export-server
```

## Requirements
 * Docker 19.03.8+

 ## Setup

To run the server simply run
```console
docker run --rm \
    -v highcharts-cache:/cache \
    --cap-add=SYS_ADMIN \
    -p 7801:7801 \
    ghcr.io/interactive-studios/dockerized-highcharts-export-server
```

And you can connect to `localhost:7801` to generate any charts.

## Verify

You can verify if the server works correctly by executing:
```shell
curl \
	-H "Content-Type: application/json" \
	-X POST \
	-d '{"infile":{"title": {"text": "Steep Chart"}, "xAxis": {"categories": ["Jan", "Feb", "Mar"]}, "series": [{"data": [29.9, 71.5, 106.4]}]}}' \
	localhost:7801 \
	-o mychart.png
```

This creates an `mychart.png` image. If you open the image, it should show a graph.

## License
When running this image, you're automatically accepting the license terms of Highcharts.js.
