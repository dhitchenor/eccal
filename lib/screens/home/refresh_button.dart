import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/diary_provider.dart';

class RefreshButton extends StatelessWidget {
  final VoidCallback onRefresh;

  const RefreshButton({
    Key? key,
    required this.onRefresh,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<DiaryProvider>(
      builder: (context, provider, child) {
        final isPolling = provider.isPolling;
        return IconButton(
          icon: isPolling
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.refresh),
          onPressed: isPolling ? null : onRefresh,
          tooltip: isPolling ? 'syncing'.tr() : 'refresh'.tr(),
        );
      },
    );
  }
}