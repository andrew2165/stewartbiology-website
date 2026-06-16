FROM ghcr.io/gohugoio/hugo:v0.163.1 AS builder

WORKDIR /src
COPY . .

# TODO: Test this build on the VPS with Podman before using it for production deployment.
RUN hugo --gc --minify --destination /tmp/site

FROM docker.io/nginxinc/nginx-unprivileged:stable-alpine

COPY deploy/nginx/default.conf /etc/nginx/conf.d/default.conf
COPY --from=builder /tmp/site/ /usr/share/nginx/html/

EXPOSE 8080

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -q -O /dev/null http://127.0.0.1:8080/ || exit 1
