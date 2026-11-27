# Alumni Mobile

A Flutter app with Home, a read-only Feed, My Profile and Settings. It uses the Alumni Platform Laravel API for accounts, profiles and posts. Theme and text-size preferences are stored on the device in Hive. Android also receives Firebase notifications for new public posts.

## Choose how to run

| Mode | What you need | Sign-in |
| --- | --- | --- |
| Android phone + Laravel | Laravel running, one USB phone, VS Code phone configuration | Verified platform email and password |
| Chrome + Laravel | Laravel running, Chrome, VS Code Chrome configuration | Verified platform email and password |
| Android emulator + Laravel | Laravel running and a started emulator; use the terminal command below | Verified platform email and password |
| Hive demo | Flutter only; no Laravel connection needed for demo data | `admin` or `sam@example.com`, password `Password1` |
| Separate Dart demo API | The server in `tool/`; no Laravel needed | `sam@example.com`, password `Password1` |

Commands below use PowerShell. Run Flutter commands from this repository's root, where `pubspec.yaml` is located. Run Laravel commands from the separate ALUMNI-PLATFORM repository.

## First-time Flutter setup

Install:

- Flutter with Dart 3.12.2 or a compatible later 3.x version, as required by `pubspec.yaml`.
- VS Code with the Flutter extension (which also installs Dart support).
- Android SDK and platform-tools for Android development, or Chrome for browser testing.
- For the Laravel project: PHP compatible with its Composer lockfile, Composer, Node.js/npm and its configured database. The current CI uses PHP 8.5.

Open this app folder directly in VS Code, then run:

```powershell
flutter --version
flutter doctor
flutter pub get
flutter devices
```

Resolve the relevant Android or Chrome issues reported by `flutter doctor`. If Android licences are missing:

```powershell
flutter doctor --android-licenses
```

For a physical Android phone, enable Developer options and USB debugging, connect a data-capable USB cable, and accept the computer-authorisation prompt on the phone.

## First-time Laravel setup

Use a checkout containing the mobile API and notification changes. In the platform repository:

```powershell
composer install
npm install
```

If `.env` does not exist, copy the example and generate the application key:

```powershell
if (!(Test-Path .env)) {
    Copy-Item .env.example .env
    php artisan key:generate
}
```

Edit `.env` for your local database and make sure that database is available. Then run:

```powershell
php artisan config:clear
php artisan migrate
```

Review pending migrations before applying them to an existing shared database. These migrations include the Sanctum token and queue tables.

Use an existing verified platform account, or register and complete email verification through the website using the platform's configured mail setup. The mobile API accepts an email, not the demo username `admin`. Hive demo accounts are not automatically created in Laravel.

Start the platform:

```powershell
composer run dev
```

Keep this terminal running. This starts Laravel on port 8000, the queue listener and the website asset server. Firebase sending is optional; leave `FIREBASE_NOTIFICATIONS_ENABLED=false` until its credentials are configured below.

## Everyday use: Android phone in VS Code

1. Start `composer run dev` in the Laravel project.
2. Connect one authorised Android USB phone.
3. Open the Flutter project in VS Code and select the phone using the device selector in the status bar.
4. Open **Run and Debug** with **Ctrl+Shift+D**.
5. Select **Flutter - local Laravel API** from the dropdown beside the green run button.
6. Press **F5** and sign in with a verified platform account.

The project configuration supplies the API flags and automatically runs `adb -d reverse tcp:8000 tcp:8000`. This connects the phone's local port 8000 to Laravel on the computer. No manual forwarding command is needed for this launch configuration.

The task expects exactly one USB Android device. On Windows it uses `%LOCALAPPDATA%\Android\sdk\platform-tools\adb.exe`. If your SDK is elsewhere, adjust the Windows command in `.vscode/tasks.json`. On macOS/Linux, `adb` must be on PATH. The Flutter launch uses the device selected in VS Code, so select the same USB phone.

These files affect only this project, not global VS Code settings.

## Everyday use: Chrome in VS Code

1. Keep `composer run dev` running in the Laravel project.
2. Open **Run and Debug** in the Flutter project.
3. Select **Flutter - Chrome + Laravel** and press **F5**.

Chrome opens at `http://127.0.0.1:7357` and calls `http://127.0.0.1:8000/api/mobile`. It does not use USB forwarding.

Laravel's `config/cors.php` must allow the exact origin `http://127.0.0.1:7357` for `api/mobile/*`, methods GET/POST/PATCH/OPTIONS, and Accept/Authorization/Content-Type headers. The platform changes already include this. Do not switch to `localhost` or a different browser port without updating CORS too.

Push notifications are currently Android-only. Chrome still supports login, feed, profiles and device preferences.

## Terminal alternatives

Stop any existing debug session first. Replace `DEVICE_ID` with the ID from `flutter devices` or `adb devices`.

### USB Android phone

