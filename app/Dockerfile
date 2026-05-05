# Build Stage
# Pinned to a Go version that includes fixes for all stdlib CVEs flagged by Trivy
# (CVE-2025-68121, CVE-2026-32280/81/83, CVE-2026-25679, ...). Bump as needed.
FROM golang:1.26.2-alpine AS builder

WORKDIR /src
COPY go.mod ./
# No external deps in main.go (pure net/http) -> no go.sum needed.
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -trimpath -ldflags="-s -w" -o /out/main .

# Final Stage (Secure & Small)
FROM alpine:3.20

# Run as non-root for least privilege
RUN addgroup -S app && adduser -S -G app app
WORKDIR /app
COPY --from=builder /out/main /app/main
USER app

EXPOSE 8080
ENTRYPOINT ["/app/main"]
