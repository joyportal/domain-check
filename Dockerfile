# Multi-stage Dockerfile for domain-check
# Stage 1: Build the application
FROM rust:1.82-slim-bookworm AS builder

WORKDIR /usr/src/domain-check

# Install build dependencies
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    pkg-config \
    libssl-dev \
    ca-certificates \
    && rm -rf /var/lib/apt/lists/*

# Copy workspace configuration
COPY Cargo.toml ./

# Copy workspace members
COPY domain-check-lib/ ./domain-check-lib/
COPY domain-check/ ./domain-check/

# Build the release binary
RUN cargo build --release -p domain-check

# Stage 2: Create minimal runtime image
FROM debian:bookworm-slim AS runtime

# Install runtime dependencies
# hadolint ignore=DL3008
RUN apt-get update && apt-get install -y --no-install-recommends \
    ca-certificates \
    libssl3 \
    && rm -rf /var/lib/apt/lists/*

# Copy the binary from builder
COPY --from=builder /usr/src/domain-check/target/release/domain-check /usr/local/bin/domain-check

# Create non-root user for security
RUN useradd -m -u 1000 domaincheck && \
    mkdir -p /workspace && \
    chown -R domaincheck:domaincheck /workspace

USER domaincheck
WORKDIR /workspace

# Set the entrypoint
ENTRYPOINT ["domain-check"]

# Default command shows help
CMD ["--help"]
