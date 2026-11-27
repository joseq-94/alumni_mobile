import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';

import '../firebase_options.dart';

class NotificationService {
  static Future<void> initialise() async {
    // This first version supports Android only.
    // Chrome and other platforms continue without notifications.
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.android) {
      return;
    }

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      final messaging = FirebaseMessaging.instance;

      // Android may ask the user to allow notifications.
      final permission = await messaging.requestPermission(
        alert: true,
        badge: true,
        sound: true,
      );

      if (permission.authorizationStatus != AuthorizationStatus.authorized) {
        debugPrint('Notifications are not allowed.');
        return;
      }

      // Subscribe before registering so we receive the device identifier.
      messaging.onRegistered.listen((installationId) {
        if (kDebugMode) {
          debugPrint('Firebase installation ID: $installationId');
        }
      });

      // Foreground messages are logged for this first test.
      FirebaseMessaging.onMessage.listen((message) {
        if (kDebugMode) {
          debugPrint('Notification received: ${message.notification?.title}');
        }
      });

      await messaging.register();
      
      // Receive announcements sent to all public-feed subscribers.
      await messaging.subscribeToTopic('public_feed');

      if (kDebugMode) {
        debugPrint('Subscribed to public_feed notifications.');
      }
    } catch (error) {
      // Notification setup must not prevent the app from opening.
      debugPrint('Notification setup failed: $error');
    }
  }
}
