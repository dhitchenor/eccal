# Eccal - Diary App with CalDAV Sync

A cross-platform diary application that syncs with any CalDAV server (Potentially any RFC 4791 compliant CalDAV server).

## ✨ Features
📝 Rich Text Editing

- Full markdown support with live preview
- Rich text formatting (bold, italic, headings, lists)
- Clean, distraction-free writing interface
- Append mode for adding to existing entries

🎨 Beautiful Interface

- Modern, intuitive design
- Mood tracking with emoji indicators
- Location tagging support
- Customizable entry titles with date placeholders
- Dark and light theme support

💾 Flexible Storage

- Local storage - your data stays on your device
- Choose your own storage location
- Plain text file storage option for data portability
- No vendor lock-in

☁️ CalDAV Sync (Optional)

- Sync with your own Nextcloud, OwnCloud, or any calDAV server
- Automatic bidirectional synchronization
- Calendar-based entry viewing
- Works with standard CalDAV protocols
- Full privacy - your data, your server

🔍 Powerful Organization

- Search through all your entries
- Filter by mood, location, date, and content
- Date-based browsing
- Smart sidebar with sync status indicators

🔒 Privacy First

- All data can be stored locally
- No telemetry or tracking
- Open source - audit the code yourself
- Self-host your own calDAV server
- You control your data

## 📸 Screenshots

<!-- Add screenshots here, once app is running -->

## 🔧 Configuration

Storage Location
By default, EcCal stores entries in your Documents folder under EcCal/entries/. You can change this under: Settings → Local

1. Go to Settings → Server
2. Enter your CalDAV server URL (e.g., https://cloud.example.com/remote.php/dav)
3. Enter your username and password
4. Choose a calendar name (will be created automatically)
5. Click "Test & Setup" to verify connection
6. Click "Save Settings" in the prompt

Potentially supported CalDAV servers:
- Nextcloud
- OwnCloud
- Radicale
- Baikal
- Any RFC 4791 compliant CalDAV server


### Customization

- **Entry Title Templates**: Customize how new entries are named by default
- **Event Duration**: Customize how long entries appear in your calendar
- **Storage Type**: Choose .ics or text files, when storing locally
- **Moods**: Many preset moods with emoji icons
- **Location**: Manual input or GPS coordinates (if available with OS)

## 📱 Usage

### Creating an Entry

1. Tap the **+** button
2. Add title, select mood, add location (optional)
3. Write your entry with formatting support
4. Save - it automatically syncs to your calendar!

### Searching Entries

Use the search bar to find entries by:
- Title
- Content
- Mood
- Location

### Appending to Entries

1. Select an existing entry
2. Click Append
2. Add your new content
3. Save - the append is timestamped automatically

## 🚀 Quick Start

### Prerequisites

- Flutter SDK 3.38.5 or higher
- Dart 3.10.4 or higher
- Applicable libraries/SDK for platfrom specific builds


## 🛠️ Building from Source

```bash
# Clone the repository
git clone https://github.com/dhitchenor/eccal.git
cd eccal

# Install dependencies
flutter pub get

# Run on your device
flutter run

# Or build for release
flutter build <option> --release
```

### Installation

1. Download the file, that's appropriate for your operating system
2. Install
3. Run, and enjoy

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
Please see [Contributing](CONTRIBUTING.md)

### Development Setup Example

1. Fork the repository
2. Create your feature branch (`git checkout -b feature/AmazingFeature`)
3. Commit your changes (`git commit -m 'Add some AmazingFeature'`)
4. Push to the branch (`git push origin feature/AmazingFeature`)
5. Open a Pull Request

### Areas for Contribution

- User interface
- Choice between use of vEvent, and vJournal
- Support for more services (Google Calendar, iCloud, etc)
- Attachments (use of WebDAV)
- User accounts/ Multi-account support
- Encryption (maybe)
- Support for various calendar backends
- Mood analytics and trends
- Localization/translations
- Testing

## 🐛 Bug Reports

Found a bug? Please [open an issue](https://github.com/dhitchenor/eccal/issues) with:
- Device/OS information
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)

## 📝 License

This project is licensed under the GPLv3 License.

## 📞 Support

- **Issues**: [GitHub Issues](https://github.com/dhitchenor/eccal/issues)

## 🗺️ Roadmap

- [x] Basic diary functionality
- [x] CalDAV sync
- [x] Mood tracking
- [x] Location support
- [x] Search functionality
- [x] Export features
- [x] Google Calendar Support
- [ ] iCloud support
- [ ] Attachments
- [ ] vJournal Support
- [ ] Simultaneous multi-account capabilities/support
- [ ] Mobile app release

---

**Made with ❤️ by dhitchenor, and the EcCal community**

*Star ⭐ this repository if you find it useful!*
