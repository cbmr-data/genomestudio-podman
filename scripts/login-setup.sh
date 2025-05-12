#!/bin/bash
{ # Force bash to read entire script
set -o nounset  # Exit on unset variables
set -o pipefail # Exit on unhandled failure in pipes
set -o errtrace # Have functions inherit ERR traps
# Print debug message and terminate script on non-zero return codes
trap 's=$?; echo >&2 "$0: Error on line "$LINENO": $BASH_COMMAND"; exit $s' ERR

EXECUTABLE="/opt/genome-studio/wineprefix/drive_c/Program Files/Illumina/GenomeStudio 2.0/GenomeStudio.exe"
if [ -e "${EXECUTABLE}" ]; then
    readonly USED=genome-studio
    readonly UNUSED=install-genome-studio
else
    readonly USED=install-genome-studio
    readonly UNUSED=genome-studio
fi

mkdir -p "${HOME}/Desktop/"

rm -f "${HOME}/Desktop/${UNUSED}.desktop"
cp "/opt/genome-studio/desktop/${USED}.desktop" "${HOME}/Desktop/"
chmod 700 "${HOME}/Desktop/${USED}.desktop"

# Remove half-broken shortcuts created by wine / GenomeStudio
rm -f "${HOME}/Desktop/GenomeStudio 2.0.desktop"
rm -f "${HOME}/Desktop/GenomeStudio 2.0.lnk"

}
