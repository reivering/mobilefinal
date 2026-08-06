#!/usr/bin/env bash
set -euo pipefail

# Vercel's build image does not provide Flutter by default. Keep the version
# aligned with the project's Flutter metadata and cache the SDK between builds.
FLUTTER_VERSION="3.41.9"
FLUTTER_ROOT="${HOME}/.cache/flutter-${FLUTTER_VERSION}"

if ! command -v flutter >/dev/null 2>&1; then
  if [ ! -x "${FLUTTER_ROOT}/bin/flutter" ]; then
    mkdir -p "${HOME}/.cache"
    archive="${HOME}/.cache/flutter-${FLUTTER_VERSION}.tar.xz"
    if [ ! -f "$archive" ]; then
      curl --fail --location --retry 3 \
        "https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz" \
        --output "$archive"
    fi
    rm -rf "${FLUTTER_ROOT}.tmp"
    mkdir -p "${FLUTTER_ROOT}.tmp"
    tar -xJf "$archive" -C "${FLUTTER_ROOT}.tmp"
    mv "${FLUTTER_ROOT}.tmp/flutter" "$FLUTTER_ROOT"
    rm -rf "${FLUTTER_ROOT}.tmp"
  fi
  export PATH="${FLUTTER_ROOT}/bin:${PATH}"
fi

flutter pub get
flutter build web --release
