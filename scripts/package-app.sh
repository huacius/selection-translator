#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Selection Translator"
BUNDLE_NAME="${APP_NAME}.app"
BUNDLE_ID="com.sengo.selectiontranslator"
APP_VERSION="$(tr -d '\n' < "${ROOT_DIR}/VERSION")"
DIST_DIR="${ROOT_DIR}/dist"
APP_DIR="${DIST_DIR}/${BUNDLE_NAME}"
MACOS_DIR="${APP_DIR}/Contents/MacOS"
RESOURCES_DIR="${APP_DIR}/Contents/Resources"
CODESIGN_IDENTITY="${CODESIGN_IDENTITY:-}"
CREATE_ZIP="${CREATE_ZIP:-1}"
ZIP_PATH="${DIST_DIR}/${BUNDLE_NAME}.zip"

if ! command -v swift >/dev/null 2>&1; then
  echo "error: swift command not found."
  exit 1
fi

build_release_binary() {
  if swift build -c release --product SelectionTranslator; then
    return 0
  fi

  echo "Release build failed once. Cleaning SwiftPM build artifacts and retrying..."
  rm -rf "${ROOT_DIR}/.build"
  swift build -c release --product SelectionTranslator
}

echo "Building release binary..."
build_release_binary

echo "Generating app icon..."
ICON_ICNS="$(cd "${ROOT_DIR}" && swift scripts/generate_app_icon.swift)"

echo "Creating app bundle..."
rm -rf "${APP_DIR}"
mkdir -p "${MACOS_DIR}" "${RESOURCES_DIR}"

cp "${ROOT_DIR}/.build/release/SelectionTranslator" "${MACOS_DIR}/SelectionTranslator"
chmod +x "${MACOS_DIR}/SelectionTranslator"
cp "${ICON_ICNS}" "${RESOURCES_DIR}/AppIcon.icns"

cat > "${APP_DIR}/Contents/Info.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>CFBundleDevelopmentRegion</key>
  <string>zh_CN</string>
  <key>CFBundleExecutable</key>
  <string>SelectionTranslator</string>
  <key>CFBundleIconFile</key>
  <string>AppIcon</string>
  <key>CFBundleIdentifier</key>
  <string>com.sengo.selectiontranslator</string>
  <key>CFBundleInfoDictionaryVersion</key>
  <string>6.0</string>
  <key>CFBundleName</key>
  <string>Selection Translator</string>
  <key>CFBundlePackageType</key>
  <string>APPL</string>
  <key>CFBundleShortVersionString</key>
  <string>${APP_VERSION}</string>
  <key>CFBundleVersion</key>
  <string>1</string>
  <key>LSMinimumSystemVersion</key>
  <string>13.0</string>
  <key>LSUIElement</key>
  <true/>
  <key>NSHighResolutionCapable</key>
  <true/>
</dict>
</plist>
PLIST

printf "APPL????" > "${APP_DIR}/Contents/PkgInfo"

echo "Signing app bundle..."
if [[ -n "${CODESIGN_IDENTITY}" ]]; then
  echo "Using codesign identity: ${CODESIGN_IDENTITY}"
  codesign \
    --force \
    --deep \
    --options runtime \
    --timestamp \
    --sign "${CODESIGN_IDENTITY}" \
    "${APP_DIR}"
else
  echo "Warning: no CODESIGN_IDENTITY configured; falling back to ad-hoc signing."
  echo "Ad-hoc signed builds often lose Accessibility permission after rebuilds."
  codesign --force --deep --sign - "${APP_DIR}"
fi

echo "Verifying code signature..."
codesign --verify --deep --strict --verbose=2 "${APP_DIR}"

echo "Assessing app bundle..."
if ! spctl --assess --type execute --verbose=4 "${APP_DIR}"; then
  if [[ -n "${CODESIGN_IDENTITY}" ]]; then
    echo "error: Gatekeeper assessment failed for signed build."
    exit 1
  fi
  echo "Note: Gatekeeper assessment can fail for ad-hoc builds before notarization."
fi

if [[ "${CREATE_ZIP}" == "1" ]]; then
  echo "Creating zip archive..."
  rm -f "${ZIP_PATH}"
  ditto -c -k --keepParent "${APP_DIR}" "${ZIP_PATH}"
fi

echo "App bundle created:"
echo "${APP_DIR}"
if [[ "${CREATE_ZIP}" == "1" ]]; then
  echo "Zip archive created:"
  echo "${ZIP_PATH}"
fi
