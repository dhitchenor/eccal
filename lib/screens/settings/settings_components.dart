import 'package:flutter/material.dart';

// Reusable components for settings screens with consistent styling and responsive padding

// RESPONSIVE PADDING
// =============================

// Get responsive horizontal padding based on screen width
// (32px desktop, 16px mobile)
EdgeInsets getResponsivePadding(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final isMobile = width < 600;
  final horizontal = isMobile ? 16.0 : 32.0;
  return EdgeInsets.symmetric(horizontal: horizontal, vertical: 16.0);
}

// Get responsive left padding only
EdgeInsets getResponsiveLeftPadding(BuildContext context) {
  final width = MediaQuery.of(context).size.width;
  final isMobile = width < 600;
  return EdgeInsets.only(left: isMobile ? 16.0 : 32.0);
}

// SECTION TITLE
// =============================

// Large bold section title
class SettingsSectionTitle extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry? padding;

  const SettingsSectionTitle({Key? key, required this.text, this.padding})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(
        text,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
      ),
    );
  }
}

// HELPER TEXT
// =============================

// Small gray helper text
class SettingsHelperText extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry? padding;

  const SettingsHelperText({Key? key, required this.text, this.padding})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.only(left: 4.0, top: 4.0),
      child: Text(
        text,
        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        softWrap: true,
      ),
    );
  }
}

// SMALL LABEL TEXT
// =============================

// Small label text
// Used for secondary labels that need to be smaller than section titles
class SettingsSmallLabel extends StatelessWidget {
  final String text;
  final EdgeInsetsGeometry? padding;

  const SettingsSmallLabel({Key? key, required this.text, this.padding})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? EdgeInsets.zero,
      child: Text(text, style: const TextStyle(fontSize: 14)),
    );
  }
}

// HELPER WIDGET BUILDERS
// =============================

// Builds a title with optional helper text underneath
// Used internally by multiple components for consistency
Widget _buildTitleWithHelper({required String title, String? helperText}) {
  if (helperText != null) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(text: title),
        SettingsHelperText(text: helperText, padding: EdgeInsets.zero),
      ],
    );
  }
  return SettingsSectionTitle(text: title);
}

// Builds a dropdown aligned at a specific percentage with optional label
// Used internally by multiple components for consistency
// COMPACT ROW WITH TITLE AND DROPDOWN
// =============================

// Compact row layout: Title on left, dropdown on right
class SettingsDropdownRow<T> extends StatelessWidget {
  final String title;
  final String? helperText;
  final T value;
  final List<DropdownMenuItem<T>> items;
  final ValueChanged<T?>? onChanged;

  const SettingsDropdownRow({
    Key? key,
    required this.title,
    this.helperText,
    required this.value,
    required this.items,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    // Responsive padding: smaller screens get less padding
    final rightPadding = screenWidth < 1000 ? 40.0 : 80.0;

    return Padding(
      padding: EdgeInsets.only(right: rightPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildTitleWithHelper(title: title, helperText: helperText),
          const Spacer(),
          IntrinsicWidth(
            child: DropdownButtonFormField<T>(
              value: value,
              decoration: InputDecoration(
                // Mobile: underline, Desktop: outline box
                border: isMobile
                    ? const UnderlineInputBorder()
                    : const OutlineInputBorder(),
                contentPadding: EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              items: items,
              onChanged: onChanged,
              isExpanded: true,
            ),
          ),
        ],
      ),
    );
  }
}

// TITLE WITH ACTION (button/switch) AND DROPDOWN ON RIGHT
// =============================

// Responsive layout component for actions with dropdowns
// Desktop: [Title] [Button/Switch+Label] on left | [Dropdown Label][Dropdown] on right
// Mobile: Stacked - title+switch, helper, then dropdown+button row
class SettingsTitleWithAction<T> extends StatelessWidget {
  final String title;
  final String? helperText;
  final double helperFontSize;
  final double helperSpacing;

  // Action button (optional) - appears on RIGHT side of title on desktop, RIGHT of dropdown on mobile
  final Widget? actionButton;

  // Switch option - appears on RIGHT side of title with label
  final bool? switchValue;
  final ValueChanged<bool>? onSwitchChanged;
  final String? switchLabel;

