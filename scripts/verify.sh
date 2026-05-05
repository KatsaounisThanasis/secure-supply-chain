#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <image-ref> [certificate-identity-regexp]"
  echo "Example: $0 ghcr.io/<owner>/secure-app:<tag> 'https://github.com/<owner>/<repo>/.github/workflows/.*'"
  exit 1
fi

IMAGE_REF="$1"
IDENTITY_REGEX="${2:-https://github.com/.+/.+/.github/workflows/.+}"

echo "Verifying signature for image: ${IMAGE_REF}"
cosign verify \
  --certificate-oidc-issuer "https://token.actions.githubusercontent.com" \
  --certificate-identity-regexp "${IDENTITY_REGEX}" \
  "${IMAGE_REF}"

echo "Signature verification succeeded."
