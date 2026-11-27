import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'models/alumni_model.dart';
import 'models/settings_model.dart';
import 'services/notification_service.dart';
import 'theme/app_theme.dart';
import 'views/app_shell.dart';
import 'views/login_page.dart';

class AlumniApp extends StatefulWidget {
  const AlumniApp({super.key});

  @override
  State<AlumniApp> createState() => _AlumniAppState();
}

class _AlumniAppState extends State<AlumniApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  final _messengerKey = GlobalKey<ScaffoldMessengerState>();

  AlumniModel? _model;
  int _feedRequest = 0;
  bool _openingFeed = false;
  bool _openingScheduled = false;

  @override
  void initState() {
    super.initState();

    NotificationService.feedRequested.addListener(_scheduleFeedOpening);
    NotificationService.foregroundMessages.addListener(_showFeedMessage);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();

    final model = context.read<AlumniModel>();

    if (!identical(model, _model)) {
      _model?.removeListener(_modelChanged);
      _model = model;
      model.addListener(_modelChanged);
    }

    // Also handles a notification received before the first screen was ready.
    _scheduleFeedOpening();
  }

  void _modelChanged() {
    if (_model?.profile == null) {
      _feedRequest = 0;
    }

    // Login or feed loading may have finished.
    _scheduleFeedOpening();
  }

  void _showFeedMessage() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      final messenger = _messengerKey.currentState;
      messenger?.hideCurrentSnackBar();
      messenger?.showSnackBar(
        SnackBar(
          content: const Text('New posts are available in the feed.'),
          action: SnackBarAction(
            label: 'View feed',
            onPressed: NotificationService.requestFeed,
          ),
        ),
      );
    });

    WidgetsBinding.instance.ensureVisualUpdate();
  }

  void _scheduleFeedOpening() {
    if (!mounted ||
        !NotificationService.feedRequested.value ||
        _openingFeed ||
        _openingScheduled) {
      return;
    }

    // Navigation must wait until Flutter finishes building the current frame.
    _openingScheduled = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _openingScheduled = false;
      if (mounted) {
        _openRequestedFeed();
      }
    });

    WidgetsBinding.instance.ensureVisualUpdate();
  }

  Future<void> _openRequestedFeed() async {
    if (_openingFeed || !NotificationService.feedRequested.value) return;

    final model = _model;
    if (model == null) return;

    // Close a post-detail screen if it is covering the main app.
    _navigatorKey.currentState?.popUntil((route) => route.isFirst);

    // Keep the request pending until login and any current loading finish.
    if (model.profile == null || model.loadingFeed) return;

    _openingFeed = true;

    try {
      await model.refreshFeed();

      if (!mounted) return;

      // An expired API token may have signed the user out during refresh.
      // Leave the request pending so it resumes after the next login.
      if (model.profile == null) return;

      NotificationService.feedRequested.value = false;

      setState(() {
        _feedRequest++;
      });
    } finally {
      _openingFeed = false;
    }
  }

  @override
  void dispose() {
    _model?.removeListener(_modelChanged);
    NotificationService.feedRequested.removeListener(_scheduleFeedOpening);
    NotificationService.foregroundMessages.removeListener(_showFeedMessage);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<SettingsModel>(
      builder: (context, settings, child) {
        return MaterialApp(
          navigatorKey: _navigatorKey,
          scaffoldMessengerKey: _messengerKey,
          title: 'Alumni',
          debugShowCheckedModeBanner: false,
          themeMode: settings.themeMode,
          theme: AppTheme.light,
          darkTheme: AppTheme.dark,
          builder: (context, child) {
            final media = MediaQuery.of(context);

            return MediaQuery(
              data: media.copyWith(
                textScaler: settings.largerText
                    ? TextScaler.linear(media.textScaler.scale(1) * 1.2)
                    : media.textScaler,
              ),
              child: child!,
            );
          },
          home: Consumer<AlumniModel>(
            builder: (context, model, child) {
              return model.profile == null
                  ? const LoginPage()
                  : AppShell(
                      key: ValueKey(model.profile!.id),
                      feedRequest: _feedRequest,
                    );
            },
          ),
        );
      },
    );
  }
}
