#!/usr/bin/env bash
set -e

cd "$(dirname "$0")/.."

APP_CONFIG_FILE="lib/config/app_config.dart"
GRADLE_FILE="android/gradle.properties"
PUBSPEC_FILE="pubspec.yaml"
DESKTOP_FILE="linux/eccal.desktop"
SOURCE_ICON="assets/icon/app_icon.png"
DEST_ICON="linux/eccal.png"
RELEASE_YML=".github/workflows/release.yml"

# Function to compare versions (returns 0 if v1 >= v2, 1 otherwise)
version_compare() {
  local v1=$1
  local v2=$2

  # Remove non-numeric parts for comparison
  v1_num=$(echo "$v1" | sed 's/[^0-9.]//g')
  v2_num=$(echo "$v2" | sed 's/[^0-9.]//g')

  # Use sort -V for version comparison
  if [ "$v1_num" = "$v2_num" ]; then
    return 0  # Equal
  fi

  highest=$(printf "%s\n%s" "$v1_num" "$v2_num" | sort -V | tail -n1)

  if [ "$highest" = "$v1_num" ]; then
    return 0  # v1 >= v2
  else
    return 1  # v1 < v2
  fi
}

# =====================================
# READ CURRENT VERSIONS FROM FILES
# =====================================
echo "Reading current versions from files..."

# Get version from app_config.dart (SOURCE OF TRUTH)
CONFIG_VERSION=$(grep "static const String appVersion" "$APP_CONFIG_FILE" | sed "s/.*appVersion[[:space:]]*=[[:space:]]*'//" | sed "s/'.*//")

# Get version from pubspec.yaml
PUBSPEC_VERSION=$(grep "^version:" "$PUBSPEC_FILE" | sed 's/version:[[:space:]]*//' | sed 's/[[:space:]]*#.*//' | tr -d ' ')

# Get version from gradle.properties
GRADLE_VERSION=$(grep "^flutter.versionName=" "$GRADLE_FILE" | cut -d'=' -f2)

# Get version from desktop file (if exists)
if [[ -f "$DESKTOP_FILE" ]]; then
  DESKTOP_VERSION=$(grep "^Version=" "$DESKTOP_FILE" | cut -d'=' -f2)
else
  DESKTOP_VERSION="(file not found)"
fi

# =====================================
# CHECK VERSION CONSISTENCY
# =====================================
VERSIONS_CONSISTENT=true

if [[ "$CONFIG_VERSION" != "$PUBSPEC_VERSION" ]] || \
   [[ "$CONFIG_VERSION" != "$GRADLE_VERSION" ]] || \
   [[ -f "$DESKTOP_FILE" && "$CONFIG_VERSION" != "$DESKTOP_VERSION" ]]; then
  VERSIONS_CONSISTENT=false
fi

# =====================================
# SET DEFAULT VERSION
# =====================================
APP_VERSION="$CONFIG_VERSION"

echo "--------------------------------------------"
echo "Current versions in files:"
echo "  • $APP_CONFIG_FILE: $CONFIG_VERSION (SOURCE OF TRUTH)"
echo "  • $PUBSPEC_FILE: $PUBSPEC_VERSION"
echo "  • $GRADLE_FILE: $GRADLE_VERSION"
echo "  • $DESKTOP_FILE: $DESKTOP_VERSION"

if [[ "$VERSIONS_CONSISTENT" == false ]]; then
  echo
  echo "WARNING: Version inconsistency detected!!!"
  echo "--------------------------------------------"
fi

echo
echo "Default version for update: $APP_VERSION"
echo "--------------------------------------------"
echo

# =====================================
# FIRST PROMPT
# =====================================
if [[ "$VERSIONS_CONSISTENT" == false ]]; then
  # If inconsistent, force "no" path
  echo "Versions are inconsistent. Proceeding to version input..."
  VERSION_CORRECT="n"
