# Alumni Mobile

A simple Flutter app with Home, a read-only Feed, My Profile and Settings. Users can sign in, read posts, edit their name and biography, and change the theme and text size.

The app uses fictional data. It does not connect to the live Alumni platform or its database as the real platfrom is yet to be deployed.

## Run the app

Use Flutter 3.44.9 / Dart 3.12.2 and an Android device or emulator.

```powershell
flutter pub get
flutter run
```

This starts Hive mode. Profiles, posts and device preferences are stored locally.

Demo accounts: `admin` or `sam@example.com`. Both use `Password1`.

## Run with the local API

Start the server in a separate terminal from the project folder:

```powershell
dart run tool/assessment_server.dart
```

For a USB-connected Android phone, enable USB debugging, authorise the computer, and replace DEVICE_ID with the ID from `adb devices`:

```powershell
adb -s DEVICE_ID reverse tcp:8080 tcp:8080
flutter run -d DEVICE_ID --dart-define=ALUMNI_USE_API=true --dart-define=ALUMNI_API_BASE_URL=http://127.0.0.1:8080/api/mobile --dart-define=ALUMNI_ALLOW_LOCAL_HTTP=true
```

In API mode, the separate Dart server handles login, profiles and posts. It saves fictional records in `tool/runtime/assessment.json`; device preferences still use Hive. Restarting the server requires signing in again.

See [API setup](tool/README.md) for emulator, Wi-Fi and web instructions. Local HTTP is enabled only for the debug demonstration.

## Code layout

- `lib/models/`: data and app state.
- `lib/services/`: Hive storage, preferences and API access.
- `lib/views/`: screens, with reusable widgets in `widgets/`.
- `lib/theme/`: shared colours and themes.
- `tool/`: local assessment server.
- `test/`: automated tests.
