FROM --platform=$BUILDPLATFORM golang:1.27.1-alpine AS builder

WORKDIR /build

COPY go.mod go.sum ./
RUN go mod download

COPY ..

RUN CGO_ENABLED=0 GOOS=linux \
    go build \
    -ldflags="-s -w -X github.com/GoPowerDNS-Admin/GoPowerDNS-Admin/internal/version.version=${VERSION}" \
    -o go-pdns .

FROM alpine:latest

LABEL org.opencontainers.image.title="67-Host-Admin"
LABEL org.opencontainers.image.description="Homelab DNS 67"
LABEL org.opencontainers.image.source="https://github.com/root-67/dns-server"
LABEL org.opencontainers.image.url="https://github.com/root-67/dns-server" \
LABEL org.opencontainers.image.licenses="MIT"

RUN apk add --no-cache ca-certificates tzdata \
    && addgroup -S gopdns && adduser -S -G gopdns gopdns

WORKDIR /app

COPY --from=builder /build/go-pdns /app/go-pdns

RUN mkdir -p /etc/go-pdns /var/lib/go-pdns \
    && chown gopdns:gopdns /etc/go-pdns /var/lib/go-pdns

VOLUME ["/etc/go-pdns", "/var/lib/go-pdns"]

USER gopdns

EXPOSE 8080 

ENTRYPOINT ["/app/go-pdns"]
CMD ["start", "-c", "/etc/go-pdns"]


