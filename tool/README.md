# Local assessment API

Use Flutter 3.44.9 and Dart 3.12.2. From the repository root, run:

```sh
flutter pub get
dart run tool/assessment_server.dart
```

The server listens at `http://127.0.0.1:8080/api/mobile` by default. It seeds two fictional accounts, 30 public posts and one private post. In the app, sign in with sam@example.com and Password1. These accounts belong to this demo server, not Laravel. Profile edits persist in `tool/runtime/assessment.json`. Stop the server before deleting that file to reset the seed data. Each server process has its own in-memory sessions, which expire after 30 minutes.

## Android

With the server running in one terminal, start the app in another:

```sh
flutter run -d emulator-5554 \
  --dart-define=ALUMNI_USE_API=true \
  --dart-define=ALUMNI_API_BASE_URL=http://10.0.2.2:8080/api/mobile \
  --dart-define=ALUMNI_ALLOW_LOCAL_HTTP=true
```

Use the device ID from `flutter devices`. For a physical phone, connect it to the same network as the laptop. Set `ASSESSMENT_API_HOST` to the laptop's LAN IPv4 address before starting the server, and use that address in `ALUMNI_API_BASE_URL` in place of `10.0.2.2`. The host and port must be reachable from the phone. Use fictional data on a trusted development network.

For Hive mode, run `flutter run --dart-define=ALUMNI_USE_API=false`. HTTP in API mode requires a debug build, the explicit HTTP flag and a localhost or private IPv4 address. For an HTTPS endpoint that implements this contract, set the API mode and URL without the HTTP flag.

## Web

Set the exact browser origin on the server for CORS, then open the URL printed by Flutter in Chrome:

```sh
ASSESSMENT_API_WEB_ORIGIN=http://127.0.0.1:7357 dart run tool/assessment_server.dart
```

```sh
flutter run -d web-server --web-hostname=127.0.0.1 --web-port=7357 \
  --dart-define=ALUMNI_USE_API=true \
  --dart-define=ALUMNI_API_BASE_URL=http://127.0.0.1:8080/api/mobile \
  --dart-define=ALUMNI_ALLOW_LOCAL_HTTP=true
```

In PowerShell, use `$env:ASSESSMENT_API_WEB_ORIGIN = 'http://127.0.0.1:7357'` before running the server. Put the Flutter command and its options on one line. Optional server variables are `ASSESSMENT_API_HOST`, `ASSESSMENT_API_PORT` and `ASSESSMENT_API_DATA` (a path to the local JSON file). Press Ctrl+C in the server terminal to stop it.

## API contract

Routes are relative to `/api/mobile`.

| Method and route | Request and successful response |
| --- | --- |
| `POST /login` | JSON `{"login":"admin","password":"<demo password>"}`. Returns `{"token":"…","data":{…}}` with the signed-in profile. |
| `POST /logout` | Revokes the current token and returns `204`. |
| `GET /me` | Returns the current user's profile under `data`. |
| `PATCH /me` | Accepts `name` and/or `bio`, and returns the saved profile under `data`. |
| `GET /feed?page=1` | Returns up to 20 public posts under `data`, newest first, and `next_page` as an integer or `null`. |
| `GET /feed/{id}` | Returns one public post under `data`. Private and missing posts return `404`. |

Requests after login use `Authorization: Bearer <token>`. Missing, revoked and expired tokens return `401`. Invalid profile changes return `422`. Profiles contain `id`, `name`, `email`, `bio` and `picture_url`. Posts contain `id`, `title`, `body`, `author_name` and UTC ISO 8601 `created_at`.
