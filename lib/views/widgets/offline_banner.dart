import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../services/offline_cache_datasource.dart';

// Shown while the screens display data saved on this device. Without an
// OfflineStatus provider (Hive demo mode, tests) it shows nothing.
class OfflineBanner extends StatelessWidget {
  const OfflineBanner({super.key});

  static const message = "You're offline. Showing saved content.";

  @override
  Widget build(BuildContext context) {
    final offline =
        Provider.of<OfflineStatus?>(context)?.showingSavedData ?? false;
    if (!offline) return const SizedBox.shrink();
    final colors = Theme.of(context).colorScheme;
    return Semantics(
      liveRegion: true,
      child: Material(
        color: colors.secondaryContainer,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              Icon(
                Icons.cloud_off,
                size: 20,
                color: colors.onSecondaryContainer,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  message,
                  style: TextStyle(color: colors.onSecondaryContainer),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
