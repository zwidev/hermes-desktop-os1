# Build stage
FROM swift:6.0-noble AS builder

WORKDIR /build
COPY . .

# Build the CLI tool
RUN swift build -c release --product os1-cli

# Run stage
FROM ubuntu:24.04

# Install runtime dependencies
RUN apt-get update && apt-get install -y \
    libcurl4 \
    libxml2 \
    openssh-client \
    python3 \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /app
COPY --from=builder /build/.build/release/os1-cli /usr/local/bin/os1

# Create config directory
RUN mkdir -p /root/.config/os1

ENTRYPOINT ["os1"]
CMD ["--help"]
