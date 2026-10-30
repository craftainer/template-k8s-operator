# Per-instance settings for the image release contract in ../Makefile
# (`-include image.mk`). Everything here is optional: uncomment and edit what
# the instance needs. This file is instance-owned (`ignore` tier); the
# Makefile itself is template-owned and overwritten by a sync.

# Build file and stage the release image is built from.
# DOCKERFILE := Dockerfile
# TARGET := runner

# Arches to build, as a space-separated list; release-arches prints it as a
# JSON array and finalize merges one tag per arch.
# ARCHES := amd64 arm64

# Extra words for `docker buildx build`, passed through as-is.
# BUILD_ARGS := --build-arg APP_VERSION=$(RELEASE_VERSION) --build-arg APP_COMMIT=$(shell git rev-parse HEAD)
# EXTRA_LABELS := --label com.example.team=platform

# Image name override (default: the repository name, lowercased) comes from
# the OCI_IMAGE_NAME env var, not from here.

# org.opencontainers.image.description (omitted while empty), and the SPDX
# licence id for org.opencontainers.image.licenses.
# OCI_DESCRIPTION := One sentence about the image
# OCI_LICENSE := GPL-3.0-only

# Release asset name (under the release's download URL) to point the
# io.github.<owner>.coverage-report label at; label omitted while empty.
# COVERAGE_REPORT := coverage.xml

# image-smoke loads dist/'s image tar, runs it and polls this URL until 2xx.
# `make release-assets` runs it for RELEASE_ARCH (each arch on its own native
# runner, before publish); `make release-check` runs it for the host arch.
# IMAGE_SMOKE_PORT := 8000
# IMAGE_SMOKE_PATH := /health/live
# Extra `docker run` words: whitespace-separated, no embedded spaces or
# quotes (it reaches the script through the environment).
# IMAGE_SMOKE_RUN_ARGS := -e DATABASE_URL=sqlite:///tmp/x
# IMAGE_SMOKE_TIMEOUT := 60

# Extra release-check steps: add prerequisites here, never a recipe on
# release-check itself (the Makefile owns that target).
# release-check: instance-tests
# instance-tests:
# 	uv run pytest --cov-report=xml:dist/coverage.xml
