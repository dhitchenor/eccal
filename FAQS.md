# EcCal - Frequently Asked Questions

## Table of Contents
- [General Questions](#general-questions)
- [Platform Support](#platform-support)
- [Google Calendar Integration](#google-calendar-integration)
- [Security & Privacy](#security--privacy)
- [Installation & Setup](#installation--setup)
- [Technical Details](#technical-details)

---

## General Questions

### What is EcCal?

EcCal is a comprehensive diary application built with Flutter that allows you to:
- Write rich-text diary entries with mood tracking and location data
- Store entries locally as RFC 5545-compliant iCalendar (.ics) files
- Sync your entries bidirectionally with CalDAV servers (like Nextcloud)
- Sync with Google Calendar (Apple Calendar, in coming)
- Access your diary across multiple devices

### Why is it called EcCal?

"EcCal" is a portmanteau of "Echo" and "CalDAV". 'Ec' refers to 'Echo', to echoing/reflecting your thoughts into a diary. 'Cal' refers to the CalDAV protocol used for synchronization with calendar servers.

### What makes EcCal different from other diary apps?

1. **Standards-compliant**: Uses iCalendar format (RFC 5545) for maximum compatibility
2. **Self-hosted sync**: Works with your own CalDAV server - you control your data
3. **Cross-platform**: Runs on Android, iOS, Windows, macOS, and Linux
4. **Rich features**: Mood tracking, location data, GPS coordinates, append functionality
5. **Offline-first**: Works without internet, syncs when available

---

## Platform Support

### Which platforms are supported?

| Platform | Status | Notes |
|----------|--------|-------|
| **Android** | Full support | APK |
| **iOS** | ⚠️ Limited | Requires Apple Developer Account (see below) |
| **Windows** | Full support | Desktop application |
| **macOS** | Full support | Desktop application |
| **Linux** | Full support | Desktop application |
| **Web** | ❌ Not supported | Use desktop/mobile apps |

### Why is iOS installation limited?

iOS has strict app distribution policies that make it challenging for independent developers to distribute apps:

**The Challenge:**
- Apple requires a **$99/year Apple Developer Account** to distribute apps
- Apps must be distributed through the **App Store** or via **TestFlight** (beta testing)
- **Sideloading** (installing apps directly) requires:
  - Xcode on a Mac
  - Rebuilding the app from source code
  - Re-signing every 7 days (for free accounts) or 1 year (paid accounts)

**Your Options:**

1. **Wait for App Store Release** (if/when available)
   - Requires developer to maintain Apple Developer Account (talk to me, about funding the iOS app)
   - Apps undergo Apple review process

2. **Build From Source** (Advanced users with Mac)
   ```bash
   # Requires: Mac, Xcode, Apple ID
   git clone https://github.com/dhitchenor/eccal
   cd eccal
   flutter build ios
   # Open in Xcode and deploy to your device
   ```

3. **Use Android or Desktop Instead**
   - Full functionality available on other platforms
   - No signing/distribution restrictions

**Why This Limitation Exists:**
Apple's walled garden approach prioritizes security and user safety, but creates barriers for independent developers and users who want to install apps outside the App Store.

### Can I use EcCal on multiple devices?

Yes! That's one of the main features. Install EcCal on all your devices and configure them to sync with the same CalDAV server (or Google Calendar/ Apple Calendar). Your entries will stay synchronized across all devices.

---

## Google Calendar Integration

### How do I connect to Google Calendar?

1. Go to Settings → Server tab
2. Select "Google Calendar" from the provider dropdown
3. Click "Sign in with Google"
4. Complete the authentication in your browser
5. Select which Google Calendar to sync with

### Looking at the source code, I noticed that the client ID, and client secret is hardcoded.. Why does the app need these?

**The Short Answer:**
- Mobile (Android/iOS): Only needs Client ID
- Desktop (Windows/macOS/Linux): Needs both Client ID AND Client Secret

**The Technical Explanation:**
This is due to OAuth 2.0 requirements for different application types. Desktop applications require both credentials to complete the OAuth flow via browser redirect.

### Wait, isn't "Client Secret" supposed to be SECRET?

**Excellent question!** This is a common misconception about OAuth for NATIVE apps (not web apps).

According to [**RFC 8252 Section 8.5** (OAuth 2.0 Best Current Practice for Native Apps)](https://datatracker.ietf.org/doc/html/rfc8252#section-8.5):

> **"Secrets that are statically included as part of an app distributed to multiple users should not be treated as confidential secrets"**

Here's why:

**For Public Applications (mobile/desktop apps):**
- Secrets **cannot** be kept truly confidential
- Users can decompile the app and extract the "secret"
- Secrets serve as **identifiers**, not true authentication
- Google themselves acknowledge this:

  > *"We don't expect those secrets to stay secret—so far we're including them mostly so it's convenient to use with libraries today"*  
  > — Andrew Wansley (Google OAuth2 Team), [Source](https://groups.google.com/g/oauth2-dev/c/HnFJJOvMfmA)

**Security is provided by:**
1. **PKCE** (Proof Key for Code Exchange) - prevents code interception
2. **Platform-specific security**:
   - Android: Package name + SHA-1 certificate fingerprint
   - iOS: Bundle ID verification
   - Desktop: Redirect URI validation

**What This Means For You:**
- It's **acceptable** to store client secrets in the EcCal native app code
- The "secret" is more like a **public identifier** than a password
- ⚠️ Real security comes from OAuth's proof-of-possession mechanisms, not the client secret

**References:**
- [RFC 8252 - OAuth 2.0 for Native Apps, Section 8.5](https://datatracker.ietf.org/doc/html/rfc8252#section-8.5)
- [Is client_id/client_secret a joke for open source apps?](https://groups.google.com/g/oauth2-dev/c/HnFJJOvMfmA)

### Does Google Calendar work on all platforms?

| Platform | Status | Method |
|----------|--------|--------|
| Android | Works | Native Google Sign-In |
| iOS | Works | Native Google Sign-In |
| Windows | Works | Browser OAuth flow |
| macOS | Works | Browser OAuth flow |
| Linux | Works | Browser OAuth flow |

**Desktop Note:** On desktop, clicking "Sign in with Google" opens your default browser for authentication, then returns to the app.

---

## Security & Privacy

### Where is my data stored?

**Local Storage:**
- Your diary entries are stored as `.ics` files in a directory you choose
- Default locations:
  - Android: App-specific data folder
  - iOS: App's documents directory
  - Desktop: Main documents folder

**Cloud Storage (Optional):**
- Only synced if you configure a CalDAV server or Google Calendar
- You control which server to use
- Can work 100% offline if you prefer

### Is my diary encrypted?

**Local Files:**
- Not encrypted by default
- You can store them in an encrypted folder/volume, but this is not directly supported by the app, yet

**Network Sync:**
- Uses HTTPS for all CalDAV communication
- Google Calendar uses OAuth 2.0 + HTTPS

### Can others read my diary if I use CalDAV sync?

**Who can access your data:**
- **You** - with your CalDAV credentials
- **Your CalDAV server admin** - if self-hosted, that's you!

**Can EcCal developers access your data:**
- we never see your data

**Best Practices:**
- Use a strong CalDAV password
- Enable 2FA on your calendar server if available
- Use your own self-hosted server for maximum privacy
- Consider end-to-end encryption solutions like Nextcloud's encryption

### What data does the app collect?

**Data Collection:**
- Absolutely nothing!
  - **ZERO** analytics
  - **ZERO** crash reports (by default)
  - **ZERO** tracking SDKs
  - **ZERO** ads, telemetry, or "anonymous usage data"

**What We Store Locally:**
- Your diary entries (in your chosen directory)
- App settings and preferences
- Logs

**Your data stays on YOUR devices and YOUR servers. Period.**

---

## Installation & Setup

### How do I install EcCal?

**Android:**
1. Download APK from [Releases page](https://github.com/dhitchenor/eccal/releases)
2. Enable "Install from unknown sources" in Android settings
3. Install the APK
4. Grant storage permissions when prompted

**iOS:**
- See "Why is iOS installation limited?" above
- Requires building from source or App Store release

**Desktop (Windows/macOS/Linux):**
1. Download installer for your platform from [Releases page](https://github.com/dhitchenor/eccal/releases)
2. Run installer, or manually setup however you like
3. Launch EcCal

### Do I need a CalDAV server?

**No!** EcCal works perfectly fine as a local-only diary app. CalDAV sync is completely optional.

**Use Cases:**
- **Local-only**: Just write diary entries, no sync needed
- **Self-hosted sync**: Set up Nextcloud and sync across devices
- **Google Calendar**: Use Google's calendar as your sync backend
- **Other CalDAV**: Any CalDAV-compatible service works

### How do I set up Nextcloud sync?

1. **Install Nextcloud** (on your server or use a provider)
2. **Create a calendar** in Nextcloud
3. **In EcCal:**
   - Go to Settings → Server
   - Select "CalDAV Calendar"
   - Enter your Nextcloud CalDAV URL:
      example:
      ```
      https://your-nextcloud.com/remote.php/dav/calendars/USERNAME/CALENDAR-NAME/
      ```
   - Enter username and password
   - Click "Test Connection"
   - Click "Sync with Server"

---

## Technical Details

### What is CalDAV?

CalDAV (Calendar Distributed Authoring and Versioning) is an open standard protocol (RFC 4791) that allows calendar clients and servers to synchronize calendar data. It's an extension of WebDAV.

**Benefits:**
- Open standard - not controlled by any single company
- Widely supported (Nextcloud, Apple Calendar, Google Calendar, etc.)
- Works with self-hosted servers
- Not tied to any specific vendor

### What is the iCalendar format?

iCalendar (RFC 5545) is a standard file format for storing calendar and scheduling information. EcCal stores all diary entries as `.ics` files.

**Why iCalendar?**
- Universal standard - works with any calendar app
- Human-readable text format
- Supports rich metadata (mood, location, custom properties)
- Future-proof - will work with any calendar app forever

**Example `.ics` file:**
See the STRUCTURE documentation

### Can I export my data?

**Yes!** Your data is already in a universal format:
- All entries are `.ics` files
- Import into any calendar app (Apple Calendar, Google Calendar, Outlook, etc.)
- Import all items into:
  - plain text (.txt)
  - iCalendar (.ics)
  - markdown (.md)
- Process with scripts/tools
- Backup by copying the folder

**No lock-in!** Your data is yours, in an open format, forever.

### Does EcCal support end-to-end encryption?

Encryption is not built-in, yet. But you have other options:
1. Store entries in an encrypted volume (VeraCrypt, LUKS, etc.)
2. Use Nextcloud's server-side encryption
3. Use encrypted CalDAV providers
4. Encrypt the entire device (iOS/Android have this built-in)

### What permissions does the app need?

**Android:**
- **Storage** - to read/write diary files
- **Location** (optional) - for GPS coordinates in entries
- **Internet** (optional) - for CalDAV/Google Calendar sync

**iOS:**
- **Files** - to read/write diary files
- **Location** (optional) - for GPS coordinates in entries
- **Internet** (optional) - for sync

**Desktop:**
- **File system access** - to read/write in your chosen directory
- **Internet** (optional) - for sync

All permissions are explained when requested and are used only for their stated purpose.

### Is the project open source?

**Yes!** EcCal is open source under [LICENSE].

- View source: [GitHub Repository](https://github.com/dhitchenor/eccal)
- Report issues: [Issue Tracker](https://github.com/dhitchenor/eccal/issues)
- Contribute: Pull requests welcome!
- Documentation: You're reading it!

---

## Troubleshooting

### CalDAV sync not working

**Common issues:**
1. **Wrong URL format** - Should end with `/`
   ```
   https://cloud.example.com/remote.php/dav/calendars/user/diary/
   ❌ https://cloud.example.com/remote.php/dav/calendars/user/diary
   ```

2. **Calendar doesn't exist** - Create it in your calendar server first

3. **Wrong credentials** - Double-check username/password

4. **Network issues** - Test connection first with "Test Connection" button

### Entries not syncing between devices

Check:
- All devices are configured with the same CalDAV server/calendar
- "Disable Sync" is not checked in settings
- Internet connection is active
- Manually trigger sync with "Sync Now" button
- Check for error messages in the app

### App crashes on startup

Try:
1. Clear app data and restart
2. Check you have storage permissions
3. Verify the storage path is accessible
4. Check logs (Settings → Advanced → View Logs)
5. Report the issue with logs attached

---

## Getting Help

### Where can I get support?

- 📖 **Documentation**: You're reading it!
- 🐛 **Bug Reports**: [GitHub Issues](https://github.com/dhitchenor/eccal/issues)
- 💬 **Discussions**: [GitHub Discussions](https://github.com/dhitchenor/eccal/discussions)
### How do I report a bug?

1. Check if it's already reported in [Issues](https://github.com/dhitchenor/eccal/issues)
2. Create a new issue with:
   - Clear description of the problem
   - Steps to reproduce
   - Your platform (Android/iOS/Windows/etc.)
   - App version
   - Logs (Settings → View Logs)
   - Screenshots if applicable

### Can I contribute to the project?

**Absolutely!** Contributions are welcome:
See [CONTRIBUTING.md](./CONTRIBUTING.md) for guidelines.

---

## Feature Requests

### Can you add [feature X]?

Check if it's already requested in [Issues](https://github.com/dhitchenor/eccal/issues). If not, create a feature request!

We consider all requests, but can't promise implementation timelines.