else
  # If consistent, ask user
  read -rp "Is version $APP_VERSION correct? (Y/n): " VERSION_CORRECT
fi

case "$VERSION_CORRECT" in
  [yY]|[yY][eE][sS]|"")
    # User says version is correct AND versions are consistent
    if [[ "$VERSIONS_CONSISTENT" == false ]]; then
      echo "ERROR: This should not happen - versions inconsistent but user said yes"
      exit 1
    fi
    echo
    echo "Version is correct. No changes needed."
    echo "Exiting..."
    exit 0
    ;;
  *)
    # User says no or versions are inconsistent - proceed to ask for new version
    ;;
esac

# =====================================
# SECOND PROMPT - GET NEW VERSION
# =====================================
echo
echo "Supported formats:"
echo "  • X.Y.Z (e.g., 1.0.0) - stable release"
echo "  • X.Y.Z-alpha (e.g., 1.0.0-alpha)"
echo "  • X.Y.Z-beta (e.g., 1.0.0-beta)"
echo "  • X.Y.Z-rc1 (e.g., 1.0.0-rc1, 1.0.0-rc2, etc.)"
echo
read -rp "What should the version number be? [$APP_VERSION]: " NEW_VERSION

# Use current version as default if user just presses enter
if [[ -z "$NEW_VERSION" ]]; then
  NEW_VERSION="$APP_VERSION"
fi

# Validate version format (X.Y.Z with optional -alpha, -beta, or -rcN)
if [[ ! "$NEW_VERSION" =~ ^[0-9]+\.[0-9]+\.[0-9]+(-alpha|-beta|-rc[0-9]+)?$ ]]; then
  echo
  echo "ERROR: Invalid version format."
  echo "Expected: X.Y.Z, X.Y.Z-alpha, X.Y.Z-beta, or X.Y.Z-rc1"
  echo "Examples: 1.0.0, 1.0.0-alpha, 1.0.0-beta, 1.0.0-rc1"
  echo "Exiting..."
  exit 1
fi

APP_VERSION="$NEW_VERSION"

# Check if this is a pre-release
IS_PRERELEASE=false
if [[ "$APP_VERSION" =~ -alpha|-beta|-rc[0-9]+ ]]; then
  IS_PRERELEASE=true
  echo
  echo "ℹ️  This will be marked as a PRE-RELEASE on GitHub"
fi

echo
echo "New version will be: $APP_VERSION"

# =====================================
# THIRD PROMPT - CONFIRM CHANGES
# =====================================
echo
read -rp "Do you want to continue and update all files to version $APP_VERSION? (y/N): " CONFIRM_UPDATE

case "$CONFIRM_UPDATE" in
  [yY]|[yY][eE][sS])
    echo "Continuing with version $APP_VERSION..."
    ;;
  *)
    echo
    echo "Update cancelled."
    echo "Exiting..."
    exit 1
    ;;
esac

# =====================================
# CHECK DEPENDENCY VERSIONS
# =====================================
echo
echo "Checking dependency versions..."

# Declare associative arrays for dependency overrides
declare -A dep_overrides
declare -A dev_dep_overrides

# Extract dependencies from app_config.dart
while IFS='=' read -r package config_version; do
  [[ -z "$package" ]] && continue

  # Get version from pubspec.yaml
  pubspec_version=$(grep "^[[:space:]]*$package:" "$PUBSPEC_FILE" | sed 's/.*:[[:space:]]*//' | sed 's/\^//' | tr -d ' ')

  if [[ -n "$pubspec_version" ]] && [[ "$pubspec_version" != "$config_version" ]]; then
    # Check if pubspec version >= config version
    if version_compare "$pubspec_version" "$config_version"; then
      echo
      echo "    Dependency version difference detected:"
      echo "    Package: $package"
      echo "    app_config.dart: $config_version"
      echo "    pubspec.yaml:    $pubspec_version"
      echo
      read -rp "    Use which version? (1=app_config [$config_version], 2=pubspec [$pubspec_version]) [1]: " choice

      case "$choice" in
        2)
          dep_overrides[$package]=$pubspec_version
          echo "    → Will use pubspec version: $pubspec_version"
          ;;
        *)
          echo "    → Will use app_config version: $config_version"
          ;;
      esac
    fi
  fi
