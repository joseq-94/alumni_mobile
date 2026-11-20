import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alumni_model.dart';
import 'widgets/profile_header.dart';
import 'widgets/section_card.dart';

class ProfilePage extends StatelessWidget {
  final VoidCallback onEdit;
  const ProfilePage({super.key, required this.onEdit});
  @override
  Widget build(BuildContext context) {
    return Consumer<AlumniModel>(
      builder: (context, model, child) {
        final profile = model.profile;
        if (profile == null) return const SizedBox.shrink();
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionCard(
              title: 'My profile',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  ProfileHeader(profile: profile),
                  const SizedBox(height: 24),
                  Text(
                    'Professional summary',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(profile.bio.isEmpty ? 'No summary yet' : profile.bio),
                  const SizedBox(height: 24),
                  OutlinedButton(
                    onPressed: onEdit,
                    child: const Text('Edit profile'),
                  ),
                ],
              ),
            ),
          ],
        );
      },
    );
  }
}
