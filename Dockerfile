FROM alpine

RUN set -eux; \
  apk add --no-cache bash curl jq libarchive-tools openssl;

COPY github-latest-release /usr/local/bin/

ENTRYPOINT [ "/usr/local/bin/github-latest-release" ]