done < <(awk '
  /static const Map<String, String> dependencies = \{/,/\};/ {
    if (match($0, /'\''([^'\'']+)'\'': '\''([^'\'']+)'\''/, arr)) {
      print arr[1] "=" arr[2]
    }
  }
' "$APP_CONFIG_FILE")

# Extract devDependencies from app_config.dart
while IFS='=' read -r package config_version; do
  [[ -z "$package" ]] && continue

  # Get version from pubspec.yaml
  pubspec_version=$(grep "^[[:space:]]*$package:" "$PUBSPEC_FILE" | sed 's/.*:[[:space:]]*//' | sed 's/\^//' | tr -d ' ')

  if [[ -n "$pubspec_version" ]] && [[ "$pubspec_version" != "$config_version" ]]; then
    # Check if pubspec version >= config version
    if version_compare "$pubspec_version" "$config_version"; then
      echo
      echo "    DevDependency version difference detected:"
      echo "    Package: $package"
      echo "    app_config.dart: $config_version"
      echo "    pubspec.yaml:    $pubspec_version"
      echo
      read -rp "    Use which version? (1=app_config [$config_version], 2=pubspec [$pubspec_version]) [1]: " choice

      case "$choice" in
        2)
          dev_dep_overrides[$package]=$pubspec_version
          echo "    → Will use pubspec version: $pubspec_version"
          ;;
        *)
          echo "    → Will use app_config version: $config_version"
          ;;
      esac
    fi
  fi
done < <(awk '
  /static const Map<String, String> devDependencies = \{/,/\};/ {
    if (match($0, /'\''([^'\'']+)'\'': '\''([^'\'']+)'\''/, arr)) {
      print arr[1] "=" arr[2]
    }
  }
' "$APP_CONFIG_FILE")

# -------------------------------------
# Check and copy icon if needed
# -------------------------------------
echo
echo "Checking Linux icon..."

if [[ ! -f "$SOURCE_ICON" ]]; then
  echo "ERROR: Source icon not found: $SOURCE_ICON"
  exit 1
fi

ICON_NEEDS_UPDATE=false

if [[ ! -f "$DEST_ICON" ]]; then
  echo "Icon does not exist at $DEST_ICON, will copy..."
  ICON_NEEDS_UPDATE=true
else
  # Both files exist, compare MD5 checksums
  if command -v md5sum &> /dev/null; then
    SOURCE_MD5=$(md5sum "$SOURCE_ICON" | cut -d' ' -f1)
    DEST_MD5=$(md5sum "$DEST_ICON" | cut -d' ' -f1)
  elif command -v md5 &> /dev/null; then
    # macOS uses 'md5' instead of 'md5sum'
    SOURCE_MD5=$(md5 -q "$SOURCE_ICON")
    DEST_MD5=$(md5 -q "$DEST_ICON")
  else
    echo "WARNING: Neither md5sum nor md5 command found, will update icon anyway"
    ICON_NEEDS_UPDATE=true
  fi

  if [[ "$SOURCE_MD5" != "$DEST_MD5" ]]; then
    echo "Icon checksums differ, will update..."
    echo "  Source MD5: $SOURCE_MD5"
    echo "  Dest MD5:   $DEST_MD5"
    ICON_NEEDS_UPDATE=true
  else
    echo "Icon is up to date (MD5: $SOURCE_MD5)"
  fi
fi

if [[ "$ICON_NEEDS_UPDATE" == true ]]; then
  echo "Copying $SOURCE_ICON to $DEST_ICON..."
  cp "$SOURCE_ICON" "$DEST_ICON"
  echo "Icon copied successfully"
fi

# -------------------------------------
# Read current versionCode and ask about incrementing
# -------------------------------------
CURRENT_CODE=$(grep "^flutter.versionCode=" "$GRADLE_FILE" | cut -d'=' -f2)
if [[ -z "$CURRENT_CODE" ]]; then
  echo "ERROR: Could not find flutter.versionCode in $GRADLE_FILE"
  exit 1
fi

echo
echo "--------------------------------------------"
echo "Current Android versionCode: $CURRENT_CODE"
echo
echo "ℹ️  versionCode is used by Google Play to identify app versions."
echo "   It should be incremented for each new release."
echo "   Only skip this for testing purposes."
echo "--------------------------------------------"
echo
read -rp "Increment versionCode to $((CURRENT_CODE + 1))? (Y/n): " INCREMENT_CODE

case "$INCREMENT_CODE" in
  [nN]|[nN][oO])
    NEW_CODE=$CURRENT_CODE
    echo "Keeping versionCode at $CURRENT_CODE (testing only)"
    ;;
  *)
    # Default yes
    NEW_CODE=$((CURRENT_CODE + 1))
    echo "Incrementing versionCode to $NEW_CODE"
    ;;
