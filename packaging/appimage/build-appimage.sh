#!/bin/bash
set -euo pipefail

# Architecture and version detection
ARCH="${ARCH:-$(uname -m)}"
VERSION="${VERSION:-$(grep -m 1 "version:" meson.build | cut -d"'" -f2)}"
STAGE_DIR="${STAGE_DIR:-stage}"
BUILD_DIR="${BUILD_DIR:-builddir-appimage}"
OUTPUT_DIR="${OUTPUT_DIR:-dist}"

echo "==> Building Jots AppImage ${VERSION} for ${ARCH}..."
mkdir -p "${OUTPUT_DIR}"

# 1. Compile into isolated DESTDIR
echo "==> Compiling Jots via Meson..."
rm -rf "${STAGE_DIR}"
if [ ! -d "${BUILD_DIR}" ]; then
    meson setup "${BUILD_DIR}" \
        --prefix=/usr \
        --buildtype=release \
        --strip \
        -Dprofile=linux \
        -Ddevelopment=false \
        -Dicon_variant=default
fi
meson compile -C "${BUILD_DIR}"
DESTDIR="$(pwd)/${STAGE_DIR}" meson install -C "${BUILD_DIR}"

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

# 5. Execute linuxdeploy with GTK plugin to populate dependencies
./linuxdeploy-${ARCH}.AppImage \
    --appdir "${APPDIR}" \
    --desktop-file "${APPDIR}/usr/share/applications/io.github.comicdeed.jots.desktop" \
    --icon-file "${APPDIR}/usr/share/icons/hicolor/scalable/apps/io.github.comicdeed.jots.svg" \
    --plugin gtk

# 6. Bundle full runtime and font rendering dependencies for universal host backwards compatibility
for libname in libharfbuzz libfreetype libfontconfig libfribidi libgraphite2 libpixman libpng libbrotli libzstd libexpat libffi libc libm libpthread libresolv librt libdl ld-linux; do
    find /lib/${ARCH}-linux-gnu /usr/lib/${ARCH}-linux-gnu -name "${libname}*.so*" -exec cp -d {} "${APPDIR}/usr/lib/" \; 2>/dev/null || true
done

# Re-apply custom AppRun launcher
cp packaging/appimage/AppRun "${APPDIR}/AppRun"
chmod +x "${APPDIR}/AppRun"

# 7. Package AppImage via appimagetool
if [ ! -f "appimagetool-${ARCH}.AppImage" ]; then
    echo "==> Downloading appimagetool-${ARCH}.AppImage..."
    wget -q "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-${ARCH}.AppImage"
    chmod +x "appimagetool-${ARCH}.AppImage"
fi

export OUTPUT="${OUTPUT_DIR}/Jots-${VERSION}-${ARCH}.AppImage"
rm -f "${OUTPUT}"
./appimagetool-${ARCH}.AppImage "${APPDIR}" "${OUTPUT}"

(cd "${OUTPUT_DIR}" && sha256sum "Jots-${VERSION}-${ARCH}.AppImage" > "Jots-${VERSION}-${ARCH}.AppImage.sha256")

echo "==> Successfully created ${OUTPUT} and checksum!"
