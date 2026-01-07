# Dockerized Export Server for Highcharts

A Docker image to run a Highcharts export server using [node-export-server](https://github.com/highcharts/node-export-server).

## Features

- Multi-architecture support (amd64, arm64)
- Runs as non-root user for security
- Persistent caching for improved performance
- Configurable worker pool for memory optimization

## Requirements

- Docker 20.10+

## Quick Start

```shell
docker run -d \
    --name highcharts-export \
    -v highcharts-cache:/cache \
    --cap-add=SYS_ADMIN \
    -p 7801:7801 \
    ghcr.io/interactive-studios/dockerized-highcharts-export-server
```

The server is now available at `http://localhost:7801`.

## Usage

### Docker Compose

```yaml
services:
  highcharts:
    image: ghcr.io/interactive-studios/dockerized-highcharts-export-server
    restart: unless-stopped
    volumes:
      - highcharts-cache:/cache
    ports:
      - 7801:7801
    cap_add:
      - SYS_ADMIN
    environment:
      - POOL_MIN_WORKERS=1
      - POOL_MAX_WORKERS=4

volumes:
  highcharts-cache:
```

### Export a Chart

```shell
curl \
    -H "Content-Type: application/json" \
    -X POST \
    -d '{"infile":{"title": {"text": "Steep Chart"}, "xAxis": {"categories": ["Jan", "Feb", "Mar"]}, "series": [{"data": [29.9, 71.5, 106.4]}]}}' \
    localhost:7801 \
    -o chart.png
```

### Export Formats

Specify the output format using the `type` parameter:

```shell
# PNG (default)
curl -X POST -H "Content-Type: application/json" \
    -d '{"type": "png", "infile": {...}}' \
    localhost:7801 -o chart.png

# SVG
curl -X POST -H "Content-Type: application/json" \
    -d '{"type": "svg", "infile": {...}}' \
    localhost:7801 -o chart.svg

# PDF
curl -X POST -H "Content-Type: application/json" \
    -d '{"type": "pdf", "infile": {...}}' \
    localhost:7801 -o chart.pdf
```

## Configuration

### Environment Variables

| Variable | Default | Description |
|----------|---------|-------------|
| `POOL_MIN_WORKERS` | `1` | Minimum number of worker processes |
| `POOL_MAX_WORKERS` | `4` | Maximum number of worker processes |
| `HIGHCHARTS_CACHE_PATH` | `../../../../cache` | Path to cache directory |

### Performance Tuning

Adjust worker pool size based on your workload and available memory:

```shell
docker run -d \
    -e POOL_MIN_WORKERS=2 \
    -e POOL_MAX_WORKERS=8 \
    -v highcharts-cache:/cache \
    --cap-add=SYS_ADMIN \
    -p 7801:7801 \
    ghcr.io/interactive-studios/dockerized-highcharts-export-server
```

**Memory guidelines:**
- Each worker uses approximately 100-200 MB of memory
- For 1 GB available: use 2-4 workers
- For 2 GB available: use 4-8 workers
- For 4 GB+ available: use 8-16 workers

### Resource Limits

For production deployments, set resource limits:

```yaml
services:
  highcharts:
    image: ghcr.io/interactive-studios/dockerized-highcharts-export-server
    deploy:
      resources:
        limits:
          memory: 2G
        reservations:
          memory: 512M
    # ... other settings
```

## Security

### Why SYS_ADMIN Capability?

The `SYS_ADMIN` capability is required for Chromium's sandboxing features. Without it, Chromium cannot create the necessary namespaces for process isolation.

For environments where `SYS_ADMIN` is not available, you can disable the sandbox (not recommended for production):

```shell
docker run -d \
    -e PUPPETEER_ARGS="--no-sandbox --disable-setuid-sandbox" \
    -v highcharts-cache:/cache \
    -p 7801:7801 \
    ghcr.io/interactive-studios/dockerized-highcharts-export-server
```

### Non-Root Execution

The server runs as a non-root `highcharts` user inside the container for improved security.

## Troubleshooting

### Container fails to start

1. Ensure Docker has enough memory allocated (minimum 512 MB)
2. Verify the `SYS_ADMIN` capability is added
3. Check logs: `docker logs <container-id>`

### Out of memory errors

- Reduce `POOL_MAX_WORKERS` value
- Increase Docker memory limits
- Monitor memory usage: `docker stats <container-id>`

### Slow chart generation

- Increase `POOL_MIN_WORKERS` to keep workers warm
- Ensure the cache volume is mounted for persistent caching
- Check if the container has sufficient CPU resources

### Permission denied errors

- Verify the cache volume has correct permissions
- The container runs as UID 1000 (highcharts user)

## API Reference

For full API documentation, see the [node-export-server documentation](https://github.com/highcharts/node-export-server#readme).

Common request parameters:

| Parameter | Type | Description |
|-----------|------|-------------|
| `infile` | object | Highcharts configuration object |
| `type` | string | Output format: `png`, `svg`, `pdf`, `jpeg` |
| `width` | number | Output width in pixels |
| `scale` | number | Scale factor for the output |
| `constr` | string | Chart constructor: `Chart`, `StockChart`, `MapChart`, `GanttChart` |

## License

This project is licensed under the MIT License. See the [LICENSE](LICENSE) file for details.

When running this image, you're automatically accepting the [Highcharts license terms](https://www.highcharts.com/license).
