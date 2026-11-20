import 'package:flutter/material.dart';
import 'widgets/profile_form.dart';
import 'widgets/app_settings_card.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key});
  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage>
    with AutomaticKeepAliveClientMixin {
  // Keep the same form when switching tabs or rotating the device.
  final _profileKey = GlobalKey();
  @override
  bool get wantKeepAlive => true;
  @override
  Widget build(BuildContext context) {
    super.build(context);
    return LayoutBuilder(
      builder: (context, constraints) {
        final profileForm = ProfileForm(key: _profileKey);
        return SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: constraints.maxWidth >= 700
              ? Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: profileForm),
                    const SizedBox(width: 20),
                    const Expanded(child: AppSettingsCard()),
                  ],
                )
              : Column(children: [profileForm, const AppSettingsCard()]),
        );
      },
    );
  }
}
