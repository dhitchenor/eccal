import 'package:flutter/material.dart';
import 'ios_bottom_bar.dart';

class MobileLayout extends StatelessWidget {
  final bool isIOS;
  final Future<void> Function() onRefresh;
  final Widget mainSection;
  final Widget entriesSidebar;

  const MobileLayout({
    Key? key,
    required this.isIOS,
    required this.onRefresh,
    required this.mainSection,
    required this.entriesSidebar,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Expanded(
          child: RefreshIndicator(
            onRefresh: onRefresh,
            child: mainSection,
          ),
        ),
        if (isIOS) IOSBottomBar(
          entriesSidebar: entriesSidebar,
        ),
      ],
    );
  }
}