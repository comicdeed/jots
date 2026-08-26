FROM ubuntu:24.04

ENV DEBIAN_FRONTEND=noninteractive

RUN apt-get update && \
    apt-get install -y --no-install-recommends \
      ca-certificates wget curl file dpkg-dev xvfb dbus dbus-x11 \
      meson ninja-build valac gcc pkg-config gettext \
      libgtk-4-dev libgee-0.8-dev \
      libjson-glib-dev libportal-dev libportal-gtk4-dev \
      desktop-file-utils libglib2.0-bin appstream zsync && \
    rm -rf /var/lib/apt/lists/*

WORKDIR /workspace

CMD ["./packaging/appimage/build-appimage.sh"]
