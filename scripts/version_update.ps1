# =====================================
# Version Update Script for Windows
# =====================================

# Set error action preference
$ErrorActionPreference = "Stop"

# Navigate to project root (script is in scripts/ folder)
$scriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location (Join-Path $scriptDir "..")

# File paths
$GRADLE_FILE = "android/gradle.properties"
$APP_CONFIG_FILE = "lib/config/app_config.dart"
$PUBSPEC_FILE = "pubspec.yaml"
$DESKTOP_FILE = "linux/eccal.desktop"
$SOURCE_ICON = "assets/icon/app_icon.png"
$DEST_ICON = "linux/eccal.png"
$RELEASE_YML = ".github\workflows\release.yml"

# Function to compare versions (returns $true if v1 >= v2)
function Compare-Versions {
    param(
        [string]$v1,
        [string]$v2
    )

    # Remove non-numeric parts (^, spaces, etc.)
    $v1Clean = $v1 -replace '[^\d.]', ''
    $v2Clean = $v2 -replace '[^\d.]', ''

    # Split into parts
    $v1Parts = $v1Clean.Split('.') | ForEach-Object { [int]$_ }
    $v2Parts = $v2Clean.Split('.') | ForEach-Object { [int]$_ }

    # Pad arrays to same length
    $maxLength = [Math]::Max($v1Parts.Length, $v2Parts.Length)
    while ($v1Parts.Length -lt $maxLength) { $v1Parts += 0 }
    while ($v2Parts.Length -lt $maxLength) { $v2Parts += 0 }

    # Compare each part
    for ($i = 0; $i -lt $maxLength; $i++) {
        if ($v1Parts[$i] -gt $v2Parts[$i]) {
            return $true  # v1 > v2
        } elseif ($v1Parts[$i] -lt $v2Parts[$i]) {
            return $false  # v1 < v2
        }
    }

    return $true  # Equal, so v1 >= v2
}

# =====================================
# READ CURRENT VERSIONS FROM FILES
# =====================================
Write-Host "Reading current versions from files..." -ForegroundColor Cyan

# Get version from app_config.dart (SOURCE OF TRUTH)
$configContent = Get-Content $APP_CONFIG_FILE
$CONFIG_VERSION = ($configContent | Select-String "static const String appVersion").ToString() -replace ".*appVersion\s*=\s*'", "" -replace "'.*", ""

# Get version from pubspec.yaml
$pubspecContent = Get-Content $PUBSPEC_FILE
$PUBSPEC_VERSION = ($pubspecContent | Select-String "^version:").ToString() -replace "version:\s*", "" -replace "\s*#.*", "" -replace "\s", ""

# Get version from gradle.properties
$gradleContent = Get-Content $GRADLE_FILE
$GRADLE_VERSION = ($gradleContent | Select-String "^flutter.versionName=").ToString() -replace "flutter.versionName=", ""

# Get version from desktop file (if exists)
if (Test-Path $DESKTOP_FILE) {
    $desktopContent = Get-Content $DESKTOP_FILE
    $DESKTOP_VERSION = ($desktopContent | Select-String "^Version=").ToString() -replace "Version=", ""
} else {
    $DESKTOP_VERSION = "(file not found)"
}

# =====================================
# CHECK VERSION CONSISTENCY
# =====================================
$VERSIONS_CONSISTENT = $true

if (($CONFIG_VERSION -ne $PUBSPEC_VERSION) -or
    ($CONFIG_VERSION -ne $GRADLE_VERSION) -or
    ((Test-Path $DESKTOP_FILE) -and ($CONFIG_VERSION -ne $DESKTOP_VERSION))) {
    $VERSIONS_CONSISTENT = $false
}

# =====================================
# DISPLAY CURRENT VERSIONS
# =====================================
$APP_VERSION = $CONFIG_VERSION

Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host "Current versions in files:" -ForegroundColor Yellow
Write-Host "  • $APP_CONFIG_FILE : $CONFIG_VERSION (SOURCE OF TRUTH)" -ForegroundColor Green
Write-Host "  • $PUBSPEC_FILE : $PUBSPEC_VERSION"
Write-Host "  • $GRADLE_FILE : $GRADLE_VERSION"
Write-Host "  • $DESKTOP_FILE : $DESKTOP_VERSION"

