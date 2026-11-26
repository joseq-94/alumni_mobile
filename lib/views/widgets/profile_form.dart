import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../models/alumni_model.dart';
import '../../models/user_profile.dart';
import 'section_card.dart';
import 'status_message.dart';

// Keep edits in text controllers until Save; Cancel restores the shared saved profile.
class ProfileForm extends StatefulWidget {
  const ProfileForm({super.key});
  @override
  State<ProfileForm> createState() => _ProfileFormState();
}

class _ProfileFormState extends State<ProfileForm> {
  final _formKey = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _bio = TextEditingController();
  @override
  void initState() {
    super.initState();
    _reset();
  }

  void _reset() {
    final profile = Provider.of<AlumniModel>(context, listen: false).profile!;
    _formKey.currentState?.reset();
    _name.text = profile.name;
    _bio.text = profile.bio;
  }

  Future<void> _save() async {
    // Check input locally first; Laravel validates it again before saving.
    if (!_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    final model = Provider.of<AlumniModel>(context, listen: false);
    final saved = await model.saveProfile(_name.text, _bio.text);
    if (!mounted || !saved) return;
    _reset();
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
  }

  @override
  void dispose() {
    _name.dispose();
    _bio.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<AlumniModel>(
      builder: (context, model, child) {
        return SectionCard(
          title: 'Profile settings',
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                TextFormField(
                  controller: _name,
                  enabled: !model.savingProfile,
                  validator: UserProfile.validateName,
                  decoration: const InputDecoration(labelText: 'Name'),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _bio,
                  enabled: !model.savingProfile,
                  validator: UserProfile.validateBio,
                  minLines: 3,
                  maxLines: 6,
                  decoration: const InputDecoration(
                    labelText: 'Professional summary',
                  ),
                ),
                const SizedBox(height: 12),
                Text('Email: ${model.profile?.email ?? ''}'),
                const SizedBox(height: 4),
                const Text(
                  'Email and profile picture are managed on the website.',
                ),
                if (model.profileError != null)
                  StatusMessage(message: model.profileError!),
                const SizedBox(height: 16),
                Wrap(
                  spacing: 12,
                  children: [
                    FilledButton(
                      onPressed: model.savingProfile ? null : _save,
                      child: Text(model.savingProfile ? 'Saving...' : 'Save'),
                    ),
                    OutlinedButton(
                      onPressed: model.savingProfile ? null : _reset,
                      child: const Text('Cancel'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
