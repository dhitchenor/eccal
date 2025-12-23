# Versioning & Release Guide

This guide explains the versioning system, version update process, and release workflow for EcCal.

## Table of Contents
- [Versioning System](#versioning-system)
- [Version Update Scripts](#version-update-scripts)
- [What Gets Updated](#what-gets-updated)
- [Release Process](#release-process)
- [Best Practices](#best-practices)

---

## Versioning System

### Semantic Versioning

EcCal uses **semantic versioning** with pre-release support:

```
X.Y.Z[-prerelease]
```

**Components:**
- `X` = **Major** version (breaking changes)
- `Y` = **Minor** version (new features, backward-compatible)
- `Z` = **Patch** version (bug fixes)
- `-prerelease` = Optional pre-release identifier

---

### Version Types

#### 1. Stable Releases

```
1.0.0
1.1.0
1.1.1
2.0.0
```

**Format:** `X.Y.Z`

**When to use:**
- Production-ready releases
- Feature-complete
- Thoroughly tested
- No known critical bugs

**Example progression:**
```
0.9.0 → 1.0.0 (first stable)
1.0.0 → 1.0.1 (bug fix)
1.0.1 → 1.1.0 (new feature)
1.1.0 → 2.0.0 (breaking change)
```

---

#### 2. Alpha Releases

```
1.0.0-alpha
1.1.0-alpha
2.0.0-alpha
```

**Format:** `X.Y.Z-alpha`

**Characteristics:**
- Early development/testing
- Incomplete features
- May have known bugs
- Internal use or brave testers
- API may change

**GitHub:** Automatically marked as **PRE-RELEASE**

**When to use:**
- First implementation of new features
- Early testing phase
- Gathering initial feedback

---

#### 3. Beta Releases

```
1.0.0-beta
1.1.0-beta
2.0.0-beta
```

**Format:** `X.Y.Z-beta`

**Characteristics:**
- Feature-complete
- Testing and refinement phase
- Bug fixes in progress
- API relatively stable
- Limited public release

**GitHub:** Automatically marked as **PRE-RELEASE**

**When to use:**
- All features implemented
- Ready for wider testing
- Collecting bug reports
- Final polish before release

---

#### 4. Release Candidates

```
1.0.0-rc1
1.0.0-rc2
1.0.0-rc3
```

**Format:** `X.Y.Z-rcN` (where N = 1, 2, 3, ...)

**Characteristics:**
- Final testing before stable
- No new features
- Critical bug fixes only
- Near-production quality
- Code freeze

**GitHub:** Automatically marked as **PRE-RELEASE**

**When to use:**
- Ready for release (pending final testing)
- All features complete and polished
- Only critical fixes allowed
- Last chance to catch issues

**Progression:**
```
1.0.0-beta → 1.0.0-rc1 → 1.0.0-rc2 → 1.0.0 (stable)
```

---

### Android Version Code

In addition to the version name, Android requires an integer `versionCode`:

```properties
flutter.versionName=1.0.0
flutter.versionCode=1
```

**Rules:**
- Must be an integer
- Must increment for each Google Play release
- Cannot decrease (Google Play requirement)
- Independent of version name

**Example progression:**
```
Version 1.0.0-alpha  → versionCode 1
Version 1.0.0-beta   → versionCode 2
Version 1.0.0-rc1    → versionCode 3
Version 1.0.0        → versionCode 4
Version 1.0.1        → versionCode 5
Version 1.1.0        → versionCode 6
```

**Important:** Always increment `versionCode` for production releases, even for patch versions.

---

## Version Update Scripts

### Quick Start

**Linux/macOS:**
```bash
./scripts/version_update.sh
```

**Windows:**
```cmd
scripts\version_update.bat
```

---

### Platform-Specific Scripts

#### Linux/macOS: `version_update.sh`

**Location:** `scripts/version_update.sh`

**Requirements:**
- Bash shell
- `sed` command (GNU or BSD)
- `md5sum` (Linux) or `md5` (macOS)

**Features:**
- Interactive prompts
- Version validation
- Dependency synchronization
- Icon MD5 checksum comparison
- Color-coded output

---

#### Windows: `version_update.bat` + `version_update.ps1`

**Location:**
- `scripts/version_update.bat` - Launcher
- `scripts/version_update.ps1` - Main script

**Requirements:**
- PowerShell 5.0 or higher
- Windows 7+ or Server 2008 R2+

**Why two files?**

`version_update.bat`:
```batch
@echo off
powershell -ExecutionPolicy Bypass -File "%~dp0version_update.ps1"
pause
```

**Purpose:** Windows PowerShell has execution policies that prevent running scripts by default. The `.bat` file temporarily bypasses this restriction.

---

### What the Scripts Do

The version update scripts perform these operations:

1. ✅ **Check version consistency** across all files
2. ✅ **Validate version format** (X.Y.Z, X.Y.Z-alpha, etc.)
3. ✅ **Update version number** in all files
4. ✅ **Sync dependencies** from `app_config.dart` to `pubspec.yaml`
5. ✅ **Increment Android version code** (with confirmation)
6. ✅ **Copy app icon** if changed (MD5 checksum)
7. ✅ **Update Flutter version** in GitHub Actions
8. ✅ **Show summary** of all changes

---

## What Gets Updated

### Files Modified

The version update scripts modify these files:

| File | What Gets Updated | Example |
|------|-------------------|---------|
| `lib/config/app_config.dart` | `appVersion` constant | `'1.0.0'` |
| `pubspec.yaml` | `version` field + dependencies | `version: 1.0.0` |
| `android/gradle.properties` | `versionName` + `versionCode` | `flutter.versionName=1.0.0`<br>`flutter.versionCode=1` |
| `linux/eccal.desktop` | `Version` field | `Version=1.0.0` |
| `.github/workflows/release.yml` | `FLUTTER_VERSION` variable | `FLUTTER_VERSION: '3.24.5'` |
| `linux/eccal.png` | Icon file (if changed) | *copied from assets/icon/app_icon.png* |

---

### Source of Truth

**`lib/config/app_config.dart`** is the **SOURCE OF TRUTH** for:
- App version number
- Flutter version
- All dependency versions

All other files are **synchronized** from this file.

---

### Dependency Synchronization

The scripts automatically sync dependencies from `app_config.dart` to `pubspec.yaml`:

**app_config.dart:**
```dart
static const Map<String, String> dependencies = {
  'provider': '6.1.0',
  'flutter_quill': '10.8.7',
  'intl': '0.19.0',
};
```

**Synced to pubspec.yaml:**
```yaml
dependencies:
  provider: 6.1.0
  flutter_quill: 10.8.7
  intl: 0.19.0
```

**Why this matters:**
- Ensures version consistency
- Prevents dependency mismatches
- Single source of truth for all versions

---

## Release Process

### Step-by-Step Release Workflow

#### 1. Prepare Release

```bash
# Make sure your code is ready
git status
git add .
git commit -m "Prepare for release X.Y.Z"
```

---

#### 2. Update Version

**Linux/macOS:**
```bash
./scripts/version_update.sh
```

**Windows:**
```cmd
scripts\version_update.bat
```

**The script will:**
1. Check current versions
2. Ask for new version number
3. Validate format
4. Ask to increment version code
5. Update all files
6. Show summary

---

#### 3. Review Changes

```bash
git diff
```

**Check:**
- Version updated in all files
- Dependencies synced correctly
- Version code incremented (for Android releases)
- Icon copied (if changed)

---

#### 4. Commit Version Update

```bash
git add .
git commit -m "Bump version to X.Y.Z"
```

---

#### 5. Create Git Tag

```bash
# For stable release
git tag vX.Y.Z

# For pre-release
git tag vX.Y.Z-alpha
git tag vX.Y.Z-beta
git tag vX.Y.Z-rc1
```

**Example:**
```bash
git tag v1.0.0
```

---

#### 6. Push Changes

```bash
git push origin main
git push origin vX.Y.Z
```

**This triggers:**
- GitHub Actions workflow (`.github/workflows/release.yml`)
- Automated builds for all platforms
- GitHub Release creation
- Asset uploads

---

#### 7. Verify Release

1. Go to GitHub → Releases
2. Check that release was created
3. Verify pre-release flag (for alpha/beta/rc)
4. Download and test builds

---

### Example: Complete Release Flow

```bash
# 1. Prepare code
git add .
git commit -m "Final changes for 1.1.0"

# 2. Update version
./scripts/version_update.sh
# Enter: 1.1.0
# Confirm: Yes to increment version code

# 3. Review changes
git diff

# 4. Commit version bump
git add .
git commit -m "Bump version to 1.1.0"

# 5. Create tag
git tag v1.1.0

# 6. Push
git push origin main
git push origin v1.1.0

# 7. Wait for GitHub Actions to complete
# 8. Download and test release builds
```

---

## Best Practices

### 1. Version Incrementing

**Major (X):** Breaking changes
```
1.9.9 → 2.0.0
```
- Changed API
- Removed features
- Incompatible changes

**Minor (Y):** New features
```
1.0.9 → 1.1.0
```
- New functionality
- Backward-compatible
- No breaking changes

**Patch (Z):** Bug fixes
```
1.0.0 → 1.0.1
```
- Bug fixes only
- No new features
- No breaking changes

---

### 2. Pre-Release Progression

**Recommended flow:**
```
1.0.0-alpha → 1.0.0-beta → 1.0.0-rc1 → 1.0.0-rc2 → 1.0.0
```

**Don't skip steps** unless absolutely necessary.

---

### 3. Version Code

**Always increment** for Google Play releases:
```
✓ Good:
  1.0.0 (code 1) → 1.0.1 (code 2) → 1.1.0 (code 3)

✗ Bad:
  1.0.0 (code 1) → 1.0.1 (code 1)  ← Google Play will reject!
```

**For testing:** You can skip incrementing, but mark it clearly:
```bash
# Script will ask:
Increment versionCode to 2? (Y/n): n
Keeping versionCode at 1 (testing only)
```

---

### 4. Commit Messages

**Use clear commit messages:**
```bash
✓ Good:
  "Bump version to 1.1.0"
  "Prepare release 1.0.0-beta"
  "Update to version 2.0.0-rc1"

✗ Bad:
  "Version update"
  "Updated files"
  "Changes"
```

---

### 5. Git Tags

**Format:** `vX.Y.Z` or `vX.Y.Z-prerelease`

```bash
✓ Good:
  v1.0.0
  v1.0.0-alpha
  v1.0.0-beta
  v1.0.0-rc1

✗ Bad:
  1.0.0 (missing 'v' prefix)
  release-1.0.0
  version_1.0.0
```

---

### 6. Release Notes

**Always include release notes** on GitHub:

**For stable releases:**
```markdown
## What's New
- Added dark mode theme selection
- Improved CalDAV sync performance
- New export to PDF feature

## Bug Fixes
- Fixed crash on Android 11
- Resolved timezone display issue

## Breaking Changes
None
```

**For pre-releases:**
```markdown
## Alpha Release - Testing Only
This is an early preview. Expect bugs!

## New Features (WIP)
- Dark mode (partially implemented)
- PDF export (experimental)

## Known Issues
- Sync may fail intermittently
- UI not finalized
```

---

### 7. Testing Before Release

**Checklist:**
- [ ] All tests pass
- [ ] Manual testing completed
- [ ] No critical bugs
- [ ] Documentation updated
- [ ] Changelog prepared
- [ ] Version updated correctly
- [ ] Git tag created
- [ ] Release notes ready

---

## Troubleshooting

### Version Mismatch Detected

**Symptom:**
```
WARNING: Version inconsistency detected!!!
  • lib/config/app_config.dart: 1.0.0
  • pubspec.yaml: 0.9.9
  • android/gradle.properties: 0.9.9
```

**Solution:** Run the version update script and enter the correct version.

---

### Script Permission Denied (Linux/macOS)

**Symptom:**
```
bash: ./scripts/version_update.sh: Permission denied
```

**Solution:**
```bash
chmod +x scripts/version_update.sh
./scripts/version_update.sh
```

---

### PowerShell Execution Policy Error (Windows)

**Symptom:**
```
execution of scripts is disabled on this system
```

**Solution:** Use `version_update.bat` instead of running `.ps1` directly:
```cmd
scripts\version_update.bat
```

---

### Invalid Version Format

**Symptom:**
```
ERROR: Invalid version format.
Expected: X.Y.Z, X.Y.Z-alpha, X.Y.Z-beta, or X.Y.Z-rc1
```

**Valid formats:**
```
✓ 1.0.0
✓ 1.0.0-alpha
✓ 1.0.0-beta
✓ 1.0.0-rc1
✓ 1.0.0-rc2

✗ 1.0
✗ v1.0.0
✗ 1.0.0-RC1 (uppercase)
✗ 1.0.0-preview
```

---

## Need More Help?

- **Project Structure:** See [STRUCTURE.md](STRUCTURE.md)
- **Build Scripts:** Check `scripts/version_update.sh` or `scripts/version_update.ps1`
- **GitHub Actions:** See `.github/workflows/release.yml`
- **Semantic Versioning:** Visit [semver.org](https://semver.org)