esac

# -------------------------------------
# Apply changes
# -------------------------------------

echo
echo "Updating app_config.dart (SOURCE OF TRUTH)..."
sed -i.bak "s/^\([[:space:]]*static const String appVersion[[:space:]]*=[[:space:]]*'\)[^']*\('.*\)$/\1$APP_VERSION\2/" "$APP_CONFIG_FILE"

# Update app_config.dart with dependency overrides
for package in "${!dep_overrides[@]}"; do
  version="${dep_overrides[$package]}"
  sed -i.bak "s/\('$package':[[:space:]]*'\)[^']*\('/\1$version\2/" "$APP_CONFIG_FILE"
  echo "  Updated $package to $version in app_config.dart"
done

for package in "${!dev_dep_overrides[@]}"; do
  version="${dev_dep_overrides[$package]}"
  sed -i.bak "s/\('$package':[[:space:]]*'\)[^']*\('/\1$version\2/" "$APP_CONFIG_FILE"
  echo "  Updated $package to $version in app_config.dart"
done

echo "Updating pubspec.yaml..."
sed -i.bak "s/^\(version:[[:space:]]*\)[0-9]\+\(\.[0-9]\+\)*\(-alpha\|-beta\|-rc[0-9]\+\)\?.*$/\1$APP_VERSION/" "$PUBSPEC_FILE"

echo "Syncing dependencies from app_config.dart to pubspec.yaml..."

# Extract dependencies map from app_config.dart and update pubspec.yaml
awk '
  /static const Map<String, String> dependencies = \{/,/\};/ {
    if (match($0, /'\''([^'\'']+)'\'': '\''([^'\'']+)'\''/, arr)) {
      package = arr[1]
      version = arr[2]
      print package "=" version
    }
  }
' "$APP_CONFIG_FILE" | while IFS='=' read -r package version; do
  # Update dependency in pubspec.yaml (no ^ caret for exact versions)
  sed -i.bak "s/^\([[:space:]]*$package:[[:space:]]*\).*/\1$version/" "$PUBSPEC_FILE"
  echo "  ✓ $package: $version"
done

# Extract devDependencies map from app_config.dart
echo "Syncing devDependencies from app_config.dart to pubspec.yaml..."
awk '
  /static const Map<String, String> devDependencies = \{/,/\};/ {
    if (match($0, /'\''([^'\'']+)'\'': '\''([^'\'']+)'\''/, arr)) {
      package = arr[1]
      version = arr[2]
      print package "=" version
    }
  }
