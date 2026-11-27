import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class NotificationService {
  // The app listens to these values to display messages and open the feed.
  static final feedRequested = ValueNotifier<bool>(false);
  static final foregroundMessages = ValueNotifier<int>(0);

  static bool _started = false;

  static void requestFeed() {
    feedRequested.value = true;
  }

  static bool _isFeedMessage(RemoteMessage message) {
    return message.data['type'] == 'public_feed';
  }

  static Future<void> initialise() async {
    if (_started || kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    // These listeners are created once for the lifetime of the app.
    _started = true;

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final messaging = FirebaseMessaging.instance;

      // A notification arrives while the app is visible.
      FirebaseMessaging.onMessage.listen((message) {
        if (_isFeedMessage(message)) {
          foregroundMessages.value++;
        }
      });

      // The user taps a notification while the app is in the background.
      FirebaseMessaging.onMessageOpenedApp.listen((message) {
        if (_isFeedMessage(message)) {
          requestFeed();
        }
      });

      // The user taps a notification that starts a closed app.
      final initialMessage = await messaging.getInitialMessage();

      if (initialMessage != null && _isFeedMessage(initialMessage)) {
        requestFeed();
      }

      final permission = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (permission.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('Notifications are not allowed.');
        return;
      }

      await messaging.register();
      await messaging.subscribeToTopic('public_feed');

      if (kDebugMode) {
        debugPrint('Subscribed to public_feed notifications.');
      }
    } catch (error) {
      // Notification problems must not prevent the rest of the app working.
      debugPrint('Notification setup failed: $error');
    }
  }
}
