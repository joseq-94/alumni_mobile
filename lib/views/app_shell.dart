import 'package:flutter/material.dart';
import 'home_page.dart';
import 'feed_page.dart';
import 'profile_page.dart';
import 'settings_page.dart';
import 'widgets/app_navigation.dart';

// The signed-in layout: four pages with bottom navigation or a side rail.
class AppShell extends StatefulWidget {
  const AppShell({super.key});
  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  final _controller = PageController();
  int _index = 0;
  void _select(int index) {
    FocusScope.of(context).unfocus();
    _controller.jumpToPage(index);
    setState(() => _index = index);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Use available width, so this also adapts when a phone rotates.
    final wide = MediaQuery.sizeOf(context).width >= 600;
    return Scaffold(
      appBar: AppBar(
        title: Text(['Home', 'Feed', 'My Profile', 'Settings'][_index]),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: Text(
              'ALUMNI',
              style: TextStyle(
                color: Theme.of(context).colorScheme.primary,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: Row(
          children: [
            if (wide)
              AppNavigation(
                wide: true,
                selectedIndex: _index,
                onSelected: _select,
              ),
            Expanded(
              child: PageView(
                controller: _controller,
                onPageChanged: (index) => setState(() => _index = index),
                children: [
                  HomePage(onSelected: _select),
                  const FeedPageView(),
                  ProfilePage(onEdit: () => _select(3)),
                  const SettingsPage(),
                ],
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: wide
          ? null
          : AppNavigation(
              wide: false,
              selectedIndex: _index,
              onSelected: _select,
            ),
    );
  }
}
