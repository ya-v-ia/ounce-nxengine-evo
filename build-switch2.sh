#!/bin/bash
# Build NXEngine-evo for Switch 2 with ounce-devkit (libounce / OunceVK).
#
#   ./build-switch2.sh
#
# Needs DEVKITPRO with libounce, the switch2 portlibs and the Switch 1
# portlibs (SDL2, SDL2_mixer, SDL2_image, libpng, libjpeg, ...), plus wget,
# unzip and curl on the host.
set -euo pipefail

cd "$(dirname "$0")"

: "${DEVKITPRO:?DEVKITPRO is not set - source \$DEVKITPRO/switch2vars.sh first}"
SWITCH2_TOOLCHAIN="${DEVKITPRO}/libounce/cmake/Switch2.cmake"
if [ ! -f "${SWITCH2_TOOLCHAIN}" ]; then
    echo "error: ${SWITCH2_TOOLCHAIN} not found - is ounce-devkit installed?" >&2
    exit 1
fi

JOBS=$(nproc 2>/dev/null || echo 4)

# --- 1. host-side data extractor --------------------------------------------
# The extractor is an ordinary PC program; build it with the host compiler.
rm -rf build-extract
cmake -S . -B build-extract -DPLATFORM=pc -DCMAKE_BUILD_TYPE=Release
cmake --build build-extract --target extract -j"${JOBS}"
EXTRACT="${PWD}/build-extract/nxextract"
if [ ! -x "${EXTRACT}" ]; then
    echo "error: ${EXTRACT} was not built" >&2
    exit 1
fi

# --- 2. fetch and extract the Cave Story data -------------------------------
rm -rf release
mkdir -p release/data
cd release

curl -fsSL -o translations.zip \
    https://github.com/nxengine/translations/releases/download/v1.8/all.zip
unzip -q -o translations.zip
rm -f translations.zip

curl -fsSL -o cavestoryen.zip \
    http://www.cavestory.org/downloads/cavestoryen.zip
unzip -q -o cavestoryen.zip
rm -f cavestoryen.zip

cd CaveStory
"${EXTRACT}"
cp -r data/* ../data/
cd ..
rm -rf CaveStory

cp -r ../data/* data/
cd ..

# --- 3. cross-compile the NRO ----------------------------------------------
# shellcheck disable=SC1091
source "${DEVKITPRO}/switch2vars.sh"

rm -rf build-switch2
cmake -S . -B build-switch2 \
    -DCMAKE_TOOLCHAIN_FILE="${SWITCH2_TOOLCHAIN}" \
    -DPLATFORM=switch2 \
    -DCMAKE_BUILD_TYPE=Release
cmake --build build-switch2 -j"${JOBS}"

# The game data lives inside the NRO's romfs, no need to ship it separately.
rm -rf release/data

echo
echo "Built:"
ls -l release/*.nro
