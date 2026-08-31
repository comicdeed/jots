#!/bin/bash
set -euo pipefail

# Parse flags
DEVEL=0
for arg in "$@"; do
    case "$arg" in
        --devel) DEVEL=1 ;;
    esac
done

# Architecture and version detection
ARCH="${ARCH:-$(uname -m)}"
VERSION="${VERSION:-$(grep -m 1 "version:" meson.build | cut -d"'" -f2)}"
STAGE_DIR="${STAGE_DIR:-stage}"
BUILD_DIR="${BUILD_DIR:-builddir-appimage}"
OUTPUT_DIR="${OUTPUT_DIR:-dist}"
CLEAN_BUILD="${CLEAN_BUILD:-1}"

# Devel vs stable build configuration
if [ "$DEVEL" = "1" ]; then
    APP_ID="io.github.comicdeed.jots.devel"
    MESON_DEVELOPMENT=true
    BUILDTYPE=debug
    STRIP_FLAG=""
    OUTPUT_SUFFIX="-devel"
    echo "==> Building Jots DEVEL AppImage ${VERSION} for ${ARCH} (debug, unit-tests wired)..."
else
    APP_ID="io.github.comicdeed.jots"
    MESON_DEVELOPMENT=false
    BUILDTYPE=debugoptimized
    STRIP_FLAG="--strip"
    OUTPUT_SUFFIX=""
    echo "==> Building Jots AppImage ${VERSION} for ${ARCH}..."
fi

mkdir -p "${OUTPUT_DIR}"

# 1. Compile into isolated DESTDIR
echo "==> Compiling Jots via Meson..."
if [ "${CLEAN_BUILD}" = "1" ]; then
    echo "==> Clean build mode enabled (CLEAN_BUILD=1)."
    rm -rf "${STAGE_DIR}" "${BUILD_DIR}"
    meson setup "${BUILD_DIR}" \
        --prefix=/usr \
        --buildtype=${BUILDTYPE} \
        ${STRIP_FLAG} \
        -Dprofile=linux \
        -Ddevelopment=${MESON_DEVELOPMENT} \
        -Dicon_variant=default
else
    echo "==> Incremental build mode enabled (CLEAN_BUILD=0)."
    rm -rf "${STAGE_DIR}"
    if [ -d "${BUILD_DIR}" ]; then
        meson setup "${BUILD_DIR}" \
            --reconfigure \
            --prefix=/usr \
            --buildtype=${BUILDTYPE} \
            ${STRIP_FLAG} \
            -Dprofile=linux \
            -Ddevelopment=${MESON_DEVELOPMENT} \
            -Dicon_variant=default
    else
        meson setup "${BUILD_DIR}" \
            --prefix=/usr \
            --buildtype=${BUILDTYPE} \
            ${STRIP_FLAG} \
            -Dprofile=linux \
            -Ddevelopment=${MESON_DEVELOPMENT} \
            -Dicon_variant=default
    fi
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
    --desktop-file "${APPDIR}/usr/share/applications/${APP_ID}.desktop" \
    --icon-file "${APPDIR}/usr/share/icons/hicolor/scalable/apps/${APP_ID}.svg" \
    --plugin gtk 2>&1 | sed -E \
    -e '/Could not find copyright files for file/d' \
    -e '/Not calling strip on binary .*rpath starts with \$/d'

# 6. Bundle full runtime, SVG engine, and font rendering dependencies for universal host backwards compatibility
for libname in librsvg libharfbuzz libfreetype libfontconfig libfribidi libgraphite2 libpixman libpng libbrotli libzstd libexpat libffi libc libm libpthread libresolv librt libdl ld-linux; do
    find /lib/${ARCH}-linux-gnu /usr/lib/${ARCH}-linux-gnu -name "${libname}*.so*" -exec cp -d {} "${APPDIR}/usr/lib/" \; 2>/dev/null || true
done

# Ensure SVG loader is copied and gdk-pixbuf loaders.cache is generated
mkdir -p "${APPDIR}/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders"
find /usr/lib/${ARCH}-linux-gnu/gdk-pixbuf-2.0/2.10.0/loaders /usr/lib/gdk-pixbuf-2.0/2.10.0/loaders -name "libpixbufloader-*.so" -exec cp -u {} "${APPDIR}/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders/" \; 2>/dev/null || true

if [ ! -f "${APPDIR}/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders/libpixbufloader-svg.so" ]; then
    echo "ERROR: libpixbufloader-svg.so not found! Please install librsvg2-common." >&2
    exit 1
fi

if command -v gdk-pixbuf-query-loaders >/dev/null 2>&1; then
    gdk-pixbuf-query-loaders "${APPDIR}/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders"/*.so > "${APPDIR}/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache" 2>/dev/null || true
    sed -i "s|${APPDIR}||g" "${APPDIR}/usr/lib/gdk-pixbuf-2.0/2.10.0/loaders.cache" 2>/dev/null || true
fi

# Re-apply custom AppRun launcher
cp packaging/appimage/AppRun "${APPDIR}/AppRun"
chmod +x "${APPDIR}/AppRun"

# 7. Package AppImage via appimagetool
if [ ! -f "appimagetool-${ARCH}.AppImage" ]; then
    echo "==> Downloading appimagetool-${ARCH}.AppImage..."
    wget -q "https://github.com/AppImage/AppImageKit/releases/download/continuous/appimagetool-${ARCH}.AppImage"
    chmod +x "appimagetool-${ARCH}.AppImage"
fi

export OUTPUT="${OUTPUT_DIR}/Jots${OUTPUT_SUFFIX}-${VERSION}-${ARCH}.AppImage"
rm -f "${OUTPUT}"
./appimagetool-${ARCH}.AppImage "${APPDIR}" "${OUTPUT}"

(cd "${OUTPUT_DIR}" && sha256sum "Jots${OUTPUT_SUFFIX}-${VERSION}-${ARCH}.AppImage" > "Jots${OUTPUT_SUFFIX}-${VERSION}-${ARCH}.AppImage.sha256")

echo "==> Successfully created ${OUTPUT} and checksum!"
