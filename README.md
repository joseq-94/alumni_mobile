# Alumni Mobile

A simple Flutter app with Home, a read-only Feed, My Profile and Settings. It connects to the Alumni Platform Laravel API for login, profiles and public posts. Theme and text size preferences stay on the device in Hive.

## Run with Laravel

In the ALUMNI-PLATFORM project, on the mobile_app branch:

```powershell
composer install
php artisan migrate
php artisan serve --host=127.0.0.1 --port=8000
```

Use an existing platform account with a verified email address. Sign in with its email and password, not the demo alias `admin`.

From the Flutter project, with an Android phone or emulator connected (replace DEVICE_ID using `adb devices`):

```powershell
flutter pub get
adb -s DEVICE_ID reverse tcp:8000 tcp:8000
flutter run -d DEVICE_ID --dart-define=ALUMNI_ALLOW_LOCAL_HTTP=true
```

API mode is the default, using `http://127.0.0.1:8000/api/mobile`. Forwarding makes that address reach the computer from the device. Local HTTP requires the flag above and a debug build. For another server, set `--dart-define=ALUMNI_API_BASE_URL=https://your-server/api/mobile`.

The app uses the six Laravel login, logout, profile and feed endpoints. Login tokens stay in memory; sign in again after restarting the app or after the 30-minute token expiry. The server validates changes to name and bio. Without a connection, the app shows the content it saved earlier; see Offline mode.

## Offline mode

In API mode the app saves a copy of the signed-in profile, the feed pages already loaded and the posts already opened, in a Hive box on the device (`alumni_offline_cache`). If the connection drops, these saved copies are shown with the banner "You're offline. Showing saved content." Refresh when the connection returns to load current data.

- Profile changes need a connection. Offline, Save shows "You're offline. Connect to save changes." and keeps the draft.
- Signing in or restoring a saved session still needs the server, so open the app online at least once.
- Logout, a rejected session or a different account deletes the saved copies.
- To turn the cache off, run with `--dart-define=ALUMNI_OFFLINE_CACHE=false`.

## Local demo options

For the original Hive demo without a server:

```powershell
flutter run --dart-define=ALUMNI_USE_API=false
```

Demo accounts: `admin` or `sam@example.com`, password `Password1`.

The separate Dart assessment server is also available. Start `dart run tool/assessment_server.dart`, forward port 8080, and set `--dart-define=ALUMNI_API_BASE_URL=http://127.0.0.1:8080/api/mobile --dart-define=ALUMNI_ALLOW_LOCAL_HTTP=true`. Use `sam@example.com` and `Password1` in its email sign-in form. See [assessment server setup](tool/README.md).

## Checks

```powershell
flutter analyze
flutter test
```

## Code layout

- `lib/models/`: data and app state.
- `lib/services/`: Hive storage, preferences and API access.
- `lib/views/`: screens, with reusable widgets in `widgets/`.
- `lib/theme/`: shared colours and themes.
- `tool/`: local assessment server.
- `test/`: automated tests.
