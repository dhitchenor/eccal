import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/diary_provider.dart';
import '../../utils/app_localizations.dart';

class RefreshButton extends StatefulWidget {
  final VoidCallback onRefresh;

  const RefreshButton({Key? key, required this.onRefresh}) : super(key: key);

  @override
  State<RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<RefreshButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 1000),
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<DiaryProvider>(
      builder: (context, provider, child) {
        // Checks isLoading (local storage) AND isPolling (CalDAV sync)
        final isRefreshing = provider.isLoading || provider.isPolling;

        // Use addPostFrameCallback to avoid changing animation during build
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) {
            if (isRefreshing && !_controller.isAnimating) {
              _controller.repeat();
            } else if (!isRefreshing && _controller.isAnimating) {
              _controller.stop();
              _controller.reset();
            }
          }
        });

        return IconButton(
          icon: RotationTransition(
            turns: _controller,
            child: const Icon(Icons.refresh),
          ),
          onPressed: isRefreshing ? null : widget.onRefresh,
          tooltip: isRefreshing ? 'syncing'.tr() : 'refresh'.tr(),
        );
      },
    );
  }
}