If `adb` is not on PATH, use the default Windows SDK location:

```powershell
$adbPath = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"
& $adbPath devices
& $adbPath -s DEVICE_ID reverse tcp:8000 tcp:8000
flutter run --debug -d DEVICE_ID --dart-define=ALUMNI_USE_API=true --dart-define=ALUMNI_API_BASE_URL=http://127.0.0.1:8000/api/mobile --dart-define=ALUMNI_ALLOW_LOCAL_HTTP=true
```

Run forwarding again after disconnecting/reconnecting the phone if necessary.

### Android emulator

Start an emulator first, then run:

```powershell
flutter devices
flutter run --debug -d EMULATOR_ID --dart-define=ALUMNI_USE_API=true --dart-define=ALUMNI_API_BASE_URL=http://10.0.2.2:8000/api/mobile --dart-define=ALUMNI_ALLOW_LOCAL_HTTP=true
```

Replace `EMULATOR_ID` with its listed ID. `10.0.2.2` reaches the computer from the standard Android emulator, without USB forwarding. For Firebase testing, use an emulator image with Google Play services; the physical phone is the demonstrated setup.

### Chrome

```powershell
flutter run --debug -d chrome --web-hostname=127.0.0.1 --web-port=7357 --dart-define=ALUMNI_USE_API=true --dart-define=ALUMNI_API_BASE_URL=http://127.0.0.1:8000/api/mobile --dart-define=ALUMNI_ALLOW_LOCAL_HTTP=true
```

### Hive demo, without Laravel

```powershell
flutter run --debug -d DEVICE_ID --dart-define=ALUMNI_USE_API=false
```

Use `chrome` instead of `DEVICE_ID` to run the demo in Chrome. Sign in with `admin` or `sam@example.com`; both use `Password1`.

Profiles and fictional posts stay in local Hive storage. Edits persist locally and do not affect Laravel. The demo data works without internet, but notification setup is still attempted on Android because it runs independently of the data-source choice. Notifications need internet and do not synchronise Laravel posts into the demo feed. Deny notification permission if you do not want alerts during a demo.

To return to Laravel, stop this run and use either saved API debug configuration. Both explicitly enable API mode.

### Separate Dart assessment server

This is an alternative to Laravel. In one Flutter-project terminal:

```powershell
dart run tool/assessment_server.dart
```

In another, for a USB phone:

```powershell
$adbPath = "$env:LOCALAPPDATA\Android\sdk\platform-tools\adb.exe"
& $adbPath -s DEVICE_ID reverse tcp:8080 tcp:8080
flutter run --debug -d DEVICE_ID --dart-define=ALUMNI_USE_API=true --dart-define=ALUMNI_API_BASE_URL=http://127.0.0.1:8080/api/mobile --dart-define=ALUMNI_ALLOW_LOCAL_HTTP=true
```

Use `sam@example.com` and `Password1`. This server stores fictional data in `tool/runtime/assessment.json`; it does not send Laravel new-post notifications. See [the assessment server instructions](tool/README.md) for its Chrome/CORS and Wi-Fi options.

## Firebase notifications

### App setup

The repository already includes `lib/firebase_options.dart`, `android/app/google-services.json` and `firebase.json`. Teammates using the same Firebase project do not need to run FlutterFire configuration again.

On Android, allow notifications when prompted. A successful setup prints `Subscribed to public_feed notifications.` in the Debug Console. If permission was denied, enable it in Android's app notification settings and restart the app.

If deliberately connecting the app to a different Firebase project, install the setup tools and configure Android again:

```powershell
npm install -g firebase-tools
firebase login
dart pub global activate flutterfire_cli
$env:Path += ";$env:LOCALAPPDATA\Pub\Cache\bin"
flutterfire configure --platforms=android --android-package-name=com.example.alumni_mobile
```

Select the intended project and review the generated changes before committing. The Laravel sender must use that same project.

### Laravel sending setup

In the same project's [Firebase Console](https://console.firebase.google.com/), open **Project settings → Service accounts** and generate a private key. Store the downloaded JSON outside both repositories. It belongs only on the server/computer running Laravel, never in Flutter or Git.

In Laravel's local `.env`, set your own values:

```dotenv
FIREBASE_NOTIFICATIONS_ENABLED=true
FIREBASE_PROJECT_ID=your-project-id
FIREBASE_CREDENTIALS="C:/Users/YOUR_NAME/.firebase/alumni-service-account.json"
QUEUE_CONNECTION=database
```

The Firebase Cloud Messaging API must be enabled for the project, and the service account needs permission to send messages. Then run `php artisan config:clear` and restart `composer run dev`.

Client Firebase configuration files are not the server's private service-account key. Never commit `.env`, the private key, or copied device identifiers. Tests keep real Firebase sending disabled; do not enable it in CI to make a notification test work.

### Check the full notification flow

