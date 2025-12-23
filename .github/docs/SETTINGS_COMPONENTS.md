# Settings Components Usage Guide

This guide explains how to use the reusable components in `settings_components.dart` for building consistent, responsive settings screens.

## Table of Contents
- [Layout Components](#layout-components)
- [Text Components](#text-components)
- [Input Components](#input-components)
- [Display Components](#display-components)
- [Spacing](#spacing)
- [Best Practices](#best-practices)

---

## Layout Components

### `ResponsiveSettingsLayout`
Wraps your entire settings tab with responsive padding (16px mobile, 32px desktop).

```dart
return ResponsiveSettingsLayout(
  children: [
    SettingsSpacing.item(),
    // Your settings widgets here
  ],
);
```

**When to use:** As the root widget for every settings tab.

---

### `IndentedContent`
Indents content by 4-8px with 80% width constraint. Used for nested sub-options.

```dart
IndentedContent(
  child: Column(
    children: [
      SettingsSwitchRow(...),
      SettingsSwitchRow(...),
    ],
  ),
)
```

**When to use:** For sub-options under a main setting (like "Append Headers" with mood/location switches).

---

## Text Components

### `SettingsSectionTitle`
Large bold title (20px, bold).

```dart
SettingsSectionTitle(text: 'General Settings')
```

**When to use:** Main section headings.

---

### `SettingsHelperText`
Small grey helper text (12px, grey).

```dart
SettingsHelperText(
  text: 'This setting controls...',
  padding: EdgeInsets.zero,
)
```

**When to use:** Explanatory text below titles or inputs.

---

### `SettingsSmallLabel`
Medium label text (14px, normal weight).

```dart
SettingsSmallLabel(text: 'Export as:')
```

**When to use:** Labels next to dropdowns or other inputs.

---

### `SettingsTitleWithHelper`
Title with helper text underneath (configurable spacing).

```dart
SettingsTitleWithHelper(
  title: 'Background Sync',
  helperText: 'Automatically sync in the background',
  spacing: 0.0, // Optional: space between title and helper
)
```

**When to use:** When you need a title and description together without any input.

---

### `SettingsTitleWithValue`
Title with a value displayed inline, with optional helper text.

```dart
SettingsTitleWithValue(
  title: 'Storage Location',
  value: '/path/to/storage',
  helperText: 'Change location to move files',
  isLoading: false,
)
```

**Layout:**
- **Desktop:** Title and value on same row, helper below
- **Mobile:** Title and helper stacked, value indented below

**When to use:** Displaying current setting values (paths, status, etc.).

---

## Input Components

### `SettingsDropdownRow<T>`
Title on left, dropdown on right (with responsive borders).

```dart
SettingsDropdownRow<bool>(
  title: 'Time Format',
  helperText: 'Choose 12 or 24 hour format', // Optional
  value: settings.use24HourFormat,
  items: [
    DropdownMenuItem(value: true, child: Text('24 Hour')),
    DropdownMenuItem(value: false, child: Text('12 Hour')),
  ],
  onChanged: (value) {
    if (value != null) settings.setTimeFormat(value);
  },
)
```

**Responsive behavior:**
- **Mobile:** Underline border
- **Desktop:** Outline box
- **Padding:** 40px (< 1000px) or 80px (>= 1000px) from right edge

**When to use:** Simple dropdown selections.

---

### `SettingsTitleWithAction<T>`
Title with switch/button on left, dropdown on right.

```dart
SettingsTitleWithAction<AppColorFamily>(
  title: 'Theme',
  helperText: 'Customize app appearance', // Optional
  
  // Switch (appears beside title)
  switchValue: isDarkMode,
  onSwitchChanged: (value) => setDarkMode(value),
  switchLabel: 'Dark Mode',
  
  // Dropdown (appears on right)
  dropdownLabel: '', // Optional label before dropdown
  dropdownValue: currentTheme,
  dropdownItems: [...],
  onDropdownChanged: (value) => setTheme(value),
)
```

**OR with button instead of switch:**

```dart
SettingsTitleWithAction<ExportFormat>(
  title: 'Export All Entries',
  helperText: 'Download all diary entries',
  
  // Button (appears beside title on desktop, beside dropdown on mobile)
  actionButton: OutlinedButton.icon(
    onPressed: () => startExport(),
    icon: Icon(Icons.download),
    label: Text('Start'),
  ),
  
  // Dropdown
  dropdownLabel: 'Export as:',
  dropdownValue: exportFormat,
  dropdownItems: [...],
  onDropdownChanged: (value) => setFormat(value),
)
```

**Layout:**
- **Desktop:** `[Title] [Button/Switch+Label] ... [Dropdown Label][Dropdown ▼]`
  - Helper text appears below title
  - Right padding: 40px (< 1000px) or 80px (>= 1000px)
- **Mobile:** Title, helper, then dropdown+button in a row

**When to use:** 
- Settings that need both a toggle/action AND a dropdown selection
- Export functionality with format selection

---

### `SettingsTextFieldRow`
Title on left, text field on right.

```dart
SettingsTextFieldRow(
  title: 'Default Duration',
  helperText: 'Length of new entries', // Optional
  controller: durationController,
  suffix: 'min', // Optional suffix
  labelText: 'Duration', // Optional field label
  hintText: 'Enter minutes', // Optional placeholder
  keyboardType: TextInputType.number,
  onChanged: (value) => saveDuration(value),
)
```

**Responsive behavior:**
- **Right padding:** 40px (< 1000px) or 80px (>= 1000px)
- Uses `Spacer()` to push text field right
- Text field has `flex: 2` for better width control

**When to use:** Text or number input fields.

---

### `SettingsSwitchRow`
Title/label with switch, optional description below.

```dart
SettingsSwitchRow(
  title: 'Show Append Mood',
  description: 'Display mood in append headers', // Optional
  value: settings.showMood,
  onChanged: (value) => settings.setShowMood(value),
  isSubtitle: true, // Optional: uses 16px non-bold text
)
```

**Parameters:**
- `isSubtitle`: If `true`, title is 16px non-bold (for sub-options)
- `isSubtitle`: If `false` (default), title is 20px bold

**When to use:** Toggle switches with optional descriptions.

---

### `SettingsButtonRow`
Row of buttons with consistent spacing.

```dart
SettingsButtonRow(
  buttons: [
    ElevatedButton.icon(
      onPressed: () => chooseFolder(),
      icon: Icon(Icons.folder_open),
      label: Text('Change Location'),
    ),
    OutlinedButton.icon(
      onPressed: () => resetToDefault(),
      icon: Icon(Icons.refresh),
      label: Text('Reset'),
    ),
  ],
  alignment: MainAxisAlignment.start, // Optional
)
```

**When to use:** Multiple related action buttons.

---

### `SettingsCheckboxTile`
Checkbox with title and optional subtitle (similar to ListTile).

```dart
SettingsCheckboxTile(
  title: 'Enable Feature',
  subtitle: 'This feature does...', // Optional
  value: settings.featureEnabled,
  onChanged: (value) {
    if (value != null) settings.setFeature(value);
  },
)
```

**When to use:** Checkbox toggles (prefer `SettingsSwitchRow` for modern UI).

---

## Display Components

### `SettingsCard`
Card with consistent padding and optional color.

```dart
SettingsCard(
  color: Colors.blue.shade50, // Optional
  margin: EdgeInsets.symmetric(vertical: 8), // Optional
  padding: EdgeInsets.all(16), // Optional
  child: Text('Card content'),
)
```

**When to use:** Grouping related settings or displaying info.

---

### `SettingsInfoBox`
Blue info card with title and content (for examples/help).

```dart
SettingsInfoBox(
  title: 'Available Placeholders',
  content:
    '• {weekday} - Full weekday name\n'
    '• {dd} - Day of month\n'
    '• {yyyy} - Full year',
)
```

**When to use:** Showing examples, help text, or important information.

---

## Spacing

### `SettingsSpacing`
Consistent spacing constants and widgets.

**Vertical spacing:**
```dart
SettingsSpacing.section()  // 32px - between major sections
SettingsSpacing.item()     // 16px - between items in a section
SettingsSpacing.tight()    // 8px - tight spacing
SettingsSpacing.micro()    // 4px - very tight spacing
```

**Horizontal spacing:**
```dart
SettingsSpacing.horizontalSection()  // 32px
SettingsSpacing.horizontalItem()     // 16px
SettingsSpacing.horizontalTight()    // 8px
SettingsSpacing.horizontalMicro()    // 4px
```

**When to use:**
- `section()`: Between major setting groups
- `item()`: Between individual settings
- `tight()`: Between related sub-items
- `micro()`: Between title and helper text

---

## Best Practices

### 1. Consistent Layout Structure
```dart
return ResponsiveSettingsLayout(
  children: [
    SettingsSpacing.item(),
    
    // Section 1
    SettingsDropdownRow(...),
    SettingsSpacing.section(),
    
    // Section 2
    SettingsTitleWithHelper(
      title: 'Section Title',
      helperText: 'Description',
    ),
    SettingsSpacing.item(),
    IndentedContent(
      child: Column(
        children: [
          SettingsSwitchRow(..., isSubtitle: true),
          SettingsSpacing.tight(),
          SettingsSwitchRow(..., isSubtitle: true),
        ],
      ),
    ),
    SettingsSpacing.section(),
  ],
);
```

### 2. Use Appropriate Components
- **Dropdowns:** `SettingsDropdownRow`
- **Text fields:** `SettingsTextFieldRow`
- **Switches:** `SettingsSwitchRow`
- **Buttons + Dropdowns:** `SettingsTitleWithAction`
- **Info boxes:** `SettingsInfoBox`

### 3. Responsive Behavior
All components handle mobile/desktop responsiveness automatically:
- Mobile (< 600px): Stacked layouts, underline borders
- Desktop (>= 600px): Side-by-side layouts, outline borders
- Right padding: 40px (< 1000px) or 80px (>= 1000px)

### 4. Typography Hierarchy
- **Section titles:** `SettingsSectionTitle` (20px, bold)
- **Subtitles:** `SettingsSwitchRow` with `isSubtitle: true` (16px, normal)
- **Labels:** `SettingsSmallLabel` (14px)
- **Helper text:** `SettingsHelperText` (12px, grey)

### 5. Indented Sub-Options
Use `IndentedContent` + `isSubtitle: true` for nested options:
```dart
SettingsTitleWithHelper(
  title: 'Main Setting',
  helperText: 'Description',
),
SettingsSpacing.item(),
IndentedContent(
  child: Column(
    children: [
      SettingsSwitchRow(..., isSubtitle: true),
      SettingsSpacing.tight(),
      SettingsSwitchRow(..., isSubtitle: true),
    ],
  ),
),
```

### 6. Consistent Spacing
- Use `SettingsSpacing` constants instead of hardcoded values
- `section()` between major groups
- `item()` between settings
- `tight()` between sub-items
- `micro()` between title and helper

---

## Complete Example

```dart
class MySettingsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final settings = context.watch<SettingsProvider>();
    
    return ResponsiveSettingsLayout(
      children: [
        SettingsSpacing.item(),
        
        // Theme settings with switch and dropdown
        SettingsTitleWithAction<ThemeColor>(
          title: 'Theme',
          switchValue: settings.isDarkMode,
          onSwitchChanged: (value) => settings.setDarkMode(value),
          switchLabel: 'Dark Mode',
          dropdownLabel: '',
          dropdownValue: settings.themeColor,
          dropdownItems: [...],
          onDropdownChanged: (value) => settings.setThemeColor(value),
        ),
        
        SettingsSpacing.section(),
        
        // Language dropdown
        SettingsDropdownRow<String>(
          title: 'Language',
          value: settings.language,
          items: [...],
          onChanged: (value) => settings.setLanguage(value),
        ),
        
        SettingsSpacing.section(),
        
        // Advanced options section
        SettingsTitleWithHelper(
          title: 'Advanced Options',
          helperText: 'Configure advanced features',
        ),
        SettingsSpacing.item(),
        IndentedContent(
          child: Column(
            children: [
              SettingsSwitchRow(
                title: 'Enable Feature A',
                description: 'Description of feature A',
                value: settings.featureA,
                onChanged: (value) => settings.setFeatureA(value),
                isSubtitle: true,
              ),
              SettingsSpacing.tight(),
              SettingsSwitchRow(
                title: 'Enable Feature B',
                description: 'Description of feature B',
                value: settings.featureB,
                onChanged: (value) => settings.setFeatureB(value),
                isSubtitle: true,
              ),
            ],
          ),
        ),
        
        SettingsSpacing.item(),
        
        // Info box with examples
        SettingsInfoBox(
          title: 'Need Help?',
          content: 'Visit our documentation at example.com',
        ),
      ],
    );
  }
}
```

---

## Migration Tips

If you have existing settings screens:

1. **Wrap with ResponsiveSettingsLayout:**
   ```dart
   return ResponsiveSettingsLayout(children: [...]);
   ```

2. **Replace custom rows with components:**
   - `Row(title, dropdown)` → `SettingsDropdownRow`
   - `Row(title, TextField)` → `SettingsTextFieldRow`
   - `Row(title, Switch)` → `SettingsSwitchRow`

3. **Use SettingsSpacing instead of SizedBox:**
   - `SizedBox(height: 32)` → `SettingsSpacing.section()`
   - `SizedBox(height: 16)` → `SettingsSpacing.item()`

4. **Replace hardcoded padding:**
   - Remove manual padding calculations
   - Components handle responsive padding automatically

---

## Need More Help?

- Check existing tabs: `display_tab.dart`, `general_tab.dart`, `local_tab.dart`, `server_tab.dart`
- All components have inline documentation in `settings_components.dart`
- Components are designed to be composable - mix and match as needed!
