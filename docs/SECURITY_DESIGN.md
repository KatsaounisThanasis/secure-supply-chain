# Security Design - Secure Software Supply Chain

## Overview
This project demonstrates a practical software supply chain security pipeline for containerized apps.  
The pipeline does not only "report" risks; it actively enforces security gates before artifacts are trusted.

## 1) SBOM (Software Bill of Materials)
An SBOM is an inventory of what is inside a software artifact (libraries, versions, dependencies).

Why we included it:
- Makes dependency risk visible and auditable.
- Helps incident response when a new CVE appears (you can quickly check exposure).
- Improves compliance and transparency for downstream consumers.

Implementation in this project:
- Trivy generates a CycloneDX SBOM (`sbom.json`) for the built image.
- The SBOM is uploaded as a GitHub Actions artifact for traceability.

## 2) Keyless Signing with Cosign
Keyless signing uses short-lived identity credentials (OIDC) instead of long-lived private keys.

Why this matters:
- Reduces key management risk (no static signing key to leak or rotate manually).
- Binds signature identity to the CI workflow execution.
- Supports provenance checks via Sigstore ecosystem (Fulcio/Rekor).

Implementation in this project:
- Workflow grants `id-token: write` for OIDC-based identity.
- Cosign is installed with `sigstore/cosign-installer`.
- The pushed GHCR image is signed with `cosign sign --yes`.

## 3) Security Enforcement (Not Just Visibility)
The pipeline enforces controls in CI/CD:

1. Build and push container image to GHCR.
2. Run Trivy scan and produce JSON report artifact for evidence.
3. Run Trivy enforcement step that fails on HIGH/CRITICAL vulnerabilities.
4. Generate and upload SBOM.
5. Sign the image using keyless Cosign.

Result:
- Vulnerable builds are blocked.
- Security artifacts (scan report + SBOM + signature) are preserved.
- The release process is both inspectable and policy-driven.