  // Dropdown configuration
  final String dropdownLabel;
  final T dropdownValue;
  final List<DropdownMenuItem<T>> dropdownItems;
  final ValueChanged<T?>? onDropdownChanged;

  const SettingsTitleWithAction({
    Key? key,
    required this.title,
    this.helperText,
    this.helperFontSize = 14.0,
    this.helperSpacing = 8.0,
    this.actionButton,
    this.switchValue,
    this.onSwitchChanged,
    this.switchLabel,
    required this.dropdownLabel,
    required this.dropdownValue,
    required this.dropdownItems,
    required this.onDropdownChanged,
  }) : super(key: key);

  Widget? _buildSwitchWidget() {
    if (switchValue != null && onSwitchChanged != null) {
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Switch(value: switchValue!, onChanged: onSwitchChanged),
          if (switchLabel != null) ...[
            SettingsSpacing.horizontalTight(),
            SettingsSmallLabel(text: switchLabel!),
          ],
        ],
      );
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final switchWidget = _buildSwitchWidget();

        if (isMobile) {
          // Mobile layout: stacked vertically
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Title with switch on same line
              Row(
                children: [
                  SettingsSectionTitle(text: title),
                  if (switchWidget != null) ...[
                    SettingsSpacing.horizontalItem(),
                    switchWidget,
                  ],
                ],
              ),

              // Helper text below title
              if (helperText != null) ...[
                SettingsSpacing.micro(),
                SettingsHelperText(text: helperText!, padding: EdgeInsets.zero),
              ],

              SettingsSpacing.item(),

              // Dropdown and button in row
              Row(
                children: [
                  if (dropdownLabel.isNotEmpty) ...[
                    SettingsSmallLabel(text: dropdownLabel),
                    SettingsSpacing.horizontalTight(),
                  ],
                  DropdownButton<T>(
                    value: dropdownValue,
                    items: dropdownItems,
                    onChanged: onDropdownChanged,
                  ),
                  if (actionButton != null) ...[
                    SettingsSpacing.horizontalItem(),
                    actionButton!,
                  ],
                ],
              ),
            ],
          );
        } else {
          // Desktop layout
          final screenWidth = MediaQuery.of(context).size.width;
          final rightPadding = screenWidth < 1000 ? 40.0 : 80.0;

          return Padding(
            padding: EdgeInsets.only(right: rightPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top row: Title with button/switch on left, dropdown on right
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Left side: Title with button/switch beside it
                    SettingsSectionTitle(text: title),
                    SettingsSpacing.horizontalItem(),
                    // Button or switch beside the title
                    if (actionButton != null)
                      actionButton!
                    else if (switchWidget != null)
                      switchWidget,

                    const Spacer(),

                    // Right side: Dropdown label and dropdown
                    if (dropdownLabel.isNotEmpty) ...[
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: SettingsSmallLabel(text: dropdownLabel),
                      ),
                      SettingsSpacing.horizontalTight(),
                    ],
                    IntrinsicWidth(
                      child: DropdownButtonFormField<T>(
                        value: dropdownValue,
                        decoration: const InputDecoration(
                          border: OutlineInputBorder(),
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 8,
                          ),
                        ),
                        items: dropdownItems,
                        onChanged: onDropdownChanged,
                        isExpanded: true,
                      ),
                    ),
                  ],
                ),

                // Helper text below
                if (helperText != null) ...[
                  SettingsSpacing.micro(),
                  SettingsHelperText(
                    text: helperText!,
                    padding: EdgeInsets.zero,
                  ),
                ],
              ],
            ),
          );
        }
      },
    );
  }
}

// COMPACT ROW WITH TITLE AND TEXT FIELD
// =============================

// Compact row layout: Title on left, text field on right
class SettingsTextFieldRow extends StatelessWidget {
  final String title;
  final String? helperText; // Helper text under title
  final TextEditingController controller;
  final String? suffix;
  final String? labelText; // Label inside text field
  final String? hintText; // Placeholder text
  final String? infoText; // Helper text inside text field decoration
  final TextInputType? keyboardType;
  final ValueChanged<String>? onChanged;
  final int? maxLines;

