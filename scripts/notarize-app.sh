#!/bin/zsh
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "$0")/.." && pwd)"
APP_NAME="Selection Translator"
BUNDLE_NAME="${APP_NAME}.app"
DIST_DIR="${ROOT_DIR}/dist"
APP_PATH="${APP_PATH:-${DIST_DIR}/${BUNDLE_NAME}}"
ZIP_PATH="${ZIP_PATH:-${DIST_DIR}/${BUNDLE_NAME}.zip}"
KEYCHAIN_PROFILE="${KEYCHAIN_PROFILE:-}"
APPLE_ID="${APPLE_ID:-}"
APPLE_APP_PASSWORD="${APPLE_APP_PASSWORD:-}"
TEAM_ID="${TEAM_ID:-}"

if ! command -v xcrun >/dev/null 2>&1; then
  echo "error: xcrun command not found."
  exit 1
fi

if [[ ! -d "${APP_PATH}" ]]; then
  echo "error: app bundle not found at ${APP_PATH}"
  exit 1
fi

if [[ ! -f "${ZIP_PATH}" ]]; then
  echo "Zip archive not found, creating one from app bundle..."
  ditto -c -k --keepParent "${APP_PATH}" "${ZIP_PATH}"
fi

NOTARY_AUTH_ARGS=()
if [[ -n "${KEYCHAIN_PROFILE}" ]]; then
  NOTARY_AUTH_ARGS=(--keychain-profile "${KEYCHAIN_PROFILE}")
elif [[ -n "${APPLE_ID}" && -n "${APPLE_APP_PASSWORD}" && -n "${TEAM_ID}" ]]; then
  NOTARY_AUTH_ARGS=(--apple-id "${APPLE_ID}" --password "${APPLE_APP_PASSWORD}" --team-id "${TEAM_ID}")
else
  echo "error: notarization credentials are missing."
  echo "Set KEYCHAIN_PROFILE, or set APPLE_ID, APPLE_APP_PASSWORD, and TEAM_ID."
  exit 1
fi

echo "Submitting archive for notarization..."
xcrun notarytool submit "${ZIP_PATH}" "${NOTARY_AUTH_ARGS[@]}" --wait

echo "Stapling notarization ticket..."
xcrun stapler staple "${APP_PATH}"

echo "Validating stapled app..."
xcrun stapler validate "${APP_PATH}"

echo "Assessing notarized app..."
spctl --assess --type execute --verbose=4 "${APP_PATH}"

echo "Notarization complete:"
echo "${APP_PATH}"
