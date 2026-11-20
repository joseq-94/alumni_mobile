import 'package:flutter/material.dart';

class AppNavigation extends StatelessWidget {
  final bool wide;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  const AppNavigation({
    super.key,
    required this.wide,
    required this.selectedIndex,
    required this.onSelected,
  });
  @override
  Widget build(BuildContext context) {
    if (wide) {
      return NavigationRail(
        selectedIndex: selectedIndex,
        onDestinationSelected: onSelected,
        labelType: NavigationRailLabelType.all,
        destinations: const [
          NavigationRailDestination(
            icon: Icon(Icons.home_outlined),
            label: Text('Home'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.article_outlined),
            label: Text('Feed'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.person_outline),
            label: Text('My Profile'),
          ),
          NavigationRailDestination(
            icon: Icon(Icons.settings_outlined),
            label: Text('Settings'),
          ),
        ],
      );
    }
    return NavigationBar(
      selectedIndex: selectedIndex,
      onDestinationSelected: onSelected,
      destinations: const [
        NavigationDestination(icon: Icon(Icons.home_outlined), label: 'Home'),
        NavigationDestination(
          icon: Icon(Icons.article_outlined),
          label: 'Feed',
        ),
        NavigationDestination(
          icon: Icon(Icons.person_outline),
          label: 'My Profile',
        ),
        NavigationDestination(
          icon: Icon(Icons.settings_outlined),
          label: 'Settings',
        ),
      ],
    );
  }
}
