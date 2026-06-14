#!/usr/bin/env bash
# =============================================================================
# Omega — iOS Release Build Script
# Run from the repository root:  bash scripts/build_ios.sh
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo "==> Building Omega for iOS (release, no-codesign)..."
echo "    Working directory: $REPO_ROOT"
echo ""

# ---------------------------------------------------------------------------
# Build iOS release (no code signing — signing is handled in Xcode)
# ---------------------------------------------------------------------------
echo "--> Running flutter build ios --release --no-codesign..."
flutter build ios --release --no-codesign

BUILD_DIR="$REPO_ROOT/build/ios/iphoneos"
echo -e "${GREEN}OK${NC} iOS build complete."
echo -e "    ${CYAN}Build output:${NC} $BUILD_DIR"
echo ""

# ---------------------------------------------------------------------------
# Xcode archive instructions
# ---------------------------------------------------------------------------
echo "============================================================"
echo " Next steps — Archive and distribute via Xcode:"
echo ""
echo "  1. Open the project in Xcode:"
echo "       open ios/Runner.xcworkspace"
echo ""
echo "  2. In Xcode, select a real device or 'Any iOS Device (arm64)'"
echo "     as the build destination (not a simulator)."
echo ""
echo "  3. Set your Team and code-signing certificate:"
echo "       Runner target -> Signing & Capabilities"
echo ""
echo "  4. Create an archive:"
echo "       Xcode menu -> Product -> Archive"
echo ""
echo "  5. In the Organizer window that opens:"
echo "     - For App Store: click 'Distribute App' -> App Store Connect"
echo "     - For Ad Hoc / Enterprise: choose the appropriate method"
echo ""
echo -e "  ${YELLOW}NOTE:${NC} Ensure ios/Runner/GoogleService-Info.plist is present"
echo "        and included in the Runner target before archiving."
echo "============================================================"