1. Run the Android app and confirm the subscription message.
2. Put the app in the background using the phone's Home button.
3. Create a new **public post** on the Laravel website.
4. Tap the received notification. The Feed should open and refresh; sign in first if asked.
5. Repeat with the app visible: use the **View feed** action in the in-app message.
6. A private post or editing an existing post should not send an announcement.

For a direct sending check, run `php artisan tinker` in Laravel, then:

```php
app(\App\Services\FeedNotificationService::class)->send();
```

All subscribed installations receive generic announcements, including the author and logged-out users. This is a shared topic, not a private per-user subscription. The app handles feed actions only when the message contains `data.type = public_feed`, which the Laravel sender includes.

Both Laravel and the phone need internet to use Firebase. The phone also needs access to the API when loading the Feed. An app that was closed can open from a notification; Android Force stop is different and requires manually reopening the app before expecting delivery again. Battery restrictions and delivery delays can also affect testing.

## Configuration and stored data

| Build setting | Default | Purpose |
| --- | --- | --- |
| `ALUMNI_USE_API` | `true` | Use Laravel/API data; `false` selects the Hive demo. |
| `ALUMNI_API_BASE_URL` | `http://127.0.0.1:8000/api/mobile` | Root address for the six mobile endpoints. |
| `ALUMNI_ALLOW_LOCAL_HTTP` | `false` | Permit local HTTP only when the app is also a debug build. |

Both saved API launch configurations supply the HTTP flag. Plain `flutter run` uses the HTTP URL without permission and will report that the API address must use HTTPS. Use one of the documented launch configurations or commands.

Build-setting changes require stopping and restarting the app; hot reload is not enough. In release builds, use a reachable HTTPS API address. Neither the USB forwarding task nor a locally running server is a deployment setup.

In API mode, profiles and posts live in Laravel; only loaded copies and the login token are held in app memory. Tokens expire after 30 minutes, and restarting the app requires login. Device theme/text preferences stay in Hive and survive logout. There is no persistent offline API-feed cache or automatic fallback to demo mode. Firebase topic subscription is independent of login-token expiry.

## Troubleshooting

| Problem | What to check |
| --- | --- |
| The API address must use HTTPS | Use the saved API launch configuration or include `ALUMNI_ALLOW_LOCAL_HTTP=true` in a debug run. Fully stop and restart. |
| Phone cannot connect | Laravel must be on port 8000. Check USB authorisation, device selection and forwarding. On a phone, 127.0.0.1 reaches Laravel only after forwarding. |
| Pre-launch task says no devices / more than one device | Connect and authorise exactly one USB phone, or use the terminal command with an explicit device ID. |
| adb executable not found | Adjust `.vscode/tasks.json` for your SDK path, or use the full platform-tools path in PowerShell. |
| Chrome cannot connect / CORS error | Use the fixed origin 127.0.0.1:7357, verify Laravel CORS configuration, and clear Laravel's config cache after changes. |
| Login rejected | Use a verified platform email/password in API mode. Demo credentials work only with demo data. |
| Too many login attempts | Wait a minute before retrying; Laravel limits login requests. |
| Notifications do not arrive | Check Android permission, internet, subscription output, matching Firebase projects, Laravel credentials and the running queue listener. |
| Notification arrives but does not open Feed | Test a Laravel-generated message containing `data.type = public_feed`, not a console test missing that field. |
| Firebase reports installation-ID API disabled | The Android application manifest must contain `firebase_messaging_installation_id_enabled` set to `true`; it is already included. Rebuild after native configuration changes. |
| Direct sending works but new posts do not notify | Check `php artisan queue:failed` and the queue terminal. The current dev listener uses one attempt. After fixing the cause, retry a specific failed job with `php artisan queue:retry JOB_ID`. |
| Website reports missing Vite manifest | Keep `composer run dev` running for website assets, or run `npm run build` in Laravel. |

If setup failed, the app prints `Notification setup failed: ...`. Fix the cause and restart: notification initialisation runs once per app process.

## Checks before committing

In Flutter:

```powershell
flutter analyze
flutter test
git diff --check
git status --short
```

For notification work, also manually check foreground, background and closed-app taps, including sign-in after token expiry. Automated Flutter tests do not prove real Firebase delivery.

In Laravel, the focused notification/post checks are:

```powershell
php artisan test tests/Feature/FeedNotificationTest.php tests/Feature/PostControllerTest.php
```

## Code layout

- `lib/main.dart`: app startup, data-source choice and notification startup.
- `lib/app.dart`: theme, login screen and notification navigation.
- `lib/models/`: data objects and shared app state.
- `lib/services/`: API access, Hive storage, preferences and Firebase messaging.
- `lib/views/`: screens, with reusable widgets in `widgets/`.
- `lib/theme/`: shared colours and themes.
- `.vscode/`: project-only phone/Chrome debug settings.
- `tool/`: optional standalone assessment server.
- `test/`: automated tests.
