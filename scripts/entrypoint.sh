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
echo "$(tput setaf 3) Password is '${password}' $(tput sgr0)"
echo "ubuntu:${password}" | sudo chpasswd

sudo xrdp-sesman && exec sudo xrdp -n
