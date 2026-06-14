#!/usr/bin/env bash
# =============================================================================
# Omega — Project Setup Script
# Run from the repository root:  bash scripts/setup.sh
# =============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT"

RED='\033[0;31m'
YELLOW='\033[1;33m'
GREEN='\033[0;32m'
NC='\033[0m' # No Color

echo "==> Omega project setup starting..."
echo "    Working directory: $REPO_ROOT"
echo ""

# ---------------------------------------------------------------------------
# 1. Check Flutter is installed
# ---------------------------------------------------------------------------
echo "--> Checking Flutter installation..."
if ! command -v flutter &>/dev/null; then
  echo -e "${RED}ERROR: Flutter is not installed or not on PATH.${NC}"
  echo "      Install from https://docs.flutter.dev/get-started/install"
  exit 1
fi

FLUTTER_VERSION=$(flutter --version 2>&1 | head -n 1)
echo -e "${GREEN}OK${NC} Found: $FLUTTER_VERSION"
echo ""

# ---------------------------------------------------------------------------
# 2. flutter pub get
# ---------------------------------------------------------------------------
echo "--> Running flutter pub get..."
flutter pub get
echo -e "${GREEN}OK${NC} Dependencies fetched."
echo ""

# ---------------------------------------------------------------------------
# 3. Build runner — code generation
# ---------------------------------------------------------------------------
echo "--> Running build_runner (this may take a minute)..."
flutter pub run build_runner build --delete-conflicting-outputs
echo -e "${GREEN}OK${NC} Code generation complete."
echo ""

# ---------------------------------------------------------------------------
# 4. Check Firebase config files
# ---------------------------------------------------------------------------
echo "--> Checking Firebase configuration files..."

ANDROID_CONFIG="$REPO_ROOT/android/app/google-services.json"
IOS_CONFIG="$REPO_ROOT/ios/Runner/GoogleService-Info.plist"
MISSING_CONFIGS=0

if [ ! -f "$ANDROID_CONFIG" ]; then
  echo -e "${YELLOW}WARN: android/app/google-services.json not found.${NC}"
  echo "      Copy android/app/google-services.json.example as a reference"
  echo "      and replace placeholder values with your Firebase project credentials."
  MISSING_CONFIGS=$((MISSING_CONFIGS + 1))
else
  echo -e "${GREEN}OK${NC} android/app/google-services.json found."
fi

if [ ! -f "$IOS_CONFIG" ]; then
  echo -e "${YELLOW}WARN: ios/Runner/GoogleService-Info.plist not found.${NC}"
  echo "      Copy ios/Runner/GoogleService-Info.plist.example as a reference"
  echo "      and replace placeholder values with your Firebase project credentials."
  MISSING_CONFIGS=$((MISSING_CONFIGS + 1))
else
  echo -e "${GREEN}OK${NC} ios/Runner/GoogleService-Info.plist found."
fi

if [ $MISSING_CONFIGS -gt 0 ]; then
  echo ""
  echo -e "${YELLOW}NOTE: $MISSING_CONFIGS Firebase config file(s) missing.${NC}"
  echo "      The app will not connect to Firebase until these are added."
  echo "      See the .example files for the required structure."
fi

echo ""
echo -e "${GREEN}============================================================${NC}"
echo -e "${GREEN} Setup complete! You can now run:${NC}"
echo -e "${GREEN}   flutter run${NC}"
echo -e "${GREEN}============================================================${NC}"
