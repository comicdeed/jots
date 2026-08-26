#!/bin/bash
set -euo pipefail

# Architecture detection
ARCH="${ARCH:-$(uname -m)}"
STAGE_DIR="${STAGE_DIR:-stage}"
BUILD_DIR="${BUILD_DIR:-builddir-appimage}"
OUTPUT_DIR="${OUTPUT_DIR:-dist}"

echo "==> Building Jots AppImage for ${ARCH}..."
mkdir -p "${OUTPUT_DIR}"

# 1. Compile Once into isolated DESTDIR
if [ ! -d "${STAGE_DIR}/usr" ]; then
    echo "==> Staging Jots via Meson..."
    rm -rf "${BUILD_DIR}" "${STAGE_DIR}"
    meson setup "${BUILD_DIR}" \
        --prefix=/usr \
        --buildtype=release \
        --strip \
        -Dprofile=linux \
        -Ddevelopment=false \
        -Dicon_variant=default
    meson compile -C "${BUILD_DIR}"
    DESTDIR="$(pwd)/${STAGE_DIR}" meson install -C "${BUILD_DIR}"
fi

# 2. Pre-compile schemas inside staging
glib-compile-schemas "${STAGE_DIR}/usr/share/glib-2.0/schemas"

# 3. Assemble AppDir
APPDIR="AppDir"
rm -rf "${APPDIR}"
cp -r "${STAGE_DIR}" "${APPDIR}"

# Apply custom dual-entrypoint AppRun
cp packaging/appimage/AppRun "${APPDIR}/AppRun"
chmod +x "${APPDIR}/AppRun"

# 4. Fetch linuxdeploy tooling if not present
export APPIMAGE_EXTRACT_AND_RUN=1
if [ ! -f "linuxdeploy-${ARCH}.AppImage" ]; then
    echo "==> Downloading linuxdeploy-${ARCH}.AppImage..."
    wget -q "https://github.com/linuxdeploy/linuxdeploy/releases/download/continuous/linuxdeploy-${ARCH}.AppImage"
    chmod +x "linuxdeploy-${ARCH}.AppImage"
fi

if [ ! -f "linuxdeploy-plugin-gtk.sh" ]; then
    echo "==> Downloading linuxdeploy-plugin-gtk.sh..."
    wget -q "https://raw.githubusercontent.com/linuxdeploy/linuxdeploy-plugin-gtk/master/linuxdeploy-plugin-gtk.sh"
    chmod +x "linuxdeploy-plugin-gtk.sh"
fi

# 5. Execute linuxdeploy with GTK plugin
export OUTPUT="${OUTPUT_DIR}/Jots-${ARCH}.AppImage"
./linuxdeploy-${ARCH}.AppImage \
    --appdir "${APPDIR}" \
    --desktop-file "${APPDIR}/usr/share/applications/io.github.comicdeed.jots.desktop" \
    --icon-file "${APPDIR}/usr/share/icons/hicolor/scalable/apps/io.github.comicdeed.jots.svg" \
    --plugin gtk \
    --output appimage

echo "==> Successfully created ${OUTPUT}!"
