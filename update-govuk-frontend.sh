#!/usr/bin/env bash
set -euo pipefail

# Configuration
EXTENSION_DIR="_extensions/quarto-govuk"
GITHUB_REPO="alphagov/govuk-frontend"
TEMP_DIR=".govuk-frontend-temp"

# Allow version override via command line argument
VERSION="${1:-latest}"

echo "╔════════════════════════════════════════════════════════════╗"
echo "║        GOV.UK Frontend Update Script for Quarto            ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""

# Step 1: Fetch release metadata
echo "[1/9] Fetching release metadata from GitHub..."
if [ "$VERSION" = "latest" ]; then
    api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/latest"
    echo "      → Using latest release"
else
    api_url="https://api.github.com/repos/${GITHUB_REPO}/releases/tags/v${VERSION}"
    echo "      → Using version v${VERSION}"
fi

json=$(curl -s "$api_url")

# Extract version and download URL
release_version=$(echo "$json" | grep '"tag_name":' | head -n1 | cut -d '"' -f4 | sed 's/^v//')
download_url=$(echo "$json" | grep '"browser_download_url":' | grep '\.zip' | head -n1 | cut -d '"' -f4)

if [ -z "$download_url" ]; then
    echo "      ✗ Failed to fetch release information"
    exit 1
fi

echo "      ✓ Found version: v${release_version}"
echo "      ✓ Download URL: $download_url"

# Step 2: Create temporary directory
echo ""
echo "[2/9] Setting up temporary directory..."
rm -rf "$TEMP_DIR"
mkdir -p "$TEMP_DIR"
echo "      ✓ Created $TEMP_DIR"

# Step 3: Download release
echo ""
echo "[3/9] Downloading GOV.UK Frontend v${release_version}..."
asset_file="${TEMP_DIR}/release.zip"
curl -L -o "$asset_file" "$download_url" 2>&1 | grep -E '^\s*[0-9]|^$' || true
echo "      ✓ Downloaded $(du -h "$asset_file" | cut -f1)"

# Step 4: Extract archive
echo ""
echo "[4/9] Extracting archive..."
unzip -q "$asset_file" -d "$TEMP_DIR"
echo "      ✓ Extracted successfully"

# Step 5: Backup existing assets (optional)
echo ""
echo "[5/9] Creating backup of existing assets..."
if [ -d "$EXTENSION_DIR/assets" ] || [ -d "$EXTENSION_DIR/stylesheets" ] || [ -d "$EXTENSION_DIR/javascripts" ]; then
    # Create hidden backup directory
    backup_root=".govuk-backups"
    mkdir -p "$backup_root"
    backup_dir="$backup_root/backup-$(date +%Y%m%d-%H%M%S)"
    mkdir -p "$backup_dir"

    [ -d "$EXTENSION_DIR/assets" ] && cp -r "$EXTENSION_DIR/assets" "$backup_dir/" 2>/dev/null || true
    [ -f "$EXTENSION_DIR/stylesheets/govuk-frontend.min.css" ] && cp "$EXTENSION_DIR/stylesheets/govuk-frontend.min.css" "$backup_dir/" 2>/dev/null || true
    [ -f "$EXTENSION_DIR/javascripts/govuk-frontend.min.js" ] && cp "$EXTENSION_DIR/javascripts/govuk-frontend.min.js" "$backup_dir/" 2>/dev/null || true
    echo "      ✓ Backup created in $backup_dir"

    # Keep only the 3 most recent backups
    backup_count=$(ls -1d "$backup_root"/backup-* 2>/dev/null | wc -l | tr -d ' ')
    if [ "$backup_count" -gt 3 ]; then
        old_backups=$(ls -1td "$backup_root"/backup-* | tail -n +4)
        echo "$old_backups" | xargs rm -rf
        echo "      ✓ Cleaned up old backups (keeping 3 most recent)"
    fi
else
    echo "      → No existing assets to backup"
fi

# Step 6: Clear existing GOV.UK Frontend assets
echo ""
echo "[6/9] Removing old GOV.UK Frontend assets..."
rm -rf "$EXTENSION_DIR/assets"
mkdir -p "$EXTENSION_DIR/assets"
mkdir -p "$EXTENSION_DIR/stylesheets"
mkdir -p "$EXTENSION_DIR/javascripts"
echo "      ✓ Directories prepared"

# Step 7: Copy assets
echo ""
echo "[7/9] Installing new assets..."
if [ -d "$TEMP_DIR/assets" ]; then
    cp -r "$TEMP_DIR/assets/"* "$EXTENSION_DIR/assets/"
    echo "      ✓ Assets copied"
else
    echo "      ✗ No assets directory found in release"
    exit 1
fi

# Copy CSS (removing version from filename)
css_count=0
for f in "$TEMP_DIR"/govuk-frontend-*.min.css; do
    [ -e "$f" ] || continue
    cp "$f" "$EXTENSION_DIR/stylesheets/govuk-frontend.min.css"
    css_count=$((css_count + 1))
done
echo "      ✓ CSS file installed"

