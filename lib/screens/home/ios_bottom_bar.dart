import 'package:flutter/material.dart';
import '../../utils/app_localizations.dart';

class IOSBottomBar extends StatelessWidget {
  final Widget entriesSidebar;

  const IOSBottomBar({
    Key? key,
    required this.entriesSidebar,
  }) : super(key: key);

  void _showEntriesBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.9,
        minChildSize: 0.5,
        maxChildSize: 0.9,
        builder: (context, scrollController) => Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
          ),
          child: Column(
            children: [
              Container(
                margin: const EdgeInsets.symmetric(vertical: 12),
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              Expanded(
                child: entriesSidebar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade200,
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).brightness == Brightness.dark
              ? Colors.white.withOpacity(0.1)
              : Colors.black.withOpacity(0.05),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          ElevatedButton.icon(
            onPressed: () => _showEntriesBottomSheet(context),
            icon: const Icon(Icons.list),
            label: Text('entries'.tr()),
          ),
        ],
      ),
    );
  }
}