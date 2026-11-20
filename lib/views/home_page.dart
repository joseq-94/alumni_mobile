import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/alumni_model.dart';
import 'widgets/section_card.dart';

class HomePage extends StatelessWidget {
  final ValueChanged<int> onSelected;
  const HomePage({super.key, required this.onSelected});
  @override
  Widget build(BuildContext context) {
    return Consumer<AlumniModel>(
      builder: (context, model, child) {
        return ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionCard(
              title: 'Welcome back',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    model.profile?.name ?? '',
                    style: Theme.of(context).textTheme.headlineMedium,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Stay connected with your alumni community. Read updates and keep your profile current.',
                  ),
                ],
              ),
            ),
            SectionCard(
              title: 'Quick links',
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  FilledButton.icon(
                    onPressed: () => onSelected(1),
                    icon: const Icon(Icons.article_outlined),
                    label: const Text('Read the feed'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => onSelected(2),
                    icon: const Icon(Icons.person_outline),
                    label: const Text('View my profile'),
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
