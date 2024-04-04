# github-latest-release

Helper script to fetch the latest release package or executable from a Github repository.

It uses [get-the-latest-release](https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#get-the-latest-release) API 
to discover all the available downloads, a regex to select a specific one, and optionally `badtar` options to extract selected files
from an archive.


# Usage

    Usage:

      github-latest-releast -r <OWNER/REPO> -l -p [REGEX]
      github-latest-releast -r <OWNER/REPO> -f -p <REGEX> -o [OUTPUT]
      github-latest-releast -r <OWNER/REPO> -t -p <REGEX>
      github-latest-releast -r <OWNER/REPO> -x -p <REGEX> \
                            -i [INCLUDE_GLOB] -s [STRIP_COMPONENTS] -c [DIRECTORY]

    Options:

      -r <OWNER/REPO>
         The github repo identifier. The 'owner/repo' part of 'https://github.com/owner/repo'

      -l
         List all available download urls. Use the '-p' regex pattern to identify a single
         download url for use in the fetch commands.

         Example:
           github-latest-releast -r prometheus/prometheus -l -p 'linux-amd64.tar.gz$'

      -f
         Fetch a release package. Use this if the release is a single executable or to
         download an archive.

         Options:
           -o   passthrough to curl --output

         Example:
           github-latest-releast -r 'tsl0922/ttyd' -f -p 'ttyd.mips64$' -o '/tmp/ttyd'

      -t
         Fetch and list files in archive.

         Example:
           github-latest-releast -r prometheus/prometheus -t -p 'linux-amd64.tar.gz$'

      -x
         Fetch and extract from an archive.

         Options:
          -i   passthrough to bsdtar --include
          -s   passthrough to bsdtar --strip-components
          -c   passthrough to bsdtar --cd

         Example:
           github-latest-releast -r prometheus/prometheus -x -p 'linux-amd64.tar.gz$' \
                                 -i '*/prometheus' -s 1 -c /tmp



# Docker Container

A small container is provided for convenience of downloading release executables in a `Dockerfile`, e.g.

    FROM ghcr.io/jessthrysoee/github-latest-release/github-latest-release:latest as octopus
    RUN set -eux; \
        github-latest-release -r OctopusDeploy/cli -x -p 'linux_amd64\.tar\.gz$' -i octopus;

    FROM node:20-slim
    COPY --from=octopus --chown=root:root --chmod=755 /octopus /usr/bin/


For [multi-platform images](https://docs.docker.com/build/building/multi-platform/) it may be necessary to create a small
architecture mapping:

    FROM ghcr.io/jessthrysoee/github-latest-release/github-latest-release:latest as ttyd
    ARG TARGETARCH

    RUN set -eux; \
      case "$TARGETARCH" in      \
        arm64) ARCH="aarch64" ;; \
        amd64) ARCH="x86_64"  ;; \
        *) echo "$TARGETARCH not supported" >&2; exit 1 ;; \
      esac; \
      github-latest-release -r 'tsl0922/ttyd' -f -p "ttyd\\.$ARCH" -o '/ttyd'

    FROM alpine
    COPY --from=ttyd --chmod=700 /ttyd /

