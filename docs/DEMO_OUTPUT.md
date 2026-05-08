# Live Demo Output — Captured Run

This document captures the **actual terminal output** produced when running
the end-to-end pipeline + runtime enforcement on commit
`55fe507faf1e1066071d4e4e2b132fb4e3f36e96`. Nothing here is fabricated;
every block is a verbatim copy from the recorded session.

## 1. Image was signed by our GitHub Actions workflow

```bash
$ cosign verify \
    --certificate-oidc-issuer https://token.actions.githubusercontent.com \
    --certificate-identity-regexp '^https://github.com/KatsaounisThanasis/secure-supply-chain/\.github/workflows/security\.yml@refs/heads/main$' \
    ghcr.io/katsaounisthanasis/secure-app:55fe507faf1e1066071d4e4e2b132fb4e3f36e96

Verification for ghcr.io/katsaounisthanasis/secure-app:55fe507faf1e1066071d4e4e2b132fb4e3f36e96 --
The following checks were performed on each of these signatures:
  - The cosign claims were validated
  - Existence of the claims in the transparency log was verified offline
  - The code-signing certificate was verified using trusted certificate authority certificates
```

The certificate identity matched exactly:

```text
Issuer:   https://token.actions.githubusercontent.com
Subject:  https://github.com/KatsaounisThanasis/secure-supply-chain/.github/workflows/security.yml@refs/heads/main
GitHub workflow:        Security Pipeline
GitHub workflow ref:    refs/heads/main
GitHub workflow trigger: push
GitHub workflow SHA:    55fe507faf1e1066071d4e4e2b132fb4e3f36e96
Image digest:           sha256:8a786e2e58064f24038e7ab346ffd6a92405f1a0302fbb6d93e63b94e293778a
Rekor transparency log entry index: 1473402910
```

## 2. Kyverno ClusterPolicy verifies that exact identity

```bash
$ kubectl get clusterpolicy
NAME                       ADMISSION   BACKGROUND   READY   AGE   MESSAGE
verify-secure-app-images   true        false        True    13m   Ready
```

Policy excerpt (the keyless attestor pinned to our workflow):

```yaml
- keyless:
    issuer: https://token.actions.githubusercontent.com
    subject: https://github.com/KatsaounisThanasis/secure-supply-chain/.github/workflows/security.yml@refs/heads/main
    rekor:
      url: https://rekor.sigstore.dev
```

## 3. Signed pod → ADMITTED

```bash
$ make demo-pass IMAGE_TAG=55fe507faf1e1066071d4e4e2b132fb4e3f36e96
pod/secure-app-signed created

$ kubectl -n demo-secure get pod
NAME                READY   STATUS    RESTARTS   AGE
secure-app-signed   1/1     Running   0          6s
```

### Cryptographic proof: Kyverno mutated the tag to a digest

```bash
$ kubectl -n demo-secure get pod secure-app-signed -o jsonpath='{.spec.containers[0].image}'
ghcr.io/katsaounisthanasis/secure-app:55fe507faf1e1066071d4e4e2b132fb4e3f36e96@sha256:8a786e2e58064f24038e7ab346ffd6a92405f1a0302fbb6d93e63b94e293778a
                                                                              ^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^^
                                                                              Kyverno appended the digest after verifying the signature.
                                                                              From this moment on, the pod is pinned to immutable bytes.
```

### Verification annotation written by Kyverno

```bash
$ kubectl -n demo-secure get pod secure-app-signed \
    -o jsonpath='{.metadata.annotations.kyverno\.io/verify-images}'
{
  "ghcr.io/katsaounisthanasis/secure-app@sha256:8a786e2e58064f24038e7ab346ffd6a92405f1a0302fbb6d93e63b94e293778a": "pass"
}
```

### App is healthy inside the pod

```bash
$ kubectl -n demo-secure exec secure-app-signed -- wget -qO- http://localhost:8080/health
OK

$ kubectl -n demo-secure logs secure-app-signed
2026/05/08 12:46:37 Server starting on :8080
```

## 4. Unsigned pod → REJECTED at admission

```bash
$ make demo-fail
Error from server: error when creating "k8s/demos/fail-unsigned.yaml":
admission webhook "validate.kyverno.svc-fail" denied the request:

resource Pod/demo-secure/nginx-unsigned was blocked due to the following policies

verify-secure-app-images:
  restrict-demo-namespace-images: 'validation failure: validation error:
    Only secure-app images are allowed in demo-secure.
    rule restrict-demo-namespace-images failed at path /image/'

OK: rejected as expected
```

## 5. Live evidence on GitHub

| Artifact | Live URL |
|----------|----------|
| Successful pipeline run (commit 55fe507) | <https://github.com/KatsaounisThanasis/secure-supply-chain/actions/runs/25556241170> |
| Trivy SARIF findings in Code Scanning | <https://github.com/KatsaounisThanasis/secure-supply-chain/security/code-scanning> |
| Signed image on GHCR (public) | <https://github.com/KatsaounisThanasis/secure-supply-chain/pkgs/container/secure-app> |
| Rekor transparency log (search by `logIndex 1473402910`) | <https://search.sigstore.dev/?logIndex=1473402910> |

Anyone can independently re-verify these claims using
[`scripts/verify-image.sh`](../scripts/verify-image.sh) without trusting this
repository's owner.