' "$APP_CONFIG_FILE" | while IFS='=' read -r package version; do
  # Update devDependency in pubspec.yaml (no ^ caret for exact versions)
  sed -i.bak "s/^\([[:space:]]*$package:[[:space:]]*\).*/\1$version/" "$PUBSPEC_FILE"
  echo "  ✓ $package: $version"
done

echo "Updating android/gradle.properties..."
sed -i.bak "s/^flutter.versionName=.*/flutter.versionName=$APP_VERSION/" "$GRADLE_FILE"
sed -i.bak "s/^flutter.versionCode=.*/flutter.versionCode=$NEW_CODE/" "$GRADLE_FILE"

echo "Updating linux/eccal.desktop..."
# Create desktop file if it doesn't exist
if [[ ! -f "$DESKTOP_FILE" ]]; then
  echo "Creating $DESKTOP_FILE..."
  cat > "$DESKTOP_FILE" << 'EOF'
[Desktop Entry]
Version=0.0.0
Type=Application
Name=EcCal
Comment=A cross-platform diary app with CalDAV integration
Exec=eccal
Icon=eccal
Terminal=false
Categories=Office;Calendar;Utility;
Keywords=diary;journal;calendar;caldav;notes;
StartupNotify=true
EOF
fi

# Update version in desktop file
sed -i.bak "s/^Version=.*/Version=$APP_VERSION/" "$DESKTOP_FILE"

# Update Flutter version in GitHub Actions
echo
echo "Updating Flutter version in GitHub Actions workflow..."

# Get Flutter version from app_config.dart
FLUTTER_VERSION=$(grep "static const String flutterVersion" "$APP_CONFIG_FILE" | sed "s/.*flutterVersion[[:space:]]*=[[:space:]]*'//" | sed "s/'.*//")

if [[ -z "$FLUTTER_VERSION" ]]; then
  echo "WARNING: Could not find flutterVersion in $APP_CONFIG_FILE"
  echo "Skipping GitHub Actions workflow update"
else
  echo "Flutter version from app_config.dart: $FLUTTER_VERSION"

  if [[ -f "$RELEASE_YML" ]]; then
    # Update the FLUTTER_VERSION env variable in release.yml
    sed -i.bak "s/^\([[:space:]]*FLUTTER_VERSION:[[:space:]]*'\)[^']*\('/\1$FLUTTER_VERSION\2/" "$RELEASE_YML"
    echo "  ✓ Updated $RELEASE_YML with Flutter $FLUTTER_VERSION"
  else
    echo "WARNING: $RELEASE_YML not found, skipping..."
  fi
fi

# -------------------------------------
# Summary
# -------------------------------------
echo
echo "--------------------------------------------"
echo "Version update complete!"
echo "--------------------------------------------"
echo "New VersionName:     $APP_VERSION"
if [[ "$IS_PRERELEASE" == true ]]; then
  echo "Release Type:        PRE-RELEASE"
fi
echo "Old VersionCode:     $CURRENT_CODE"
echo "New VersionCode:     $NEW_CODE"
if [[ "$NEW_CODE" == "$CURRENT_CODE" ]]; then
  echo "                     (unchanged - testing only!)"
fi
if [[ -n "$FLUTTER_VERSION" ]]; then
  echo "Flutter Version:     $FLUTTER_VERSION"
fi
echo
echo "Updated files:"
echo "  • $APP_CONFIG_FILE (SOURCE OF TRUTH)"
echo "  • $PUBSPEC_FILE (version + dependencies synced)"
echo "  • $GRADLE_FILE"
echo "  • $DESKTOP_FILE"
if [[ -n "$FLUTTER_VERSION" && -f "$RELEASE_YML" ]]; then
  echo "  • $RELEASE_YML (Flutter version)"
fi
if [[ "$ICON_NEEDS_UPDATE" == true ]]; then
  echo "  • $DEST_ICON (copied)"
else
  echo "  • $DEST_ICON (already up to date)"
fi
echo "--------------------------------------------"
echo

read -n 1 -s -r -p "Press any key to exit..."
echo
