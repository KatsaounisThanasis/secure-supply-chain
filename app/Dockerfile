# Build Stage
# Pinned to a Go version that includes fixes for all stdlib CVEs flagged by Trivy
# (latest batch: CVE-2026-33818 encoding/asn1, CVE-2026-39821/22, fixed in 1.26.6).
# When the CI gate goes red on stdlib CVEs, bumping this is the fix - the gate
# blocking a vulnerable toolchain is the pipeline working as designed.
FROM golang:1.26.6-alpine AS builder

WORKDIR /src
COPY go.mod ./
# No external deps in main.go (pure net/http) -> no go.sum needed.
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/main .

# Final Stage (Secure & Small)
FROM alpine:3.22

# Run as non-root for least privilege
RUN addgroup -S app && adduser -S -G app app
WORKDIR /app
COPY --from=builder /out/main /app/main
USER app

EXPOSE 8080
ENTRYPOINT ["/app/main"]
