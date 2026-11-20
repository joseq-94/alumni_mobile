import 'package:flutter/material.dart';

class StatusMessage extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;
  const StatusMessage({super.key, required this.message, this.onRetry});
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(message, textAlign: TextAlign.center),
          if (onRetry != null)
            TextButton(onPressed: onRetry, child: const Text('Retry')),
        ],
      ),
    );
  }
}
