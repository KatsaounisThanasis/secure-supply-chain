# Build Stage
FROM golang:1.21-alpine AS builder

WORKDIR /app
COPY go.mod ./
# Σημείωση: Στο πραγματικό Go θα χρειαζόμασταν go.sum, αλλά για το demo το αφήνουμε απλό
RUN go mod download

COPY . .
RUN CGO_ENABLED=0 GOOS=linux go build -o main .

# Final Stage (Secure & Small)
FROM alpine:3.18

WORKDIR /root/
COPY --from=builder /app/main .

EXPOSE 8080
CMD ["./main"]
