"""Check the actual exported APK against the repository's public debug identity."""
import argparse
import hashlib
from pathlib import Path
import re
import subprocess
import zipfile


def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("apk", type=Path)
    parser.add_argument("--build-tools", type=Path, required=True)
    args = parser.parse_args()
    certificate = subprocess.check_output([
        "keytool", "-exportcert", "-alias", "androiddebugkey", "-keystore",
        "tools/android/debug.keystore", "-storepass", "android",
    ])
    expected = hashlib.sha256(certificate).hexdigest()
    verification = subprocess.check_output([
        str(args.build_tools / "apksigner"), "verify", "--verbose", "--print-certs", str(args.apk),
    ], text=True)
    actual = re.search(r"Signer #1 certificate SHA-256 digest: ([0-9a-f]+)", verification)
    if not actual or actual.group(1) != expected:
        raise SystemExit("APK signing certificate does not match the stable debug identity")
    badging = subprocess.check_output([
        str(args.build_tools / "aapt"), "dump", "badging", str(args.apk),
    ], text=True)
    if "package: name='sv.apenalegaltech.wivoritrails'" not in badging or "versionName='0.4.0'" not in badging:
        raise SystemExit("Unexpected Android package identity or version")
    with zipfile.ZipFile(args.apk) as archive:
        if archive.testzip() is not None:
            raise SystemExit("APK archive is damaged")
        if not any(name.startswith("lib/arm64-v8a/") for name in archive.namelist()):
            raise SystemExit("APK does not include native ARM64 libraries")
    print(verification)
    print(f"Verified Wivori Trails 0.4.0 ARM64; stable debug SHA-256: {expected}")


if __name__ == "__main__":
    main()
