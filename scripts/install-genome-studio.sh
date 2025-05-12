#!/bin/bash
{ # Force bash to read entire script
set -o nounset  # Exit on unset variables
set -o pipefail # Exit on unhandled failure in pipes
set -o errtrace # Have functions inherit ERR traps
# Print debug message and terminate script on non-zero return codes
trap 's=$?; echo >&2 "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

function download() {
    filename=${1/*\//}
    if [ ! -e "${filename}" ]; then
        echo "## ${filename}: Downloading from '$1'"
        wget -N "$1"
    else
        echo "## ${filename}: Already downloaded"
    fi

    echo "$2  $filename" | sha256sum -c
}

export WINEPREFIX=/opt/genome-studio/wineprefix

cd /opt/genome-studio/installers/ || exit

if [ ! -e "GenomeStudioInstaller.exe" ]; then
    echo "Genome Studio installer (GenomeStudioInstaller.exe) not found."
    echo "Please download 'GenomeStudioInstaller.exe' from 'https://emea.support.illumina.com/downloads/genomestudio-2-0.html',"
    echo "and place the installer in the "installers" mount before running "
    echo "the installation script again."
    echo
    echo "Press enter to close this window..."
    read -r
    exit 1
fi

echo "## Downloading wine-gecko installers"
download "https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86.msi" 26cecc47706b091908f7f814bddb074c61beb8063318e9efc5a7f789857793d6
download "https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86_64.msi" e590b7d988a32d6aa4cf1d8aa3aa3d33766fdd4cf4c89c2dcc2095ecb28d066f

echo "## Creating wine prefix"
# Prevent 'install wine-mono?' dialog from opening before we install dotnet
env WINEDLLOVERRIDES=mscoree=d winecfg /v win7

echo "## Installing wine-gecko"
# The gecko browser engine is required for embedded HTML in Genome Studio
# https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86.msi
wine msiexec -i wine-gecko-2.47.4-x86.msi
# https://dl.winehq.org/wine/wine-gecko/2.47.4/wine-gecko-2.47.4-x86_64.msi
wine msiexec -i wine-gecko-2.47.4-x86_64.msi

# Genome Studio requirements
echo "## Installing dotnet35"
winetricks --unattended dotnet35
echo "## Installing dotnet472"
winetricks --unattended dotnet472

echo "## Disabling theming for apps run in wine"
winetricks windowmanagerdecorated=n

# Install GS
echo "## Installing GenomeStudio"
wine GenomeStudioInstaller.exe

# Setup desktop shortcuts
bash /opt/genome-studio/bin/login-setup.sh

exit $?
}
