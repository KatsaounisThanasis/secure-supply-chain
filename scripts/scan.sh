#!/usr/bin/env bash
set -euo pipefail

# Local equivalent of the CI security scan: build the image, scan with Trivy,
# generate a CycloneDX SBOM. Useful for pre-push verification.

if ! command -v trivy &> /dev/null; then
  echo "ERROR: Trivy not found. Install it from:" >&2
  echo "  https://aquasecurity.github.io/trivy/latest/getting-started/installation/" >&2
  exit 1
fi

if ! command -v docker &> /dev/null; then
  echo "ERROR: Docker not found." >&2
  exit 1
fi

IMAGE_NAME="${IMAGE_NAME:-secure-app:local}"
SBOM_FILE="${SBOM_FILE:-sbom-local.json}"

echo "==> Building Docker image: ${IMAGE_NAME}"
docker build -t "${IMAGE_NAME}" ./app

echo "==> Running vulnerability scan (HIGH,CRITICAL, ignore-unfixed)"
trivy image \
  --severity HIGH,CRITICAL \
  --ignore-unfixed \
  --exit-code 1 \
  "${IMAGE_NAME}"

echo "==> Generating CycloneDX SBOM -> ${SBOM_FILE}"
trivy image \
  --format cyclonedx \
  --output "${SBOM_FILE}" \
  "${IMAGE_NAME}"

echo "==> Done. SBOM at ${SBOM_FILE}"