  const SettingsTextFieldRow({
    Key? key,
    required this.title,
    this.helperText,
    required this.controller,
    this.suffix,
    this.labelText,
    this.hintText,
    this.infoText,
    this.keyboardType,
    this.onChanged,
    this.maxLines = 1,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final rightPadding = screenWidth < 1000 ? 40.0 : 80.0;

    return Padding(
      padding: EdgeInsets.only(right: rightPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (helperText != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SettingsSectionTitle(text: title),
                SettingsHelperText(text: helperText!),
              ],
            )
          else
            SettingsSectionTitle(text: title),
          const Spacer(),
          Expanded(
            flex: 2,
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                labelText: labelText,
                suffix: suffix != null ? Text(suffix!) : null,
                hintText: hintText,
                helperText: infoText,
                border: const OutlineInputBorder(),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
              ),
              keyboardType: keyboardType,
              maxLines: maxLines,
              onChanged: onChanged,
            ),
          ),
        ],
      ),
    );
  }
}

// CHECKBOX LIST TILE
// =============================

// Checkbox list tile with consistent styling
class SettingsCheckboxTile extends StatelessWidget {
  final String title;
  final String? subtitle;
  final bool value;
  final ValueChanged<bool?>? onChanged;

  const SettingsCheckboxTile({
    Key? key,
    required this.title,
    this.subtitle,
    required this.value,
    required this.onChanged,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CheckboxListTile(
      title: Text(title),
      subtitle: subtitle != null ? Text(subtitle!) : null,
      value: value,
      onChanged: onChanged,
      controlAffinity: ListTileControlAffinity.leading,
    );
  }
}

// SWITCH ROW (Title + Description + Switch)
// =============================

// Row with title, description, and switch on the right
class SettingsSwitchRow extends StatelessWidget {
  final String title;
  final String? description;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool isSubtitle;

  const SettingsSwitchRow({
    Key? key,
    required this.title,
    this.description,
    required this.value,
    required this.onChanged,
    this.isSubtitle = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            // Use subtitle style or normal title style
            if (isSubtitle)
              Text(
                title,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.normal,
                ),
              )
            else
              SettingsSectionTitle(text: title),
            SettingsSpacing.horizontalItem(),
            Switch(value: value, onChanged: onChanged),
          ],
        ),
        if (description != null) ...[
          SettingsSpacing.micro(),
          SettingsHelperText(text: description!, padding: EdgeInsets.zero),
        ],
      ],
    );
  }
}

// CARD SECTION
// =============================

// Card with consistent padding and styling
class SettingsCard extends StatelessWidget {
  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;

  const SettingsCard({
    Key? key,
    required this.child,
    this.color,
    this.padding,
    this.margin,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: color,
      margin: margin,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(16.0),
        child: child,
      ),
    );
  }
}

// INFO BOX (Blue background for examples/help)
// =============================

// Blue info box for examples and help text
class SettingsInfoBox extends StatelessWidget {
  final String title;
  final String content;
  final EdgeInsetsGeometry? padding;

  const SettingsInfoBox({
    Key? key,
    required this.title,
    required this.content,
    this.padding,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      color: Colors.blue.shade50,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: Colors.blue.shade900,
              ),
            ),
            const SizedBox(height: 8),
            Text(content, style: const TextStyle(color: Colors.black54)),
          ],
        ),
      ),
    );
  }
}

// BUTTON ROW
// =============================

// Row of buttons with consistent spacing
class SettingsButtonRow extends StatelessWidget {
  final List<Widget> buttons;
  final MainAxisAlignment alignment;

