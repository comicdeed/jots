FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update

RUN apt-get install -y --no-install-recommends \
    ca-certificates wget curl file dpkg-dev git

RUN apt-get install -y --no-install-recommends \
    meson ninja-build valac gcc pkg-config gettext

RUN apt-get install -y --no-install-recommends \
    libgtk-4-dev libgee-0.8-dev libjson-glib-dev \
    libportal-dev libportal-gtk4-dev

RUN apt-get install -y --no-install-recommends \
    librsvg2-dev librsvg2-common

RUN apt-get install -y --no-install-recommends \
    desktop-file-utils libglib2.0-bin appstream zsync xvfb dbus dbus-x11 && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["./packaging/appimage/build-appimage.sh"]
