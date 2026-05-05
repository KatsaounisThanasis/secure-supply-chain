#!/bin/bash

# Έλεγχος αν το Trivy είναι εγκατεστημένο
if ! command -v trivy &> /dev/null
then
    echo "Trivy could not be found. Please install it first: https://aquasecurity.github.io/trivy/latest/getting-started/installation/"
    exit
fi

IMAGE_NAME="secure-app:local"

echo "🔨 Building Docker image..."
docker build -t $IMAGE_NAME ./app

echo "🔍 Running Vulnerability Scan..."
trivy image --severity HIGH,CRITICAL $IMAGE_NAME

echo "📋 Generating SBOM (CycloneDX)..."
trivy image --format cyclonedx --output sbom-local.json $IMAGE_NAME

echo "✅ Done! Local SBOM generated as sbom-local.json"
