#!/usr/bin/env bash
set -e

echo "Installing Flutter..."

FLUTTER_VERSION="3.22.3"
FLUTTER_DIR="$HOME/flutter"

if [ ! -d "$FLUTTER_DIR" ]; then
  curl -sSL https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_${FLUTTER_VERSION}-stable.tar.xz -o flutter.tar.xz
  tar -xf flutter.tar.xz
  mv flutter "$FLUTTER_DIR"
  rm flutter.tar.xz
fi

export PATH="$FLUTTER_DIR/bin:$PATH"

flutter --version
flutter config --no-analytics
flutter precache --web
flutter pub get
flutter build web --release
