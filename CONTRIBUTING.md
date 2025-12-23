# Contributing to EcCal

Thank you for your interest in contributing to EcCal! This document will guide you through the contribution process.

## 📋 Table of Contents 📋

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [Contributing Guidelines](#contributing-guidelines)
- [Translation Contributions](#translation-contributions)
- [Reporting Issues](#reporting-issues)
- [Pull Request Process](#pull-request-process)

## Code of Conduct

By participating in this project, you agree to maintain a respectful and inclusive environment for all contributors.

## Getting Started

EcCal is a cross-platform diary application built with Flutter, featuring CalDAV integration for cloud synchronization.

**Before contributing:**
1. Check existing [Issues](https://github.com/dhitchenor/eccal/issues) and [Pull Requests](https://github.com/dhitchenor/eccal/pulls)
2. Read the development documentation
3. Set up your development environment

## Development Setup

**Prerequisites:**
- Flutter 3.38.5 or higher
- Dart SDK (bundled with Flutter)
- Platform-specific tools (Android Studio, Xcode, etc.)

**Reproducibility:**
- All versions of all tools, should be frozen to a specific version depending on the version of EcCal, as to retain reproducibility

**Building for multiple platforms:**
Strive to build/maintain EcCal for different platforms:
- Android
- iOS
- Linux
- Windows
- macOS

## Contributing Guidelines

### Code Style

- Follow [Dart style guidelines](https://dart.dev/guides/language/effective-dart/style)
- Use meaningful variable and function names
- Comment complex logic
- Keep functions small and focused

[**Structure guide/details:**](.github/docs/STRUCTURE.md)

[**Logging guide/details:**](.github/docs/LOGGING.md)

[**Versioning guide:**](.github/docs/VERSIONING.md)

## Translation Contributions

EcCal supports multiple languages and we welcome translation contributions!

[**Translation guide:**](.github/docs/TRANSLATIONS.md)

**Current Translations:**
- English (en)

- some existing language files have been added in the project, in an attempt to prompt others to translate EcCal

## Reporting Issues

### Bug Reports

When reporting bugs, please include:
- EcCal version
- Platform (Android/iOS/Linux/Windows/macOS)
- Steps to reproduce
- Expected vs actual behavior
- Screenshots (if applicable)
- Logs (if available)

### Feature Requests

We welcome feature suggestions! Please:
- Check if the feature already exists or is planned
- Describe the use case
- Explain why it would benefit users

## Pull Request Process

### Before Submitting

1. **Fork** the repository
2. **Create a branch** from `main`:
```bash
   git checkout -b feature/your-feature-name
```
3. **Make your changes**
4. **Test thoroughly** on relevant platforms
5. **Update documentation** if needed
6. **Run code formatting**:
```bash
   flutter format .
```
7. **Commit your changes**:
```bash
   git commit -m "feat: add feature description"
```

### Commit Message Format

EcCal development follows [Conventional Commits](https://www.conventionalcommits.org/):

- `feat:` - New feature
- `fix:` - Bug fix
- `docs:` - Documentation changes
- `style:` - Code style changes (formatting)
- `refactor:` - Code refactoring
- `test:` - Adding tests
- `chore:` - Maintenance tasks

**Examples:**
```
feat: add dark mode support for neutral theme
fix: resolve FAB animation glitch on mobile
docs: update list in CONTRIBUTING.md with new translations
```

### Submitting the Pull Request

1. **Push to your fork**:
```bash
   git push origin feature/your-feature-name
```

2. **Open a Pull Request** on GitHub

3. **Fill out the PR template** with:
   - Description of changes
   - Related issue number (if applicable)
   - Testing performed
   - Screenshots (for UI changes)

4. **Wait for review**
   - Address any feedback
   - Keep your branch up to date with `main`

### Review Process

- Changes may be requested for code quality or style
- Be responsive to feedback

## Questions?

- 💬 Open a [Discussion](https://github.com/dhitchenor/eccal/discussions)
- 🐛 Report a [Bug](https://github.com/dhitchenor/eccal/issues/new?template=bug_report.md)
- 💡 Suggest a [Feature](https://github.com/dhitchenor/eccal/issues/new?template=feature_request.md)

## License

By contributing to EcCal, you agree that your contributions will be licensed under the same license as the project.

---

Thank you for contributing to EcCal! 🎉
