#!/usr/bin/env bash
set -euo pipefail

# Use only the JDK, Android SDK and standard utilities already used by Godot CI.
APK_PATH="${1:?Pass the APK path}"
ANDROID_BUILD_TOOLS="${2:?Pass the Android build-tools directory}"
EXPECTED_CERT_SHA256="$(keytool -exportcert -alias androiddebugkey \
  -keystore tools/android/debug.keystore -storepass android | sha256sum | cut -d ' ' -f 1)"
SIGNATURE_OUTPUT="$("$ANDROID_BUILD_TOOLS/apksigner" verify --verbose --print-certs "$APK_PATH")"
ACTUAL_CERT_SHA256="$(sed -n 's/^Signer #1 certificate SHA-256 digest: //p' <<< "$SIGNATURE_OUTPUT")"
if [[ "$ACTUAL_CERT_SHA256" != "$EXPECTED_CERT_SHA256" ]]; then
  echo "APK signing certificate does not match the stable debug identity" >&2
  exit 1
fi

BADGING_OUTPUT="$("$ANDROID_BUILD_TOOLS/aapt" dump badging "$APK_PATH")"
if [[ "$BADGING_OUTPUT" != *"package: name='sv.apenalegaltech.wivoritrails'"* || \
      "$BADGING_OUTPUT" != *"versionName='0.4.0'"* ]]; then
  echo "Unexpected Android package identity or version" >&2
  exit 1
fi
unzip -t "$APK_PATH" | tail -1
APK_ENTRIES="$(unzip -Z1 "$APK_PATH")"
if ! grep -q '^lib/arm64-v8a/' <<< "$APK_ENTRIES"; then
  echo "APK does not include native ARM64 libraries" >&2
  exit 1
fi
printf '%s\n' "$SIGNATURE_OUTPUT"
printf 'Verified Wivori Trails 0.4.0 ARM64; stable debug SHA-256: %s\n' "$EXPECTED_CERT_SHA256"
