#!/bin/bash
{ # Force bash to read entire script
set -o nounset  # Exit on unset variables
set -o pipefail # Exit on unhandled failure in pipes
set -o errtrace # Have functions inherit ERR traps
# Print debug message and terminate script on non-zero return codes
trap 's=$?; echo >&2 "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

# Configuration
echo "ubuntu ALL=(ALL) NOPASSWD: ALL" | tee -a /etc/sudoers
patch -p0 < /opt/genome-studio/config/sesman.ini.patch
# patch -p0 < /opt/genome-studio/config/xrdp.ini.patch
patch -p0 < /opt/genome-studio/config/keyboard.patch

echo "WINEPREFIX=/opt/genome-studio/wineprefix" | tee -a /etc/environment
echo "WINEDEBUG=fixme-all" | tee -a /etc/environment

# Create and add user to group required for login
groupadd tsusers
usermod -a -G tsusers ubuntu

# Setup desktop shortcuts
mkdir -p /home/ubuntu/.config/autostart
# Setup script that prepares desktop icons on login
cp /opt/genome-studio/desktop/login-setup.desktop /home/ubuntu/.config/autostart/

chmod +x /home/ubuntu/.config/autostart/*.desktop
chown -R ubuntu:ubuntu /home/ubuntu/.config

mkdir -p /home/ubuntu/.cache/
ln -s /opt/genome-studio/installers /home/ubuntu/.cache/winetricks
chown -R ubuntu:ubuntu /home/ubuntu/.cache

ln -s /maps/projects /
ln -s /maps/datasets /

exit $?
}
