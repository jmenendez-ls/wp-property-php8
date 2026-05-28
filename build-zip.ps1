# build-zip.ps1 — Generate production ZIP for WP-Property
# Usage: .\build-zip.ps1 [-Version "3.0.0"]
#
# Examples:
#   .\build-zip.ps1 -Version "3.0.0"
#   .\build-zip.ps1                     # defaults to 3.0.0
param([string]$Version = "3.0.0")

$SLUG = "wp-property"
$BUILD_ROOT = "build"
$BUILD_DIR = "$BUILD_ROOT\$SLUG"
$ZIP_NAME = "$SLUG-$Version.zip"

Write-Host "==> Building $SLUG v$Version"

# 1. Clean previous build
if (Test-Path $BUILD_ROOT) { Remove-Item -Recurse -Force $BUILD_ROOT }

# 2. Composer production install (vendor-dir is vendor/libraries per composer.json)
if (Get-Command composer -ErrorAction SilentlyContinue) {
    Write-Host "==> Running composer install --no-dev"
    composer install --no-dev --no-interaction --optimize-autoloader
} else {
    Write-Host "WARNING: composer not found - skipping composer install."
    Write-Host "         The vendor/ directory will be copied as-is."
}

# 3. Copy production files
Write-Host "==> Copying production files"

$dirs = @("addons", "bin", "lib", "static", "vendor")
$files = @("wp-property.php", "composer.json", "readme.txt", "readme.md")

New-Item -ItemType Directory -Path $BUILD_DIR -Force | Out-Null
foreach ($f in $files) {
    if (Test-Path $f) {
        Copy-Item $f "$BUILD_DIR\$f"
    } else {
        Write-Host "WARNING: expected file '$f' not found, skipping"
    }
}
foreach ($d in $dirs) {
    if (Test-Path $d) {
        Copy-Item -Recurse $d "$BUILD_DIR\$d"
    } else {
        Write-Host "WARNING: expected directory '$d' not found, skipping"
    }
}

# 4. Strip dev/source artifacts from the build copy
Write-Host "==> Stripping dev/source artifacts"

$removeList = @(
    # Core static dev artifacts
    "$BUILD_DIR\static\cache",
    "$BUILD_DIR\static\codex",
    "$BUILD_DIR\static\readme.html",
    "$BUILD_DIR\static\styles\src",
    "$BUILD_DIR\static\scripts\src",
    # Composer installer plugin (build-time only)
    "$BUILD_DIR\vendor\composer\installers",
    # Vendor library dev artifacts (from composer.json archive.exclude)
    "$BUILD_DIR\vendor\libraries\usabilitydynamics\lib-ui\static\scripts\src",
    "$BUILD_DIR\vendor\libraries\usabilitydynamics\lib-ui\static\scripts\editor",
    "$BUILD_DIR\vendor\libraries\usabilitydynamics\lib-ui\static\styles\src",
    "$BUILD_DIR\vendor\libraries\usabilitydynamics\lib-ui\static\test",
    "$BUILD_DIR\vendor\libraries\usabilitydynamics\lib-ui\static\examples",
    "$BUILD_DIR\vendor\libraries\usabilitydynamics\lib-ud-api-client\static\css\src",
    "$BUILD_DIR\vendor\libraries\usabilitydynamics\lib-settings\static\scripts\src",
    "$BUILD_DIR\vendor\libraries\usabilitydynamics\lib-settings\test",
    "$BUILD_DIR\vendor\libraries\usabilitydynamics\lib-utility\test",
    "$BUILD_DIR\vendor\libraries\usabilitydynamics\lib-utility\scripts\src",
    "$BUILD_DIR\vendor\libraries\usabilitydynamics\lib-wp-shortcode\test"
)
foreach ($p in $removeList) {
    if (Test-Path $p) { Remove-Item -Recurse -Force $p }
}

# Remove LESS/JS source dirs from addons
Get-ChildItem -Path "$BUILD_DIR\addons" -Recurse -Directory -Filter "src" -ErrorAction SilentlyContinue |
    Where-Object { $_.Parent.Name -eq "scripts" -or $_.Parent.Name -eq "styles" } |
    Remove-Item -Recurse -Force -ErrorAction SilentlyContinue

# Remove nested .git/.svn from vendor and addons
foreach ($searchDir in @("$BUILD_DIR\vendor", "$BUILD_DIR\addons")) {
    if (Test-Path $searchDir) {
        foreach ($pattern in @(".git", ".svn")) {
            Get-ChildItem -Path $searchDir -Recurse -Directory -Filter $pattern -ErrorAction SilentlyContinue |
                Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
        }
    }
}

# Remove vendor plugin nested vendor src/test dirs (wp-rets-client bundles its own lib-ui)
if (Test-Path "$BUILD_DIR\vendor\plugins") {
    Get-ChildItem -Path "$BUILD_DIR\vendor\plugins" -Recurse -Directory -Filter "src" -ErrorAction SilentlyContinue |
        Where-Object { $_.Parent.Name -eq "scripts" -or $_.Parent.Name -eq "styles" } |
        Remove-Item -Recurse -Force -ErrorAction SilentlyContinue
}

# 5. Create ZIP
Write-Host "==> Creating ZIP archive"
Compress-Archive -Path $BUILD_DIR -DestinationPath "$BUILD_ROOT\$ZIP_NAME" -Force
$zipSize = [math]::Round((Get-Item "$BUILD_ROOT\$ZIP_NAME").Length / 1MB, 2)

Write-Host ""
Write-Host "================================================"
Write-Host "  Built: $BUILD_ROOT\$ZIP_NAME ($zipSize MB)"
Write-Host "================================================"