  const SettingsButtonRow({
    Key? key,
    required this.buttons,
    this.alignment = MainAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: alignment,
      children: [
        for (int i = 0; i < buttons.length; i++) ...[
          buttons[i],
          if (i < buttons.length - 1) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

// TITLE WITH HELPER TEXT (configurable spacing)
// =============================

// Section title with helper text underneath
class SettingsTitleWithHelper extends StatelessWidget {
  final String title;
  final String helperText;
  final double helperFontSize;
  final double spacing; // Spacing between title and helper

  const SettingsTitleWithHelper({
    Key? key,
    required this.title,
    required this.helperText,
    this.helperFontSize = 14.0,
    this.spacing = 0.0, // Default: no spacing
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SettingsSectionTitle(text: title),
        if (spacing > 0) SizedBox(height: spacing),
        // Use custom Text widget for larger font size if needed
        Text(
          helperText,
          style: TextStyle(fontSize: helperFontSize, color: Colors.grey[600]),
        ),
      ],
    );
  }
}

// TITLE WITH INLINE VALUE (Title on left, value on right in same row)
// =============================

// Section title with value displayed inline on the same row (Title and helper text stacked on mobile)
// Optional helper text below the row
class SettingsTitleWithValue extends StatelessWidget {
  final String title;
  final String value;
  final String? helperText;
  final bool isLoading;
  final TextStyle? valueStyle;

  const SettingsTitleWithValue({
    Key? key,
    required this.title,
    required this.value,
    this.helperText,
    this.isLoading = false,
    this.valueStyle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;

        if (isMobile) {
          // Mobile layout: Title and helper stacked, value indented below
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SettingsSectionTitle(text: title),
              if (helperText != null) ...[
                SettingsSpacing.micro(),
                SettingsHelperText(text: helperText!, padding: EdgeInsets.zero),
              ],
              SettingsSpacing.tight(),
              if (isLoading)
                const CircularProgressIndicator()
              else
                IndentedContent(
                  child: SelectableText(
                    value,
                    style:
                        valueStyle ??
                        const TextStyle(fontSize: 16, color: Colors.blue),
                  ),
                ),
            ],
          );
        } else {
          // Desktop layout: Title and value in same row, helper below
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  SettingsSectionTitle(text: title),
                  SettingsSpacing.horizontalItem(),
                  if (isLoading)
                    const CircularProgressIndicator()
                  else
                    Expanded(
                      child: SelectableText(
                        value,
                        style:
                            valueStyle ??
                            const TextStyle(fontSize: 16, color: Colors.blue),
                      ),
                    ),
                ],
              ),
              if (helperText != null) ...[
                SettingsSpacing.micro(),
                SettingsHelperText(text: helperText!, padding: EdgeInsets.zero),
              ],
            ],
          );
        }
      },
    );
  }
}

// INDENTED CONTENT (for forms and nested widgets)
// =============================

// Indented container with 80% width constraint
// Used for forms and content that should be visually nested
class IndentedContent extends StatelessWidget {
  final Widget child;

  const IndentedContent({Key? key, required this.child}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        final leftPadding = isMobile ? 4.0 : 8.0;
        final contentWidth = constraints.maxWidth * 0.8;

        return Padding(
          padding: EdgeInsets.only(left: leftPadding),
          child: SizedBox(width: contentWidth, child: child),
        );
      },
    );
  }
}

// RESPONSIVE LAYOUT BUILDER
// =============================

// Responsive layout that applies proper padding based on screen size
class ResponsiveSettingsLayout extends StatelessWidget {
  final List<Widget> children;
  final CrossAxisAlignment crossAxisAlignment;

  const ResponsiveSettingsLayout({
    Key? key,
    required this.children,
    this.crossAxisAlignment = CrossAxisAlignment.start,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListView(padding: getResponsivePadding(context), children: children);
  }
}

// SPACING CONSTANTS
// =============================

class SettingsSpacing {
  // Vertical spacing
  static const double sectionSpacing = 32.0; // Between major sections
  static const double itemSpacing = 16.0; // Between items in a section
  static const double tightSpacing = 8.0; // Tight spacing
  static const double microSpacing = 4.0; // Very tight spacing

  // Get vertical spacing widgets
  static Widget section() => const SizedBox(height: sectionSpacing);
  static Widget item() => const SizedBox(height: itemSpacing);
  static Widget tight() => const SizedBox(height: tightSpacing);
  static Widget micro() => const SizedBox(height: microSpacing);

  // Get horizontal spacing widgets
  static Widget horizontalSection() => const SizedBox(width: sectionSpacing);
  static Widget horizontalItem() => const SizedBox(width: itemSpacing);
  static Widget horizontalTight() => const SizedBox(width: tightSpacing);
  static Widget horizontalMicro() => const SizedBox(width: microSpacing);
}
