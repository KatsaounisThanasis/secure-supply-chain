#!/usr/bin/env bash
set -euo pipefail

if [[ $# -lt 1 ]]; then
  echo "Usage: $0 <image-ref> [certificate-identity-regexp]"
  echo "Example: $0 ghcr.io/<owner>/secure-app:<tag> '^https://github.com/<owner>/<repo>/\\.github/workflows/security\\.yml@refs/heads/main$'"
  exit 1
fi

IMAGE_REF="$1"
IDENTITY_REGEX="${2:-^https://github.com/KatsaounisThanasis/secure-supply-chain/\\.github/workflows/security\\.yml@refs/heads/main$}"
OIDC_ISSUER="https://token.actions.githubusercontent.com"

echo "Verifying Cosign signature for image: ${IMAGE_REF}"
cosign verify \
  --certificate-oidc-issuer "${OIDC_ISSUER}" \
  --certificate-identity-regexp "${IDENTITY_REGEX}" \
  "${IMAGE_REF}"

echo "Verifying CycloneDX attestation for image: ${IMAGE_REF}"
cosign verify-attestation \
  --type cyclonedx \
  --certificate-oidc-issuer "${OIDC_ISSUER}" \
  --certificate-identity-regexp "${IDENTITY_REGEX}" \
  "${IMAGE_REF}"

echo "Signature and CycloneDX attestation verification succeeded."
