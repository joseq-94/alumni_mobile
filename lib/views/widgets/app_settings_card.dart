import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/alumni_model.dart';
import '../../models/settings_model.dart';
import 'section_card.dart';
import 'status_message.dart';

// Save device preferences through SettingsModel; logout uses AlumniModel.
class AppSettingsCard extends StatelessWidget {
  const AppSettingsCard({super.key});
  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsModel>(
      builder: (context, settings, child) {
        return SectionCard(
          title: 'App preferences',
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              DropdownButtonFormField<String>(
                initialValue: settings.theme,
                key: ValueKey(settings.theme),
                decoration: const InputDecoration(labelText: 'Theme'),
                items: ['System', 'Light', 'Dark']
                    .map(
                      (theme) =>
                          DropdownMenuItem(value: theme, child: Text(theme)),
                    )
                    .toList(),
                onChanged: settings.saving
                    ? null
                    : (value) {
                        if (value != null) {
                          settings.update(value, settings.largerText);
                        }
                      },
              ),
              const SizedBox(height: 12),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Larger text'),
                subtitle: const Text('Make text easier to read'),
                value: settings.largerText,
                onChanged: settings.saving
                    ? null
                    : (value) => settings.update(settings.theme, value),
              ),
              const SizedBox(height: 8),
              const Text('Saved automatically on this device.'),
              if (settings.error != null)
                StatusMessage(message: settings.error!),
              const SizedBox(height: 24),
              OutlinedButton.icon(
                onPressed: () =>
                    Provider.of<AlumniModel>(context, listen: false).signOut(),
                icon: const Icon(Icons.logout),
                label: const Text('Sign out'),
              ),
            ],
          ),
        );
      },
    );
  }
}
