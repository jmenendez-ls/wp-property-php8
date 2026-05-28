#!/usr/bin/env bash
# build-zip.sh — Generate production ZIP for WP-Property
# Usage: ./build-zip.sh [version]
#
# Examples:
#   ./build-zip.sh 3.0.0
#   ./build-zip.sh              # defaults to 3.0.0
set -euo pipefail

VERSION="${1:-3.0.0}"
SLUG="wp-property"
BUILD_ROOT="build"
BUILD_DIR="$BUILD_ROOT/$SLUG"
ZIP_NAME="$SLUG-$VERSION.zip"

echo "==> Building $SLUG v$VERSION"

# 1. Clean previous build
rm -rf "$BUILD_ROOT"
mkdir -p "$BUILD_DIR"

# 2. Copy production files
# Note: vendor/ is committed directly — the private Composer repository
# (repository.usabilitydynamics.com) is no longer available, so composer install
# cannot resolve dependencies. All libraries are already in vendor/libraries/.
echo "==> Copying production files"
for file in wp-property.php composer.json readme.txt readme.md; do
  if [ -f "$file" ]; then
    cp "$file" "$BUILD_DIR/$file"
  else
    echo "WARNING: expected file '$file' not found, skipping"
  fi
done

for dir in addons bin lib static vendor; do
  if [ -d "$dir" ]; then
    cp -r "$dir" "$BUILD_DIR/$dir"
  else
    echo "WARNING: expected directory '$dir' not found, skipping"
  fi
done

# 3. Strip dev/source artifacts from the build copy
echo "==> Stripping dev/source artifacts"

# Core static dev artifacts
rm -rf "$BUILD_DIR/static/cache"
rm -rf "$BUILD_DIR/static/codex"
rm -rf "$BUILD_DIR/static/readme.html"
rm -rf "$BUILD_DIR/static/styles/src"
rm -rf "$BUILD_DIR/static/scripts/src"

# Composer installer plugin (build-time only)
rm -rf "$BUILD_DIR/vendor/composer/installers"

# Addon LESS/JS source directories
find "$BUILD_DIR/addons" -type d -name src \
  \( -path "*/scripts/src" -o -path "*/styles/src" \) \
  -exec rm -rf {} + 2>/dev/null || true

# Vendor library dev artifacts (from composer.json archive.exclude)
rm -rf "$BUILD_DIR/vendor/libraries/usabilitydynamics/lib-ui/static/scripts/src"
rm -rf "$BUILD_DIR/vendor/libraries/usabilitydynamics/lib-ui/static/scripts/editor"
rm -rf "$BUILD_DIR/vendor/libraries/usabilitydynamics/lib-ui/static/styles/src"
rm -rf "$BUILD_DIR/vendor/libraries/usabilitydynamics/lib-ui/static/test"
rm -rf "$BUILD_DIR/vendor/libraries/usabilitydynamics/lib-ui/static/examples"
rm -rf "$BUILD_DIR/vendor/libraries/usabilitydynamics/lib-ud-api-client/static/css/src"
rm -rf "$BUILD_DIR/vendor/libraries/usabilitydynamics/lib-settings/static/scripts/src"
rm -rf "$BUILD_DIR/vendor/libraries/usabilitydynamics/lib-settings/test"
rm -rf "$BUILD_DIR/vendor/libraries/usabilitydynamics/lib-utility/test"
rm -rf "$BUILD_DIR/vendor/libraries/usabilitydynamics/lib-utility/scripts/src"
rm -rf "$BUILD_DIR/vendor/libraries/usabilitydynamics/lib-wp-shortcode/test"

# Nested VCS directories in vendor
find "$BUILD_DIR/vendor" -type d \( -name .git -o -name .svn \) \
  -exec rm -rf {} + 2>/dev/null || true

# Nested VCS directories in addons (just in case)
find "$BUILD_DIR/addons" -type d \( -name .git -o -name .svn \) \
  -exec rm -rf {} + 2>/dev/null || true

# Vendor plugin nested vendor src/test dirs (wp-rets-client bundles its own lib-ui)
find "$BUILD_DIR/vendor/plugins" -type d -name src \
  \( -path "*/scripts/src" -o -path "*/styles/src" \) \
  -exec rm -rf {} + 2>/dev/null || true

# 4. Create ZIP
echo "==> Creating ZIP archive"
cd "$BUILD_ROOT"
zip -qr "$ZIP_NAME" "$SLUG/"
ZIP_SIZE=$(du -h "$ZIP_NAME" | cut -f1)
cd ..

echo ""
echo "================================================"
echo "  Built: $BUILD_ROOT/$ZIP_NAME ($ZIP_SIZE)"
echo "================================================"
