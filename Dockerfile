FROM ghcr.io/browserless/chromium:latest

# Authentication token - override this in production
ENV TOKEN=${BROWSER_TOKEN:-cloud-eyes-default-token}

# Concurrency settings
ENV CONCURRENT=5
ENV QUEUED=10

# Session timeout in milliseconds (60 seconds)
ENV TIMEOUT=60000

EXPOSE 3000

# Health check against the config endpoint
HEALTHCHECK --interval=30s --timeout=10s --retries=3 \
  CMD curl -f http://localhost:3000/config?token=${TOKEN} || exit 1
