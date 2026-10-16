# WebHackingTools — reproducible image built straight from installer.sh.
# Base image matches a supported OS: Debian 13 ("trixie").
#
#   docker build -t webhackingtools .
#   docker run --name webhackingtools -it webhackingtools
#
# Optional, to avoid the GitHub API rate limit during the build:
#   docker build --build-arg GITHUB_TOKEN=ghp_xxx -t webhackingtools .
FROM debian:13

LABEL org.opencontainers.image.title="WebHackingTools" \
      org.opencontainers.image.description="Curated web hacking / bug bounty toolset" \
      org.opencontainers.image.source="https://github.com/supr4s/WebHackingTools" \
      org.opencontainers.image.licenses="MIT"

# TERM lets the installer's `clear` work in a non-interactive build.
ENV DEBIAN_FRONTEND=noninteractive \
    TERM=xterm \
    PATH="/usr/local/go/bin:/root/go/bin:/usr/local/bin:/usr/bin:/bin"

# Minimal prerequisites; installer.sh installs the whole toolset itself.
RUN apt-get update \
    && apt-get install -y --no-install-recommends ca-certificates git curl \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /opt/WebHackingTools
COPY . .

# GITHUB_TOKEN is used only for this build step (not baked into the image).
ARG GITHUB_TOKEN=""
# The installer is resilient: individual tool failures are reported in the
# end-of-run summary and never abort the others, so `|| true` keeps a single
# optional tool from failing the whole image build. Check the summary/log.
RUN chmod +x installer.sh \
    && GITHUB_TOKEN="$GITHUB_TOKEN" ./installer.sh || true
RUN rm -rf /var/lib/apt/lists/* /tmp/* /root/.cache

WORKDIR /root
CMD ["/bin/bash"]
