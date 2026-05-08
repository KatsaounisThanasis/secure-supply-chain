# Secure Software Supply Chain Lab

This project demonstrates a production-oriented DevSecOps pipeline focused on securing the software supply chain from source code to container registry. It integrates automated vulnerability scanning, Software Bill of Materials (SBOM) generation, policy enforcement, and keyless image signing to build trust and integrity into software artifacts, protecting against modern supply chain attacks.

## Status

![GitHub Actions workflow status](https://img.shields.io/github/actions/workflow/status/KatsaounisThanasis/secure-supply-chain/security.yml?branch=main&label=Security%20Pipeline)
![License](https://img.shields.io/badge/License-MIT-blue.svg)

## Architecture Overview

A visual representation of the secure CI/CD pipeline, detailing each stage from code commit to artifact verification.

```mermaid
graph TD
    A[Code Commit] --> B(GitHub Actions Workflow)
    B --> C(Build Docker Image);
    C --> D(Trivy Scan - JSON Report);
    D --> E(Generate SBOM - CycloneDX);
    E --> F{Enforcement Gate: HIGH/CRITICAL Vulnerabilities?};
    F -- NO --> G(Push Image to GHCR);
    F -- YES --> H(Fail Build);
    G --> I(Cosign Keyless Sign);
    I --> J(Image Available for Deployment);
    J --> K(Verify Image Integrity);
```

## What This Demonstrates

This repository showcases practical application of several critical DevSecOps and supply chain security concepts:

*   **Automated Vulnerability Scanning:** Proactive identification of software vulnerabilities using Trivy.
*   **Software Bill of Materials (SBOM):** Generation and management of CycloneDX-formatted SBOMs for enhanced transparency and risk management.
*   **Policy-as-Code Enforcement:** Implementing gates in the CI/CD pipeline to prevent the deployment of insecure artifacts.
*   **Keyless Container Image Signing:** Leveraging Sigstore and Cosign with GitHub OIDC for secure, auditable, and ephemeral image attestations.
*   **Supply Chain Levels for Software Artifacts (SLSA):** Adherence to foundational SLSA principles to improve software supply chain integrity.
*   **Defense-in-Depth:** Layering security controls throughout the CI/CD process to create robust protections.
*   **Secure Containerization:** Building minimal, non-root Docker images for Go applications.

## Pipeline at a Glance

Each stage in the CI/CD pipeline serves a specific security purpose:

1.  **Build Docker Image (local):** The application is containerized into a Docker image, prepared for scanning and deployment.
    *   **Rationale:** Ensures consistent build environment and reproducible artifacts.
2.  **Trivy Scan (JSON Report):** The locally built image is scanned for vulnerabilities, and a detailed JSON report is generated.
    *   **Rationale:** Identifies security flaws early in the pipeline, preventing vulnerable images from reaching the registry. This scan does not fail the build but provides data for the enforcement gate.
3.  **Generate SBOM (CycloneDX):** A comprehensive Software Bill of Materials is created for the image.
    *   **Rationale:** Provides an immutable manifest of all components and dependencies, crucial for compliance, risk assessment, and rapid response to new CVEs.
4.  **Enforcement Gate (HIGH/CRITICAL Vulnerabilities):** The pipeline explicitly fails if Trivy detects HIGH or CRITICAL severity vulnerabilities.
    *   **Rationale:** Prevents the promotion of severely vulnerable images to the container registry, enforcing a 'shift-left' security posture.
5.  **Push Image to GHCR:** The scanned and approved image is pushed to GitHub Container Registry.
    *   **Rationale:** Utilizes a secure, versioned, and OCI-compliant registry for artifact storage. This only occurs *after* security checks pass.
6.  **Cosign Keyless Sign:** The pushed image is digitally signed using Cosign and Sigstore's keyless approach with GitHub OIDC.
    *   **Rationale:** Establishes cryptographic proof of the image's origin and integrity, allowing consumers to verify that the image has not been tampered with and originates from this specific CI/CD workflow.

## Verify It Yourself

To independently verify the security posture of an image pushed by this pipeline:

1.  **Install `cosign`:**
    ```bash
    go install github.com/sigstore/cosign/cmd/cosign@latest
    ```
    *(Ensure `$GOPATH/bin` is in your `$PATH`)*

2.  **Pull the image (example):**
    ```bash
    docker pull ghcr.io/katsaounisthanasis/secure-app:7f3f595...
    # Replace '7f3f595...' with an actual commit SHA from a successful workflow run.
    ```

3.  **Verify the Cosign signature:**
    ```bash
    COSIGN_EXPERIMENTAL=1 cosign verify 
      --certificate-oidc-issuer https://token.actions.githubusercontent.com 
      --certificate-identity-regexp 'https://github.com/KatsaounisThanasis/secure-supply-chain/.github/workflows/security.yml@refs/heads/main' 
      ghcr.io/katsaounisthanasis/secure-app:7f3f595...
    # Replace '7f3f595...' with the same commit SHA used above.
    ```
    A successful verification will output details about the signature.

4.  **Inspect the SBOM:**
    ```bash
    cosign download sbom ghcr.io/katsaounisthanasis/secure-app:7f3f595... | jq .
    # Replace '7f3f595...' with the same commit SHA.
    # Requires 'jq' for pretty-printing JSON.
    ```
    This will display the CycloneDX SBOM, detailing all software components within the image.

## Threat Model

| Threat                     | Mitigation                        | Where in the Pipeline       |
| :------------------------- | :-------------------------------- | :-------------------------- |
| **Dependency CVEs**        | Trivy Scan, Enforcement Gate      | Scan, Enforcement           |
| **Build-time Tampering**   | OIDC-based Image Signing          | Sign                        |
| **Registry Compromise**    | Immutable Images, SBOM Artifact   | Push, SBOM Generation       |
| **Identity Spoofing**      | Cosign Verification (OIDC Issuer) | Sign, Verify                |
| **Vulnerable Base Image**  | Trivy Scan, Dockerfile Pinning    | Build, Scan                 |

## Tech Stack

| Category                  | Tool / Language      | Purpose                                       |
| :------------------------ | :------------------- | :-------------------------------------------- |
| **Application Language**  | Go                   | Core web service implementation               |
| **Containerization**      | Docker               | Image packaging and isolation                 |
| **CI/CD Platform**        | GitHub Actions       | Workflow automation and orchestration         |
| **Vulnerability Scanning**| Trivy (Aqua Security)| Image scanning, SBOM generation, policy engine|
| **Container Registry**    | GitHub Container Registry (GHCR) | Secure OCI artifact hosting           |
| **Image Signing**         | Cosign (Sigstore)    | Keyless digital signatures for artifacts      |
| **SBOM Standard**         | CycloneDX            | Software Bill of Materials format             |

## Local Development

The `scripts/scan.sh` script provides a local equivalent of the CI pipeline's scanning and SBOM generation steps:

```bash
./scripts/scan.sh
```

This script will:
1.  Build the Docker image locally.
2.  Run a Trivy vulnerability scan (HIGH, CRITICAL severity).
3.  Generate a CycloneDX SBOM (`sbom-local.json`).

## License

This project is licensed under the MIT License - see the LICENSE file for details.
