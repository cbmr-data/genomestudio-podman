# syntax=docker/dockerfile:1
FROM ubuntu:jammy-20260810

ENV DEBIAN_FRONTEND=noninteractive

# Disable auto installation of recommended packages, too many unwanted packages gets installed without this
RUN apt-config dump | grep -we Recommends -e Suggests | sed 's/1/0/' | tee /etc/apt/apt.conf.d/999norecommend
# Prevent cleanup of cached apt packages
RUN rm -f /etc/apt/apt.conf.d/docker-clean; echo 'Binary::apt::APT::Keep-Downloaded-Packages "true";' > /etc/apt/apt.conf.d/keep-cache

# Required for wine
RUN dpkg --add-architecture i386

# Requirement
# - ca-certificates, cabextract, make, pgp are required for winetricks
# - dbus-x11, xfce4, xserver-xorg required for a minimal X11 desktop
# - fonts-* are required for Genome Studio to render correctly
# - nano, suid, xterm are for convenience
# - patch is required for scripts/container-setup.sh
# - uuid is required for scripts/entrypoint.sh
# - wget is required for winetricks and scripts/download-installers.sh
# - software-properties-common is required or `add-apt-repository`
RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get -y update \
    && apt-get -y upgrade \
    && apt-get autoremove -y --purge \
    && apt-get install -y \
        ca-certificates \
        cabextract \
        dbus-x11 \
        fonts-noto-core \
        fonts-noto-hinted \
        fonts-noto-mono \
        fonts-noto-ui-core \
        make \
        nano \
        patch \
        pgp \
        software-properties-common \
        sudo \
        uuid \
        wget \
        xfce4 \
        xfce4-terminal \
        xserver-xorg

# Add wine repository
RUN mkdir -pm755 /etc/apt/keyrings && wget -O - https://dl.winehq.org/wine-builds/winehq.key | gpg --dearmor -o /etc/apt/keyrings/winehq-archive.key -
RUN wget -NP /etc/apt/sources.list.d/ https://dl.winehq.org/wine-builds/ubuntu/dists/jammy/winehq-jammy.sources

# Add xrdp-egfx repo
RUN add-apt-repository ppa:saxl/xrdp-egfx

RUN --mount=type=cache,target=/var/cache/apt,sharing=locked \
    --mount=type=cache,target=/var/lib/apt,sharing=locked \
    apt-get update \
    && apt-get install -y \
        winehq-devel=11.17~jammy-1 \
        xrdp-egfx \
        xorgxrdp-egfx

# Install wine-tricks
RUN DIR=$(mktemp -d) \
    && cd "${DIR}" \
    && wget "https://github.com/Winetricks/winetricks/archive/refs/tags/20260125.tar.gz" \
    && tar xvzf "${DIR}/20260125.tar.gz" \
    && make -C "winetricks-20260125/" install \
    && rm -rv "${DIR}"

COPY --chmod=555 scripts/*.sh /opt/genome-studio/bin/
COPY --chmod=444 desktop/*.desktop /opt/genome-studio/desktop/
COPY --chmod=444 config/*.patch /opt/genome-studio/config/

RUN /opt/genome-studio/bin/container-setup.sh

# Docker config
EXPOSE 3389
ENTRYPOINT ["/opt/genome-studio/bin/entrypoint.sh"]
