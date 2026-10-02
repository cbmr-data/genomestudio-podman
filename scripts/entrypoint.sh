#!/bin/bash
set -o nounset  # Exit on unset variables
set -o pipefail # Exit on unhandled failure in pipes
set -o errtrace # Have functions inherit ERR traps
# Print debug message and terminate script on non-zero return codes
trap 's=$?; echo >&2 "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

stop_xrdp_services() {
    sudo xrdp --kill
    sudo xrdp-sesman --kill
    exit 0
}

trap "stop_xrdp_services" SIGTERM SIGHUP SIGINT EXIT

password=$(uuid)
echo
echo "$(tput setaf 3) Password is '${password}' $(tput sgr0)"
if [ -n "${EXTHOST:-}" ] && [ -n "${EXTPORT:-}" ]; then
    echo "$(tput setaf 3) To connect using xfreerdp3$(tput sgr0)"
    echo "$(tput setaf 3)     xfreerdp3 /size:1920x1080 /v:${EXTHOST}:${EXTPORT} /u:ubuntu /p:${password}$(tput sgr0)"
fi
echo

echo "ubuntu:${password}" | sudo chpasswd

sudo chown ubuntu:ubuntu /opt/genome-studio/wineprefix
sudo mkdir -p /var/run/xrdp/
sudo xrdp-sesman && exec sudo xrdp -n
