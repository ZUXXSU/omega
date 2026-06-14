#!/usr/bin/env bash
# =============================================================================
# Omega — Android Release Build Script
# Run from the repository root:  bash scripts/build_android.sh
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
NC='\033[0m'

echo "==> Building Omega for Android (release)..."
echo "    Working directory: $REPO_ROOT"
echo ""

# ---------------------------------------------------------------------------
# 1. Build APK
# ---------------------------------------------------------------------------
echo "--> Building release APK..."
flutter build apk --release
APK_PATH="$REPO_ROOT/build/app/outputs/flutter-apk/app-release.apk"
echo -e "${GREEN}OK${NC} APK built."
echo -e "    ${CYAN}Output:${NC} $APK_PATH"
echo ""

# ---------------------------------------------------------------------------
# 2. Build App Bundle (recommended for Play Store)
# ---------------------------------------------------------------------------
echo "--> Building release App Bundle (.aab)..."
flutter build appbundle --release
AAB_PATH="$REPO_ROOT/build/app/outputs/bundle/release/app-release.aab"
echo -e "${GREEN}OK${NC} App Bundle built."
echo -e "    ${CYAN}Output:${NC} $AAB_PATH"
echo ""

# ---------------------------------------------------------------------------
# Summary
# ---------------------------------------------------------------------------
echo "============================================================"
echo " Android build artifacts:"
echo ""
echo "  APK (direct install / testing):"
echo "    $APK_PATH"
echo ""
echo "  App Bundle (Google Play Store upload):"
echo "    $AAB_PATH"
echo ""
echo "  To install the APK on a connected device:"
echo "    adb install $APK_PATH"
echo "============================================================"