# Copy JavaScript (removing version from filename)
js_count=0
for f in "$TEMP_DIR"/govuk-frontend-*.min.js; do
    [ -e "$f" ] || continue
    cp "$f" "$EXTENSION_DIR/javascripts/govuk-frontend.min.js"
    js_count=$((js_count + 1))
done
echo "      ✓ JavaScript file installed"

# Copy source maps if available (optional)
for f in "$TEMP_DIR"/govuk-frontend-*.min.css.map; do
    [ -e "$f" ] || continue
    cp "$f" "$EXTENSION_DIR/stylesheets/govuk-frontend.min.css.map"
done
for f in "$TEMP_DIR"/govuk-frontend-*.min.js.map; do
    [ -e "$f" ] || continue
    cp "$f" "$EXTENSION_DIR/javascripts/govuk-frontend.min.js.map"
done

# Step 8: Fix asset paths and source map references
echo ""
echo "[8/9] Fixing asset paths and source map references..."

# Fix CSS file - change absolute paths to relative paths in the same directory
# Quarto copies extension files to example_files/libs/quarto-contrib/govuk-frontend/
# So assets need to be at assets/ not /assets/
# The original GOV.UK CSS uses /assets/ (absolute paths)
sed -i '' 's|/assets/|assets/|g' "$EXTENSION_DIR/stylesheets/govuk-frontend.min.css"
# Fix any malformed paths like ..assets/ that might have been created
sed -i '' 's|url(\.\.assets/|url(assets/|g' "$EXTENSION_DIR/stylesheets/govuk-frontend.min.css"
echo "      ✓ Updated asset paths in CSS (changed /assets/ to assets/)"

# Fix sourceMappingURL in CSS to point to renamed file
sed -i '' "s|sourceMappingURL=govuk-frontend-.*\.min\.css\.map|sourceMappingURL=govuk-frontend.min.css.map|g" \
    "$EXTENSION_DIR/stylesheets/govuk-frontend.min.css"
echo "      ✓ Updated CSS source map reference"

# Fix sourceMappingURL in JS to point to renamed file
sed -i '' "s|sourceMappingURL=govuk-frontend-.*\.min\.js\.map|sourceMappingURL=govuk-frontend.min.js.map|g" \
    "$EXTENSION_DIR/javascripts/govuk-frontend.min.js"
echo "      ✓ Updated JS source map reference"

# Fix the "file" field in source map files to match renamed files
if [ -f "$EXTENSION_DIR/stylesheets/govuk-frontend.min.css.map" ]; then
    sed -i '' "s|\"file\":\"govuk-frontend-.*\.min\.css\"|\"file\":\"govuk-frontend.min.css\"|g" \
        "$EXTENSION_DIR/stylesheets/govuk-frontend.min.css.map"
    echo "      ✓ Updated CSS source map file reference"
fi

if [ -f "$EXTENSION_DIR/javascripts/govuk-frontend.min.js.map" ]; then
    sed -i '' "s|\"file\":\"govuk-frontend-.*\.min\.js\"|\"file\":\"govuk-frontend.min.js\"|g" \
        "$EXTENSION_DIR/javascripts/govuk-frontend.min.js.map"
    echo "      ✓ Updated JS source map file reference"
fi

# Replace GDS Transport font with Arial (GDS Transport requires a license)
sed -i '' 's|GDS Transport,arial|arial|g' "$EXTENSION_DIR/stylesheets/govuk-frontend.min.css"
echo "      ✓ Replaced GDS Transport font with Arial"

if [ -f "$EXTENSION_DIR/stylesheets/govuk-frontend.min.css.map" ]; then
    sed -i '' 's|GDS Transport,arial|arial|g' "$EXTENSION_DIR/stylesheets/govuk-frontend.min.css.map"
    echo "      ✓ Updated font references in CSS source map"
fi

# Step 9: Update version tracking
echo ""
echo "[9/9] Updating version information..."
echo "$release_version" > "$EXTENSION_DIR/.govuk-frontend-version"
echo "      ✓ Version ${release_version} recorded in ${EXTENSION_DIR}/.govuk-frontend-version"

# Cleanup
echo ""
echo "[Cleanup] Removing temporary files..."
rm -rf "$TEMP_DIR"
echo "      ✓ Temporary files removed"

# Summary
echo ""
echo "╔════════════════════════════════════════════════════════════╗"
echo "║                   Update Complete!                         ║"
echo "╚════════════════════════════════════════════════════════════╝"
echo ""
echo "  GOV.UK Frontend: v${release_version}"
echo "  Assets:          ${EXTENSION_DIR}/assets/"
echo "  CSS:             ${EXTENSION_DIR}/stylesheets/govuk-frontend.min.css"
echo "  JavaScript:      ${EXTENSION_DIR}/javascripts/govuk-frontend.min.js"
echo ""
echo "Next steps:"
echo "  • Test your Quarto documents to ensure everything works"
echo "  • Review the changelog: https://github.com/${GITHUB_REPO}/releases/tag/v${release_version}"
echo "  • Commit the changes when ready"
echo ""
