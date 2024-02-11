# github-latest-release

Helper script to fetch the latest release package or executable from a Github repository.

It uses [get-the-latest-release](https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#get-the-latest-release) API 
to discover all the available downloads, a regex to select a specific one, and optionally `badtar` options to extract selected files
from an archive.


# Docker Container

A small container is provided for convenience of downloading release executables in a `Dockerfile`, e.g.

    FROM ghcr.io/jessthrysoee/github-latest-release/github-latest-release:latest as ttyd
    RUN github-latest-release -r 'tsl0922/ttyd' -f -p 'ttyd.x86_64' -o '/ttyd'

    FROM alpine
    COPY --from=ttyd --chmod=700 /ttyd /


# Usage

      github-latest-release -r <OWNER/REPO> -l -p [REGEX_PATTERN]
      github-latest-release -r <OWNER/REPO> -f -p <REGEX_PATTERN> -o [OUTPUT]
      github-latest-release -r <OWNER/REPO> -t -p <REGEX_PATTERN>
      github-latest-release -r <OWNER/REPO> -x -p <REGEX_PATTERN> -i [INCLUDE_GLOB_PATTERN] -s [STRIP_COMPONENTS] -c [DIRECTORY]

    Options:

      -r <OWNER/REPO>
        The mandatory github repo identifier, e.g. the 'owner/repo' part of 'https://github.com/owner/repo'

      -l
        List all available download urls. Use the '-p' regex pattern to identify a single download url.

        Example: github-latest-release -r prometheus/prometheus -l -p 'linux-amd64.tar.gz$'

      -f
        Fetch a release package. Use this if the release is a single executable or to download an archive.
        Option '-o' is curl '-o'.

        Example: github-latest-release -r 'tsl0922/ttyd' -f -p 'ttyd.mips64$' -o '/tmp/ttyd'

      -t
        Fetch and list files in archive. 

        Example: github-latest-release -r prometheus/prometheus -t -p 'linux-amd64.tar.gz$'

      -x
        Fetch and extract from an archive. 
        Option '-i' is bsdtar '--include', '-s' is bsdtar '--strip-components', and '-c' is bsdar '-C'.

        Example: github-latest-release -r prometheus/prometheus -x -p 'linux-amd64.tar.gz$' -i '*/prometheus' -s 1 -c /tmp


