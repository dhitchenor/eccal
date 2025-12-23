import 'package:flutter/material.dart';
import 'refresh_button.dart';
import '../../screens/settings_screen.dart';
import '../../utils/app_localizations.dart';

class HomeAppBarActions extends StatelessWidget {
  final bool isDesktop;
  final VoidCallback onRefresh;

  const HomeAppBarActions({
    Key? key,
    required this.isDesktop,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (isDesktop) {
      // Desktop: Refresh and Settings buttons in top right
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RefreshButton(onRefresh: onRefresh),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const SettingsScreen(),
                ),
              );
            },
            tooltip: 'settings'.tr(),
          ),
        ],
      );
    } else {
      // Mobile: Refresh button and hamburger menu
      return Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          RefreshButton(onRefresh: onRefresh),
          Builder(
            builder: (context) => IconButton(
              icon: const Icon(Icons.menu),
              onPressed: () {
                Scaffold.of(context).openEndDrawer();
              },
              tooltip: 'menu'.tr(),
            ),
          ),
        ],
      );
    }
  }
}