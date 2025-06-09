# github-latest-release

Helper script to fetch the latest release package or executable from a Github repository.

It uses [get-the-latest-release](https://docs.github.com/en/rest/releases/releases?apiVersion=2022-11-28#get-the-latest-release) API
to discover all the available downloads, a regex to select a specific one, and optionally `badtar` options to extract selected files
from an archive.

# Walk Through

Let's say we want to fetch the latest `ffmpeg` and `ffprobe` from [https://github.com/BtbN/FFmpeg-Builds](https://github.com/BtbN/FFmpeg-Builds).
Start by listing all (-l) the newest assets:

    $ github-latest-release -r BtbN/FFmpeg-Builds -l
    checksums.sha256
    ffmpeg-master-latest-linux64-gpl-shared.tar.xz
    ffmpeg-master-latest-linux64-gpl.tar.xz
    ...

Next, use a regex pattern (-p) to select a single asset:

    $ github-latest-release -r BtbN/FFmpeg-Builds -l -p 'latest-linux64-gpl-7'
    ffmpeg-n7.1-latest-linux64-gpl-7.1.tar.xz

With a single asset, list its contents (-t):

    $ github-latest-release -r BtbN/FFmpeg-Builds -t -p 'latest-linux64-gpl-7'
    ...
    ffmpeg-n7.1-latest-linux64-gpl-7.1/bin/ffplay
    ffmpeg-n7.1-latest-linux64-gpl-7.1/bin/ffmpeg
    ffmpeg-n7.1-latest-linux64-gpl-7.1/bin/ffprobe

Filter the list, by including (-i) only the matches of a glob-pattern:

    github-latest-release -r BtbN/FFmpeg-Builds -t -p 'latest-linux64-gpl-7' -i '*/bin/ff[mp][!l]*'

Finally extract (-x) and strip (-s) the two leading directories:

    $ github-latest-release -r BtbN/FFmpeg-Builds -x -p 'latest-linux64-gpl-7' -i '*/bin/ff[mp][!l]*' -s 2

    $ ls -1 ff*
    ffmpeg
    ffprobe

# Usage

    Usage:

      github-latest-release [-a <AUTH_TOKEN>] [-m {release|artifact}] -r <OWNER/REPO> -l [-p <REGEX>]

      github-latest-release [-a <AUTH_TOKEN>] [-m {release|artifact}] -r <OWNER/REPO> -f [-p <REGEX>] \
                            [-o <OUTPUT>]

      github-latest-release [-a <AUTH_TOKEN>] [-m {release|artifact}] -r <OWNER/REPO> -t [-p <REGEX>] \
                            [-i <INCLUDE_GLOB>]

      github-latest-release [-a <AUTH_TOKEN>] [-m {release|artifact}] -r <OWNER/REPO> -x [-p <REGEX>] \
                            [-i <INCLUDE_GLOB>] [-s <STRIP_COMPONENTS>] [-c <DIRECTORY>]

    Options:

      -a <AUTH_TOKEN>
         Authorization token. (equivalent to environment variale GITHUB_AUTH_TOKEN)

         Example:
           github-latest-release -a "$(gh auth token)" -r enterprise/repo -l

      -m {release|artifact}
         Change mode to list and fetch 'release' (default) or 'artifact'.

      -r <OWNER/REPO>
         The github repo identifier. The 'owner/repo' part of 'https://github.com/owner/repo'

      -l
         List all available download urls. Use the '-p' regex pattern to identify a single
         download url for use in the fetch commands.

         Example:
           github-latest-release -r prometheus/prometheus -l -p 'linux-amd64.tar.gz$'

      -f
         Fetch a release package. Use this if the release is a single executable or to
         download an archive.

         Options:
           -o   passthrough to curl --output

         Example:
           github-latest-release -r 'tsl0922/ttyd' -f -p 'ttyd.mips64$' -o '/tmp/ttyd'

      -t
         Fetch and list files in archive.

         Options:
          -i   passthrough to bsdtar --include

         Example:
           github-latest-release -r prometheus/prometheus -t -p 'linux-amd64.tar.gz$' \
                                 -i '*/prometheus'

      -x
         Fetch and extract from an archive.

         Options:
          -i   passthrough to bsdtar --include
          -s   passthrough to bsdtar --strip-components
          -c   passthrough to bsdtar --cd

         Example:
           github-latest-release -r prometheus/prometheus -x -p 'linux-amd64.tar.gz$' \
                                 -i '*/prometheus' -s 1 -c /tmp

    Authenticating as a GitHub App installation:

    If all the following environment variables are available and non-empty, a Github App installation
    access token is generated and used for authentication:

         GITHUB_APP_CLIENT_ID
         GITHUB_APP_INSTALLATION_ID
         GITHUB_APP_PRIVATE_KEY


# Docker Container

A small container is provided for convenience of downloading release executables in a `Dockerfile`, e.g.

    FROM ghcr.io/jessthrysoee/github-latest-release/github-latest-release:latest as octopus
    RUN set -eux; \
        github-latest-release -r OctopusDeploy/cli -x -p 'linux_amd64\.tar\.gz$' -i octopus;

    FROM node:20-slim
    COPY --from=octopus --chown=root:root --chmod=755 /octopus /usr/bin/

---

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

---

In Github Enterprise with internal repositories, the GITHUB_TOKEN does not authorize fetching assets across
repositories. However, it's possible but painful, to authenticate with a Github App installation like this:

    FROM ghcr.io/jessthrysoee/github-latest-release/github-latest-release:latest as latest
    RUN --mount=type=secret,id=GITHUB_APP_PRIVATE_KEY,env=GITHUB_APP_PRIVATE_KEY \
      set -eux; \
      export GITHUB_APP_CLIENT_ID="Ik2bliVgBIlj9ncKLL4X" GITHUB_APP_INSTALLATION_ID="12013411"; \
      github-latest-release -r enterprise/repo -f -p 'linux.tar.gz$'

# Github Action

It can be used as a Github action. For example, to install [Task](https://github.com/go-task/task):

    ...
    jobs:
      build:
        runs-on: ubuntu-latest

        steps:
          - name: Get latest Task runner
            uses: jessthrysoee/github-latest-release@1.0.4
              args: '-r go-task/task -x -p "linux_amd64.tar.gz" -i task'

          - run: ./task --help
