### Versioning

We use semantic versioning with pre-release support:
- `X.Y.Z` - Stable releases
- `X.Y.Z-alpha` - Alpha releases
- `X.Y.Z-beta` - Beta releases
- `X.Y.Z-rc1` - Release candidates

**To update version:**
- **Linux/macOS:**
    - Run `scripts/version_update.sh`
- **Windows:**
    - Run `scripts/version_update.bat`
    - `version_update.bat` runs the powershell, with temporary elevated access control