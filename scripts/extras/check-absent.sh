#!/usr/bin/env bash
# Refuses to publish over an existing OCI tag. A tag in a registry is mutable:
# pushing the chart, the bundle or the catalog again under the same version
# gives it a different digest, and the signatures and attestations made for
# the first push then point at a digest the tag no longer names. So a
# re-dispatch for a tag that was already published must stop, not re-push.
#
# Usage: check-absent.sh <version> <ghcr.io/owner/name>...
# Reads: GITHUB_TOKEN (pull access to the packages, e.g. the workflow's token).
# Exit: 0 if none of the <name>:<version> tags exists, 1 if any does (or if
# the registry's answer is not a plain exists / does not exist).
set -euo pipefail

if [[ $# -lt 2 ]]; then
    echo "usage: $0 <version> <ghcr.io/owner/name>..." >&2
    exit 2
fi
: "${GITHUB_TOKEN:?GITHUB_TOKEN is required}"

version="$1"
shift
accept="application/vnd.oci.image.manifest.v1+json, application/vnd.oci.image.index.v1+json, application/vnd.docker.distribution.manifest.v2+json, application/vnd.docker.distribution.manifest.list.v2+json"

status=0
for ref in "$@"; do
    if [[ $ref != ghcr.io/* ]]; then
        echo "::error::only ghcr.io references are supported: '$ref'" >&2
        exit 2
    fi
    path="${ref#ghcr.io/}"
    bearer=$(curl -sSf -u "token:${GITHUB_TOKEN}" "https://ghcr.io/token?scope=repository:${path}:pull&service=ghcr.io" |
        python3 -I -c 'import json, sys; print(json.load(sys.stdin)["token"])')
    code=$(curl -sS -o /dev/null -w '%{http_code}' -I -H "Authorization: Bearer ${bearer}" -H "Accept: ${accept}" \
        "https://ghcr.io/v2/${path}/manifests/${version}")
    case "$code" in
        200)
            echo "::error::${ref}:${version} already exists; refusing to re-push a published tag (cut a new release instead)" >&2
            status=1
            ;;
        404) ;;
        *)
            echo "::error::cannot tell whether ${ref}:${version} exists (HTTP ${code})" >&2
            status=1
            ;;
    esac
done
exit "$status"
