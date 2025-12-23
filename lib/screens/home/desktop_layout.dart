import 'package:flutter/material.dart';
import 'sidebar_toggle_button.dart';

class DesktopLayout extends StatelessWidget {
  final bool isSidebarCollapsed;
  final VoidCallback onToggleSidebar;
  final Widget mainSection;
  final Widget entriesSidebar;

  const DesktopLayout({
    Key? key,
    required this.isSidebarCollapsed,
    required this.onToggleSidebar,
    required this.mainSection,
    required this.entriesSidebar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          flex: isSidebarCollapsed ? 1 : 4,
          child: Row(
            children: [
              Expanded(child: mainSection),
              SidebarToggleButton(
                isCollapsed: isSidebarCollapsed,
                onToggle: onToggleSidebar,
              ),
            ],
          ),
        ),
        if (!isSidebarCollapsed) const VerticalDivider(width: 1),
        if (!isSidebarCollapsed)
          Expanded(
            flex: 2,
            child: entriesSidebar,
          ),
      ],
    );
  }
}