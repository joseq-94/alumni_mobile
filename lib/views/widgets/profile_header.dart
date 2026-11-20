import 'package:flutter/material.dart';
import '../../models/user_profile.dart';
import '../../theme/app_theme.dart';

class ProfileHeader extends StatelessWidget {
  final UserProfile profile;
  const ProfileHeader({super.key, required this.profile});
  @override
  Widget build(BuildContext context) {
    final initial = profile.name.trim().isEmpty
        ? '?'
        : profile.name.trim().characters.first.toUpperCase();
    final fallback = CircleAvatar(
      radius: 30,
      backgroundColor: AppTheme.red,
      foregroundColor: Colors.white,
      child: Text(initial, style: const TextStyle(fontSize: 26)),
    );
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (profile.pictureUrl == null || profile.pictureUrl!.isEmpty)
          fallback
        else
          ClipOval(
            child: Image.network(
              profile.pictureUrl!,
              width: 60,
              height: 60,
              fit: BoxFit.cover,
              errorBuilder: (_, error, stack) => fallback,
            ),
          ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(profile.name, style: Theme.of(context).textTheme.titleLarge),
              const SizedBox(height: 4),
              Text(profile.email),
            ],
          ),
        ),
      ],
    );
  }
}