if (-not $VERSIONS_CONSISTENT) {
    Write-Host ""
    Write-Host "  WARNING: Version inconsistency detected!" -ForegroundColor Red
    Write-Host "--------------------------------------------" -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Default version for update: $APP_VERSION" -ForegroundColor Green
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host ""

# =====================================
# FIRST PROMPT
# =====================================
if (-not $VERSIONS_CONSISTENT) {
    Write-Host "Versions are inconsistent. Proceeding to version input..." -ForegroundColor Yellow
    $VERSION_CORRECT = "n"
} else {
    $response = Read-Host "Is version $APP_VERSION correct? (Y/n)"
    $VERSION_CORRECT = if ([string]::IsNullOrWhiteSpace($response)) { "y" } else { $response }
}

if ($VERSION_CORRECT -match "^[yY]") {
    if (-not $VERSIONS_CONSISTENT) {
        Write-Host "ERROR: This should not happen - versions inconsistent but user said yes" -ForegroundColor Red
        Read-Host "Press Enter to exit"
        exit 1
    }
    Write-Host ""
    Write-Host "Version is correct. No changes needed." -ForegroundColor Green
    Write-Host "Exiting..." -ForegroundColor Green
    Read-Host "Press Enter to exit"
    exit 0
}

# =====================================
# SECOND PROMPT - GET NEW VERSION
# =====================================
Write-Host ""
Write-Host "Supported formats:" -ForegroundColor Cyan
Write-Host "  • X.Y.Z (e.g., 1.0.0) - stable release"
Write-Host "  • X.Y.Z-alpha (e.g., 1.0.0-alpha)"
Write-Host "  • X.Y.Z-beta (e.g., 1.0.0-beta)"
Write-Host "  • X.Y.Z-rc1 (e.g., 1.0.0-rc1, 1.0.0-rc2, etc.)"
Write-Host ""

$response = Read-Host "What should the version number be? [$APP_VERSION]"
$NEW_VERSION = if ([string]::IsNullOrWhiteSpace($response)) { $APP_VERSION } else { $response }

# Validate version format
if ($NEW_VERSION -notmatch "^[0-9]+\.[0-9]+\.[0-9]+(-alpha|-beta|-rc[0-9]+)?$") {
    Write-Host ""
    Write-Host "ERROR: Invalid version format." -ForegroundColor Red
    Write-Host "Expected: X.Y.Z, X.Y.Z-alpha, X.Y.Z-beta, or X.Y.Z-rc1" -ForegroundColor Red
    Write-Host "Examples: 1.0.0, 1.0.0-alpha, 1.0.0-beta, 1.0.0-rc1" -ForegroundColor Red
    Write-Host "Exiting..." -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$APP_VERSION = $NEW_VERSION

# Check if this is a pre-release
$IS_PRERELEASE = $false
if ($APP_VERSION -match "-alpha|-beta|-rc[0-9]+") {
    $IS_PRERELEASE = $true
    Write-Host ""
    Write-Host "ℹ️  This will be marked as a PRE-RELEASE on GitHub" -ForegroundColor Cyan
}

Write-Host ""
Write-Host "New version will be: $APP_VERSION" -ForegroundColor Green

# =====================================
# THIRD PROMPT - CONFIRM CHANGES
# =====================================
Write-Host ""
$response = Read-Host "Do you want to continue and update all files to version $APP_VERSION? (y/N)"

if ($response -notmatch "^[yY]") {
    Write-Host ""
    Write-Host "Update cancelled." -ForegroundColor Yellow
    Write-Host "Exiting..." -ForegroundColor Yellow
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host "Continuing with version $APP_VERSION..." -ForegroundColor Green

# =====================================
# CHECK DEPENDENCY VERSIONS
# =====================================
Write-Host ""
Write-Host "Checking dependency versions..." -ForegroundColor Cyan

# Read app_config.dart content
$configFileContent = Get-Content $APP_CONFIG_FILE -Raw

# Hash tables to store version overrides
$depOverrides = @{}
$devDepOverrides = @{}

# Extract and check dependencies
if ($configFileContent -match "static const Map<String, String> dependencies = \{([^}]+)\}") {
    $depsBlock = $matches[1]
    $depsBlock -split "`n" | ForEach-Object {
        if ($_ -match "'([^']+)':\s*'([^']+)'") {
            $package = $matches[1]
            $configVersion = $matches[2]

            # Get version from pubspec.yaml
            $pubspecLine = $pubspecContent | Select-String "^\s+$package\s*:"
            if ($pubspecLine) {
                $pubspecVersion = $pubspecLine.ToString() -replace ".*:\s*", "" -replace "\^", "" -replace "\s", ""

                if ($pubspecVersion -and ($pubspecVersion -ne $configVersion)) {
                    # Check if pubspec version >= config version
                    if (Compare-Versions $pubspecVersion $configVersion) {
                        Write-Host ""
                        Write-Host "    Dependency version difference detected:" -ForegroundColor Yellow
                        Write-Host "    Package: $package" -ForegroundColor White
                        Write-Host "    app_config.dart: $configVersion" -ForegroundColor White
                        Write-Host "    pubspec.yaml:    $pubspecVersion" -ForegroundColor White
                        Write-Host ""

                        $choice = Read-Host "    Use which version? (1=app_config [$configVersion], 2=pubspec [$pubspecVersion]) [1]"

                        if ($choice -eq "2") {
                            $depOverrides[$package] = $pubspecVersion
                            Write-Host "    → Will use pubspec version: $pubspecVersion" -ForegroundColor Green
                        } else {
                            Write-Host "    → Will use app_config version: $configVersion" -ForegroundColor Green
                        }
                    }
                }
            }
        }
    }
}

# Extract and check devDependencies
if ($configFileContent -match "static const Map<String, String> devDependencies = \{([^}]+)\}") {
    $devDepsBlock = $matches[1]
    $devDepsBlock -split "`n" | ForEach-Object {
        if ($_ -match "'([^']+)':\s*'([^']+)'") {
            $package = $matches[1]
            $configVersion = $matches[2]

            # Get version from pubspec.yaml
            $pubspecLine = $pubspecContent | Select-String "^\s+$package\s*:"
            if ($pubspecLine) {
                $pubspecVersion = $pubspecLine.ToString() -replace ".*:\s*", "" -replace "\^", "" -replace "\s", ""

                if ($pubspecVersion -and ($pubspecVersion -ne $configVersion)) {
                    # Check if pubspec version >= config version
                    if (Compare-Versions $pubspecVersion $configVersion) {
                        Write-Host ""
                        Write-Host "    DevDependency version difference detected:" -ForegroundColor Yellow
                        Write-Host "    Package: $package" -ForegroundColor White
                        Write-Host "    app_config.dart: $configVersion" -ForegroundColor White
                        Write-Host "    pubspec.yaml:    $pubspecVersion" -ForegroundColor White
                        Write-Host ""

                        $choice = Read-Host "    Use which version? (1=app_config [$configVersion], 2=pubspec [$pubspecVersion]) [1]"

                        if ($choice -eq "2") {
                            $devDepOverrides[$package] = $pubspecVersion
                            Write-Host "    → Will use pubspec version: $pubspecVersion" -ForegroundColor Green
                        } else {
                            Write-Host "    → Will use app_config version: $configVersion" -ForegroundColor Green
                        }
                    }
                }
            }
        }
    }
}

# -------------------------------------
# Check and copy icon if needed
# -------------------------------------
Write-Host ""
Write-Host "Checking Linux icon..." -ForegroundColor Cyan

if (-not (Test-Path $SOURCE_ICON)) {
    Write-Host "ERROR: Source icon not found: $SOURCE_ICON" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

$ICON_NEEDS_UPDATE = $false

if (-not (Test-Path $DEST_ICON)) {
    Write-Host "Icon does not exist at $DEST_ICON, will copy..." -ForegroundColor Yellow
    $ICON_NEEDS_UPDATE = $true
} else {
    # Compare file hashes (MD5)
    $SOURCE_HASH = (Get-FileHash -Path $SOURCE_ICON -Algorithm MD5).Hash
    $DEST_HASH = (Get-FileHash -Path $DEST_ICON -Algorithm MD5).Hash

    if ($SOURCE_HASH -ne $DEST_HASH) {
        Write-Host "Icon checksums differ, will update..." -ForegroundColor Yellow
        Write-Host "  Source MD5: $SOURCE_HASH"
        Write-Host "  Dest MD5:   $DEST_HASH"
        $ICON_NEEDS_UPDATE = $true
    } else {
        Write-Host "Icon is up to date (MD5: $SOURCE_HASH)" -ForegroundColor Green
    }
}

if ($ICON_NEEDS_UPDATE) {
    Write-Host "Copying $SOURCE_ICON to $DEST_ICON..." -ForegroundColor Cyan
    Copy-Item $SOURCE_ICON $DEST_ICON -Force
    Write-Host "Icon copied successfully" -ForegroundColor Green
}

# -------------------------------------
# Read current versionCode and ask about incrementing
# -------------------------------------
$gradleContent = Get-Content $GRADLE_FILE
$CURRENT_CODE = [int](($gradleContent | Select-String "^flutter.versionCode=").ToString() -replace "flutter.versionCode=", "")

if (-not $CURRENT_CODE) {
    Write-Host "ERROR: Could not find flutter.versionCode in $GRADLE_FILE" -ForegroundColor Red
    Read-Host "Press Enter to exit"
    exit 1
}

Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host "Current Android versionCode: $CURRENT_CODE" -ForegroundColor Yellow
Write-Host ""
Write-Host "   versionCode is used by Google Play to identify app versions." -ForegroundColor Cyan
Write-Host "   It should be incremented for each new release." -ForegroundColor Cyan
Write-Host "   Only skip this for testing purposes." -ForegroundColor Cyan
Write-Host "--------------------------------------------" -ForegroundColor Yellow
Write-Host ""

$response = Read-Host "Increment versionCode to $($CURRENT_CODE + 1)? (Y/n)"
$INCREMENT_CODE = if ([string]::IsNullOrWhiteSpace($response)) { "y" } else { $response }

if ($INCREMENT_CODE -match "^[nN]") {
    $NEW_CODE = $CURRENT_CODE
    Write-Host "Keeping versionCode at $CURRENT_CODE (testing only)" -ForegroundColor Yellow
} else {
    $NEW_CODE = $CURRENT_CODE + 1
    Write-Host "Incrementing versionCode to $NEW_CODE" -ForegroundColor Green
}

# -------------------------------------
# Apply changes
# -------------------------------------

Write-Host ""
Write-Host "Updating app_config.dart (SOURCE OF TRUTH)..." -ForegroundColor Cyan
$configContent = Get-Content $APP_CONFIG_FILE
$configContent = $configContent -replace "(\s*static const String appVersion\s*=\s*')[^']*('.*)", "`${1}$APP_VERSION`${2}"

# Update app_config.dart with dependency overrides
foreach ($package in $depOverrides.Keys) {
    $version = $depOverrides[$package]
    $configContent = $configContent -replace "('$package'\s*:\s*')[^']*(')", "`${1}$version`${2}"
    Write-Host "  Updated $package to $version in app_config.dart" -ForegroundColor Green
}

foreach ($package in $devDepOverrides.Keys) {
    $version = $devDepOverrides[$package]
    $configContent = $configContent -replace "('$package'\s*:\s*')[^']*(')", "`${1}$version`${2}"
    Write-Host "  Updated $package to $version in app_config.dart" -ForegroundColor Green
}

Set-Content -Path $APP_CONFIG_FILE -Value $configContent

Write-Host "Updating pubspec.yaml..." -ForegroundColor Cyan
$pubspecContent = Get-Content $PUBSPEC_FILE
$pubspecContent = $pubspecContent -replace "^version:\s*[0-9]+(\.[0-9]+)*(-alpha|-beta|-rc[0-9]+)?.*$", "version: $APP_VERSION"

Write-Host "Syncing dependencies from app_config.dart to pubspec.yaml..." -ForegroundColor Cyan

# Re-read app_config.dart (with any overrides applied)
$configFileContent = Get-Content $APP_CONFIG_FILE -Raw

# Extract dependencies map
if ($configFileContent -match "static const Map<String, String> dependencies = \{([^}]+)\}") {
    $depsBlock = $matches[1]
    $depsBlock -split "`n" | ForEach-Object {
        if ($_ -match "'([^']+)':\s*'([^']+)'") {
            $package = $matches[1]
            $version = $matches[2]

            # Update in pubspec (without ^ for exact versions)
            $pubspecContent = $pubspecContent -replace "^(\s+$package\s*:).*$", "`${1} $version"
            Write-Host "  ✓ $package`: $version" -ForegroundColor Green
        }
    }
}

# Extract devDependencies map
Write-Host "Syncing devDependencies from app_config.dart to pubspec.yaml..." -ForegroundColor Cyan
if ($configFileContent -match "static const Map<String, String> devDependencies = \{([^}]+)\}") {
    $devDepsBlock = $matches[1]
    $devDepsBlock -split "`n" | ForEach-Object {
        if ($_ -match "'([^']+)':\s*'([^']+)'") {
            $package = $matches[1]
            $version = $matches[2]

            # Update in pubspec (without ^ for exact versions)
            $pubspecContent = $pubspecContent -replace "^(\s+$package\s*:).*$", "`${1} $version"
            Write-Host "  ✓ $package`: $version" -ForegroundColor Green
        }
    }
}

Set-Content -Path $PUBSPEC_FILE -Value $pubspecContent

Write-Host "Updating android/gradle.properties..." -ForegroundColor Cyan
$gradleContent = Get-Content $GRADLE_FILE
$gradleContent = $gradleContent -replace "^flutter.versionName=.*$", "flutter.versionName=$APP_VERSION"
$gradleContent = $gradleContent -replace "^flutter.versionCode=.*$", "flutter.versionCode=$NEW_CODE"
Set-Content -Path $GRADLE_FILE -Value $gradleContent

Write-Host "Updating linux/eccal.desktop..." -ForegroundColor Cyan
if (-not (Test-Path $DESKTOP_FILE)) {
    Write-Host "Creating $DESKTOP_FILE..." -ForegroundColor Yellow
    $desktopContent = @"
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
"@
    Set-Content -Path $DESKTOP_FILE -Value $desktopContent
}

$desktopContent = Get-Content $DESKTOP_FILE
$desktopContent = $desktopContent -replace "^Version=.*$", "Version=$APP_VERSION"
Set-Content -Path $DESKTOP_FILE -Value $desktopContent

# Update Flutter version in GitHub Actions
Write-Host ""
Write-Host "Updating Flutter version in GitHub Actions workflow..." -ForegroundColor Cyan

# Get Flutter version from app_config.dart
$FlutterVersionMatch = Select-String -Path $APP_CONFIG_FILE -Pattern "static const String flutterVersion\s*=\s*'([^']+)'" | Select-Object -First 1

if ($FlutterVersionMatch) {
    $FlutterVersion = $FlutterVersionMatch.Matches.Groups[1].Value
    Write-Host "Flutter version from app_config.dart: $FlutterVersion" -ForegroundColor Green

    if (Test-Path $RELEASE_YML) {
        # Update the FLUTTER_VERSION env variable in release.yml
        $content = Get-Content $RELEASE_YML -Raw
        $content = $content -replace "(FLUTTER_VERSION:\s*')([^']+)(')", "`${1}$FlutterVersion`${3}"
        Set-Content -Path $RELEASE_YML -Value $content -NoNewline
        Write-Host "  ✓ Updated $RELEASE_YML with Flutter $FlutterVersion" -ForegroundColor Green
    } else {
        Write-Host "WARNING: $RELEASE_YML not found, skipping..." -ForegroundColor Yellow
    }
} else {
    Write-Host "WARNING: Could not find flutterVersion in $APP_CONFIG_FILE" -ForegroundColor Yellow
    Write-Host "Skipping GitHub Actions workflow update" -ForegroundColor Yellow
}

# -------------------------------------
# Summary
# -------------------------------------
Write-Host ""
Write-Host "--------------------------------------------" -ForegroundColor Green
Write-Host "Version update complete!" -ForegroundColor Green
Write-Host "--------------------------------------------" -ForegroundColor Green
Write-Host "New VersionName:     $APP_VERSION" -ForegroundColor White
if ($IS_PRERELEASE) {
    Write-Host "Release Type:        PRE-RELEASE" -ForegroundColor Cyan
}
Write-Host "Old VersionCode:     $CURRENT_CODE" -ForegroundColor White
Write-Host "New VersionCode:     $NEW_CODE" -ForegroundColor White
if ($NEW_CODE -eq $CURRENT_CODE) {
    Write-Host "                     (unchanged - testing only!)" -ForegroundColor Yellow
}
if ($FlutterVersion) {
    Write-Host "Flutter Version:     $FlutterVersion" -ForegroundColor White
}
Write-Host ""
Write-Host "Updated files:" -ForegroundColor White
Write-Host "  • $APP_CONFIG_FILE (SOURCE OF TRUTH)" -ForegroundColor Green
Write-Host "  • $PUBSPEC_FILE (version + dependencies synced)" -ForegroundColor Green
Write-Host "  • $GRADLE_FILE"
Write-Host "  • $DESKTOP_FILE"
if ($FlutterVersion -and (Test-Path $RELEASE_YML)) {
    Write-Host "  • $RELEASE_YML (Flutter version)" -ForegroundColor Green
}
if ($ICON_NEEDS_UPDATE) {
    Write-Host "  • $DEST_ICON (copied)"
} else {
    Write-Host "  • $DEST_ICON (already up to date)"
}
Write-Host "--------------------------------------------" -ForegroundColor Green
Write-Host ""

Read-Host "Press Enter to exit"
