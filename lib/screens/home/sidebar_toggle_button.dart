import 'package:flutter/material.dart';

class SidebarToggleButton extends StatelessWidget {
  final bool isCollapsed;
  final VoidCallback onToggle;

  const SidebarToggleButton({
    Key? key,
    required this.isCollapsed,
    required this.onToggle,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Center(
      child: InkWell(
        onTap: onToggle,
        child: Container(
          width: 20,
          height: 60,
          decoration: BoxDecoration(
            color: Colors.grey.shade100,
            border: Border.all(color: Colors.grey.shade300, width: 1),
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(8),
              bottomLeft: Radius.circular(8),
            ),
            boxShadow: [
              BoxShadow(
                color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white.withOpacity(0.1)
                  : Colors.black.withOpacity(0.05),
                blurRadius: 4,
                offset: const Offset(-2, 0),
              ),
            ],
          ),
          child: Icon(
            isCollapsed ? Icons.chevron_left : Icons.chevron_right,
            size: 16,
            color: Colors.grey.shade700,
          ),
        ),
      ),
    );
  }
}