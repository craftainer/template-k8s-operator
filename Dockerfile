# syntax=docker/dockerfile:1.28
# Skeleton runtime image (builder -> runner), the repo's only top-level
# Dockerfile; an instance replaces the app parts and keeps the shape. The
# devcontainer image is the base-owned .devcontainer/Dockerfile's `develop`
# stage. As shipped it serves GET /health/live on port 8000 (busybox httpd)
# so `make release-check` has a real image to smoke-test; template-docker
# releases itself through that contract.

# Also declared in .devcontainer/Dockerfile; scripts/check-dockerfile-versions.sh
# keeps the two equal.
ARG DEBIAN_VERSION=trixie
# Both stages pin the base image by digest as well as tag (the digest is of
# the multi-arch index); Renovate's dockerfile manager bumps tag and digest.

ARG APP_UID=1000

ARG SSL_CERT_FILE=/etc/ssl/certs/ca-certificates.crt
ARG SSL_CERT_DIR=/etc/ssl/certs

########################################
# builder -- produces what the runner needs (here: a static busybox)
########################################
FROM debian:${DEBIAN_VERSION}-slim@sha256:62bd423aeee912639ca8ee681c2b762cb3e25137e0a92b20be455898a9f034ad AS builder
ARG SSL_CERT_FILE
ARG SSL_CERT_DIR

ENV SSL_CERT_FILE=${SSL_CERT_FILE} \
    SSL_CERT_DIR=${SSL_CERT_DIR} \
    DEBIAN_FRONTEND=noninteractive

# Debian mirrors drop superseded package versions, so pinning one breaks
# rebuilds; the base image is pinned by digest instead.
# hadolint ignore=DL3008
RUN apt-get update \
    && apt-get install -y --no-install-recommends busybox-static \
    && rm -rf /var/lib/apt/lists/*

WORKDIR /build
RUN mkdir -p www/health \
    && printf 'ok\n' > www/health/live
# Read-only modes as numeric values, applied here per kind: the runner COPY
# keeps them. The symbolic `COPY --chmod=u=rX,g=rX,o=` form left files
# unreadable on GitHub's stock-runner Docker (template-fastapi's smoke) even
# with the dockerfile:1.28 frontend; numeric modes work everywhere.
# Files that are executable stay so (0550), the rest are 0440.
RUN find . -type d -exec chmod 0550 {} + \
    && find . -type f ! -perm /111 -exec chmod 0440 {} + \
    && find . -type f -perm /111 -exec chmod 0550 {} +

########################################
# runner -- minimal runtime image. Runs under an arbitrary UID (e.g.
# OpenShift's restricted SCC) as well as a fixed one: see runner-setup.sh.
########################################
FROM debian:${DEBIAN_VERSION}-slim@sha256:62bd423aeee912639ca8ee681c2b762cb3e25137e0a92b20be455898a9f034ad AS runner
ARG APP_UID
ARG SSL_CERT_FILE
ARG SSL_CERT_DIR
# Set by `make build` through BUILD_ARGS in image.mk when an instance wants
# them; empty otherwise.
ARG APP_VERSION=
ARG APP_COMMIT=

ENV APP_VERSION=${APP_VERSION} \
    APP_COMMIT=${APP_COMMIT} \
    HOME=/home/appuser \
    SSL_CERT_FILE=${SSL_CERT_FILE} \
    SSL_CERT_DIR=${SSL_CERT_DIR}

COPY --from=builder /bin/busybox /usr/local/bin/busybox

# Create the user and the few writable directories first (home, /app/data),
# then copy app code read-only on top (0550 dirs / 0440 files, set in the
# builder; see there): no recursive chgrp/chmod layer, and the runtime user
# can't modify what it runs.
COPY scripts/runner-setup.sh /tmp/runner-setup.sh
COPY scripts/runner-setup.d/ /tmp/runner-setup.d/
RUN bash /tmp/runner-setup.sh "$APP_UID" && rm -rf /tmp/runner-setup.sh /tmp/runner-setup.d

WORKDIR /app
COPY --from=builder --chown=${APP_UID}:0 /build/ /app/

USER $APP_UID
EXPOSE 8000
ENTRYPOINT ["busybox", "httpd", "-f", "-p", "8000", "-h", "/app/www"]
