# Docker Support for domain-check

This document describes how to use domain-check with Docker and Docker Compose.

## Quick Start

### Using Docker (without compose)

```bash
# Build the image
docker build -t domain-check:latest .

# Check a single domain
docker run --rm domain-check:latest example.com

# Check with options
docker run --rm domain-check:latest myapp -t com,io,ai --pretty

# Check all TLDs
docker run --rm domain-check:latest mystartup --all

# Use with environment variables
docker run --rm -e DC_PRESET=startup -e DC_PRETTY=true domain-check:latest myapp
```

### Using Docker Compose

```bash
# Build and run with a single command
docker-compose run --rm domain-check example.com

# Check with custom options
docker-compose run --rm domain-check mystartup -t com,org,io --pretty

# Bulk check from file
docker-compose run --rm domain-check --file data/domains.txt --json
```

## Building the Image

```bash
# Build the Docker image
docker build -t domain-check:latest .

# Build with specific tag
docker build -t domain-check:0.6.0 .
```

## Usage Examples

### Basic Domain Check

```bash
# Single domain
docker run --rm domain-check:latest google.com

# Multiple TLDs
docker run --rm domain-check:latest mystartup -t com,io,ai,dev
```

### Using Environment Variables

```bash
# Set options via environment variables
docker run --rm \
  -e DC_CONCURRENCY=50 \
  -e DC_PRESET=startup \
  -e DC_PRETTY=true \
  domain-check:latest myapp

# With bootstrap enabled
docker run --rm \
  -e DC_BOOTSTRAP=true \
  -e DC_TIMEOUT=15s \
  domain-check:latest myproject --all
```

### Checking Domains from File

```bash
# Create a domains file
echo -e "myapp\nmystartup\ncoolproject" > domains.txt

# Mount and check
docker run --rm \
  -v $(pwd)/domains.txt:/workspace/domains.txt:ro \
  domain-check:latest --file domains.txt --json
```

### Using Custom Configuration

```bash
# Create config file
cat > .domain-check.toml << 'EOF'
[defaults]
concurrency = 30
preset = "startup"
pretty = true
timeout = "10s"
bootstrap = true
EOF

# Mount config file
docker run --rm \
  -v $(pwd)/.domain-check.toml:/workspace/.domain-check.toml:ro \
  domain-check:latest mystartup
```

### Output to File

```bash
# Save results to file
docker run --rm \
  -v $(pwd)/output:/workspace/output \
  domain-check:latest myapp --all --json > output/results.json

# Or with CSV
docker run --rm \
  -v $(pwd)/output:/workspace/output \
  domain-check:latest myapp -t com,org,net --csv > output/results.csv
```

## Docker Compose Configuration

The included `docker-compose.yml` provides pre-configured services:

### Services

- **domain-check**: Main service for interactive use
- **domain-check-bulk**: Pre-configured for bulk file processing (use with `--profile bulk`)

### Examples

```bash
# Standard check
docker-compose run --rm domain-check example.com

# With environment overrides
docker-compose run --rm \
  -e DC_PRESET=enterprise \
  -e DC_CONCURRENCY=50 \
  domain-check mybrand

# Bulk processing (requires domains.txt file)
docker-compose --profile bulk run --rm domain-check-bulk

# Custom command with mounted file
docker-compose run --rm \
  -v $(pwd)/my-domains.txt:/workspace/domains.txt:ro \
  domain-check --file domains.txt --streaming
```

## Image Details

- **Base Image**: `debian:bookworm-slim` (runtime)
- **Builder Image**: `rust:1.82-slim-bookworm`
- **Size**: ~100MB (compressed)
- **User**: Non-root user (`domaincheck`)
- **Workdir**: `/workspace`

## CI/CD Integration

### GitHub Actions Example

```yaml
name: Domain Check

on:
  schedule:
    - cron: '0 0 * * *'  # Daily at midnight

jobs:
  check-domains:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      
      - name: Build domain-check image
        run: docker build -t domain-check:latest .
      
      - name: Check critical domains
        run: |
          docker run --rm \
            -v $(pwd)/critical-domains.txt:/workspace/domains.txt:ro \
            domain-check:latest \
            --file domains.txt \
            --json \
            --preset enterprise > results.json
      
      - name: Upload results
        uses: actions/upload-artifact@v4
        with:
          name: domain-check-results
          path: results.json
```

### GitLab CI Example

```yaml
domain-check:
  image: docker:latest
  services:
    - docker:dind
  script:
    - docker build -t domain-check:latest .
    - docker run --rm domain-check:latest mycompany.com --preset enterprise --json
  only:
    - schedules
```

## Advanced Usage

### Multi-architecture Builds

```bash
# Create buildx builder
docker buildx create --name domain-check-builder --use

# Build for multiple platforms
docker buildx build \
  --platform linux/amd64,linux/arm64 \
  -t domain-check:latest \
  --push .
```

### Running as One-off Command

Add to your shell profile for easy access:

```bash
# .bashrc or .zshrc
domain-check-docker() {
  docker run --rm \
    -e DC_PRETTY=true \
    -e DC_PRESET=startup \
    domain-check:latest "$@"
}

# Usage
alias dcheck='domain-check-docker'
dcheck example.com
```

## Troubleshooting

### Container won't start

Check the logs:
```bash
docker logs domain-check
```

### Permission denied with mounted files

Ensure files are readable:
```bash
chmod 644 domains.txt
docker run --rm -v $(pwd)/domains.txt:/workspace/domains.txt:ro domain-check:latest --file domains.txt
```

### Network issues

If behind a corporate proxy:
```bash
docker run --rm \
  -e HTTP_PROXY=$HTTP_PROXY \
  -e HTTPS_PROXY=$HTTPS_PROXY \
  domain-check:latest example.com
```

## Security Notes

- The container runs as a non-root user (`domaincheck`)
- Configuration files are mounted read-only (`:ro`)
- Minimal base image reduces attack surface
- No unnecessary packages installed

## License

Same as the main project - Apache License 2.0
