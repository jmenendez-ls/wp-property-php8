# WP-Property — Build Guide

This document explains how to create a production-ready ZIP file for distributing a new version of the WP-Property plugin.

## Overview

WP-Property ships all CSS and JS assets pre-compiled and committed to the repository. The build process is a straightforward **copy + exclude + ZIP** operation — no Node.js, Grunt, or npm is required.

Two build scripts are provided:

| Script | Platform | Usage |
|--------|----------|-------|
| `build-zip.sh` | Linux / macOS / WSL / Git Bash | `./build-zip.sh 3.0.0` |
| `build-zip.ps1` | Windows PowerShell | `.\build-zip.ps1 -Version "3.0.0"` |

Both scripts produce identical output: a file named `build/wp-property-<version>.zip` containing a single `wp-property/` directory ready for WordPress installation.

---

## Prerequisites

| Requirement | Details |
|-------------|---------|
| **zip** (bash) or **Compress-Archive** (PowerShell) | Standard on most systems. On Ubuntu/Debian: `sudo apt install zip` |
| **Git** | For version control and tagging releases |

**Not required:** Node.js, npm, Grunt, Composer, or any JavaScript build tooling. The legacy `build.sh` / `gruntfile.js` / `makefile` / `package.json` pipeline has been retired. All PHP vendor dependencies are committed directly to the repository (see [Vendor Dependencies](#vendor-dependencies) below).

---

## Step-by-Step: Creating a New Release

### 1. Update Version Numbers

Before building, update the version string in all locations where it appears:

**`wp-property.php`** — Plugin header:
```
Version: 3.1.0
Tested up to: 6.7
Requires PHP: 8.0
```

**`readme.txt`** — WordPress readme:
```
Stable tag: 3.1.0
Tested up to: 6.7
Requires PHP: 8.0
```
Also add a new entry under the `== Changelog ==` section.

**`composer.json`** — PHP requirement (if it changes):
```json
"require": {
    "php": ">=8.0",
    ...
}
```

**Addon headers** — If any addon has its own version, update the `Version:` line in its main PHP file (e.g., `addons/wp-property-importer/wp-property-importer.php`).

### 2. Commit All Changes

Make sure your working tree is clean:

```bash
git add -A
git commit -m "Bump version to 3.1.0"
```

### 3. Run the Build Script

**On Linux / macOS / WSL / Git Bash:**

```bash
chmod +x build-zip.sh    # only needed once
./build-zip.sh 3.1.0
```

**On Windows PowerShell:**

```powershell
.\build-zip.ps1 -Version "3.1.0"
```

If you omit the version argument, both scripts default to `3.0.0`.

The script will:

1. **Clean** any previous `build/` directory
2. **Copy** all production files into `build/wp-property/` (including the committed `vendor/` directory)
3. **Strip** development artifacts (LESS sources, JS sources, test directories, editor snippets, cache directories, VCS metadata)
4. **Create** `build/wp-property-<version>.zip`

When complete, you'll see output like:

```
================================================
  Built: build/wp-property-3.1.0.zip (8.42 MB)
================================================
```

### 4. Verify the ZIP

Before distributing, test the ZIP on a clean WordPress installation:

1. Log in to a WordPress 6.0+ site running PHP 8.0+
2. Go to **Plugins > Add New > Upload Plugin**
3. Upload `build/wp-property-<version>.zip`
4. Activate the plugin
5. Verify:
   - No PHP errors in the debug log (`wp-content/debug.log`)
   - The Settings page loads correctly (**Properties > Settings**)
   - A property can be created and viewed on the frontend

### 5. Tag the Release

After verification:

```bash
git tag -a v3.1.0 -m "Release v3.1.0"
git push origin v3.1.0
```

### 6. Distribute

Attach `build/wp-property-<version>.zip` to a GitHub Release, or distribute through your preferred channel (private update server, direct download, etc.).

---

## What's Included in the ZIP

The production ZIP contains only the files needed to run the plugin:

```
wp-property/
├── wp-property.php           # Plugin entry point
├── composer.json             # Runtime config (read by PHP for version, features, schemas)
├── readme.txt                # WordPress plugin readme (required by WP + UD lib-utility)
├── readme.md                 # GitHub readme (used by lib-ud-api-client for path resolution)
├── addons/                   # All 11 bundled addons
│   ├── wp-property-agents/
│   ├── wp-property-facebook-tabs/
│   ├── wp-property-feps/
│   ├── wp-property-importer/
│   ├── wp-property-pdf/
│   ├── wp-property-power-tools/
│   ├── wp-property-responsive-slideshow/
│   ├── wp-property-slideshow/
│   ├── wp-property-supermap/
│   ├── wp-property-terms/
│   └── wp-property-walkscore/
├── bin/                      # WP-CLI commands
├── lib/                      # Core PHP classes, features, shortcodes, widgets, third-party libs
├── static/
│   ├── views/                # PHP templates (admin + frontend)
│   ├── scripts/              # Compiled JavaScript
│   ├── styles/               # Compiled CSS
│   ├── config/               # standard_attributes.json
│   ├── languages/            # .po/.mo translation files
│   └── splashes/             # Splash screen assets
└── vendor/
    ├── libraries/
    │   ├── autoload.php      # Composer autoloader
    │   ├── composer/         # Composer autoload internals
    │   ├── usabilitydynamics/ # UD libraries (lib-ui, lib-utility, lib-settings, etc.)
    │   └── ccampbell/        # ChromePHP
    └── plugins/              # Bundled vendor plugins (ElasticPress, wp-rets-client, wp-tax-post-binding)
```

## What's Excluded from the ZIP

The build scripts automatically strip these from the build copy:

| Excluded path | Reason |
|---------------|--------|
| `.git/`, `.github/`, `.gitignore` | Version control metadata |
| `build-zip.sh`, `build-zip.ps1` | Build scripts themselves |
| `BUILD_GUIDE.md` | This documentation file |
| `v3.0_changelog.md`, `changes.md` | Internal development notes |
| `composer.lock` | Lock file (not needed for plugin distribution) |
| `static/cache/`, `static/codex/` | Runtime cache / documentation cache |
| `static/readme.html` | Legacy Grunt-generated HTML (not referenced by any PHP code) |
| `static/styles/src/` | LESS source files (compiled CSS is in `static/styles/`) |
| `static/scripts/src/` | JS source files (compiled JS is in `static/scripts/`) |
| `addons/*/static/scripts/src/` | Addon JS source files |
| `addons/*/static/styles/src/` | Addon LESS/CSS source files |
| `vendor/composer/installers/` | Composer installer plugin (build-time only) |
| `vendor/libraries/*/test/` | Library test suites |
| `vendor/libraries/*/static/scripts/src/` | Library JS source files |
| `vendor/libraries/*/static/styles/src/` | Library LESS source files |
| `vendor/libraries/*/static/scripts/editor/` | Ace editor snippets (lib-ui) |
| `vendor/libraries/*/static/test/` | Library test directories |
| `vendor/libraries/*/static/examples/` | Library examples |
| `vendor/libraries/*/scripts/src/` | Library JS source files (lib-utility) |
| `**/vendor/**/.git/`, `**/.svn/` | Nested VCS directories |

---

## Vendor Dependencies

All PHP dependencies are **committed directly** to the repository under `vendor/libraries/` and `vendor/plugins/`. The build scripts copy this directory as-is — no `composer install` step is needed or performed.

This is necessary because the original packages were hosted on a private Composer repository (`repository.usabilitydynamics.com`) that is no longer available. The 9 UsabilityDynamics libraries, ChromePHP, and the 3 bundled plugins are not published on Packagist. The committed `vendor/` directory is the source of truth.

The `composer.json` file is **not modified** — it is still read at runtime by several PHP classes (lib-ud-api-client, lib-wp-bootstrap) that parse its `extra.featureFlags`, `extra.schemas`, and `require` sections for plugin configuration.

### Regenerating the Autoloader

If you add or remove PHP class files in `lib/classes/`, the Composer autoloader classmap needs to be regenerated. This command does **not** contact any remote repository:

```bash
composer dump-autoload --optimize
```

This updates `vendor/libraries/composer/autoload_classmap.php` to include the new classes. Commit the result.

---

## Troubleshooting

### `zip` command not found (Linux)

```bash
sudo apt install zip    # Debian/Ubuntu
sudo yum install zip    # RHEL/CentOS
brew install zip        # macOS (usually pre-installed)
```

### PowerShell execution policy blocks the script

```powershell
Set-ExecutionPolicy -Scope CurrentUser -ExecutionPolicy RemoteSigned
```

Or run with bypass:

```powershell
powershell -ExecutionPolicy Bypass -File .\build-zip.ps1 -Version "3.1.0"
```

### The ZIP is too large

Typical production ZIP size is 8-12 MB. If it's significantly larger, check that:

- `node_modules/` doesn't exist in the repo root (should be in `.gitignore`)
- `static/cache/` and `static/codex/` were properly stripped
- No stale `build/` directories from previous runs leaked in

---

## Modifying CSS or JS Assets in the Future

All compiled CSS and JS assets are committed directly to the repository. If you need to edit LESS or JS source files in the future, **do not** reinstall the legacy Grunt pipeline.

Instead, use standalone tools on a per-file basis:

**LESS compilation:**
```bash
npx lessc static/styles/src/wpp.admin.less static/styles/wpp.admin.css --clean-css
```

**JS minification (if desired):**
```bash
npx terser static/scripts/wpp.global.js -o static/scripts/wpp.global.min.js
```

Commit the compiled output after running these commands. The build script does not compile assets — it only packages what's already committed.

---

## Build Script Internals

Both `build-zip.sh` and `build-zip.ps1` follow the same logic:

```
1. rm -rf build/
2. cp production files → build/wp-property/
3. rm -rf dev artifacts from build/wp-property/
4. zip build/wp-property/ → build/wp-property-<version>.zip
```

The scripts are intentionally simple — no configuration files, no environment variables, no external services. They can be run locally or in any CI environment that has `zip` installed.

### Adapting for CI (GitHub Actions example)

```yaml
name: Build Release ZIP
on:
  push:
    tags: ['v*']

jobs:
  build:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4

      - name: Build ZIP
        run: |
          chmod +x build-zip.sh
          ./build-zip.sh ${GITHUB_REF_NAME#v}

      - name: Upload release asset
        uses: softprops/action-gh-release@v2
        with:
          files: build/wp-property-*.zip
```

This workflow triggers on version tags (e.g., `v3.1.0`), builds the ZIP, and attaches it to the GitHub Release automatically. No PHP or Composer setup is needed since all vendor dependencies are committed.
