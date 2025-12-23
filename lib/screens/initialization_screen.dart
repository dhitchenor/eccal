import 'package:flutter/material.dart';

class InitializationScreen extends StatelessWidget {
  final String? message;
  final bool showError;
  final String? errorMessage;
  final VoidCallback? onRetry;

  const InitializationScreen({
    Key? key,
    this.message,
    this.showError = false,
    this.errorMessage,
    this.onRetry,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    // Get screen dimensions and use smaller value for responsive sizing
    final screenSize = MediaQuery.of(context).size;
    final smallerDimension = screenSize.width < screenSize.height
        ? screenSize.width
        : screenSize.height;

    // Logo size is 20% of smaller dimension, clamped between 80-200
    final logoSize = (smallerDimension * 0.2).clamp(80.0, 200.0);

    return Scaffold(
      backgroundColor: const Color(0xFF241e49), // Logo background color
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Animated app logo from assets - responsive size
            Image.asset(
              'assets/icon/app_icon.gif',
              width: logoSize,
              height: logoSize,
            ),
            const SizedBox(height: 8),
            const Text(
              'EcCal',
              style: TextStyle(
                fontSize: 32,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 16),

            if (showError) ...[
              // Error state
              const Icon(
                Icons.error_outline,
                size: 48,
                color: Colors.redAccent,
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  errorMessage ?? 'An error occurred',
                  textAlign: TextAlign.center,
                  style: const TextStyle(fontSize: 16, color: Colors.redAccent),
                ),
              ),
              if (onRetry != null) ...[
                const SizedBox(height: 24),
                ElevatedButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: const Color(0xFF241e49),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 32,
                      vertical: 16,
                    ),
                  ),
                ),
              ],
            ] else ...[
              // Loading state - just show message (animation is in logo)
              const SizedBox(height: 8),
              Text(
                message ?? 'Loading...',
                style: const TextStyle(fontSize: 16, color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
