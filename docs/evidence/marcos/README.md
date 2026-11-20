# Local API verification

20 November 2026 (Perth). Flutter 3.44.9, Dart 3.12.2 and Chrome desktop. The Flutter web app in debug API mode and the Dart assessment server ran in separate processes on loopback. Setup instructions are in the [local API guide](../../../tool/README.md).

## App and HTTP results

| Action | Observed result |
| --- | --- |
| Sign in using a fictional account | `POST /api/mobile/login` returned `200` and opened Home. |
| Open the feed and select Load more | Both feed requests returned `200`. Page 1 had 20 posts and `next_page: 2`. Page 2 had 10 posts and `next_page: null`. The 30 public IDs were unique and excluded private post 31. |
| Open the first post | `GET /api/mobile/feed/30` returned `200` and the detail screen opened. |
| Edit profile | `PATCH /api/mobile/me` returned `200`. The app showed “Profile saved.” and Home displayed the updated name. |
| Sign out | `POST /api/mobile/logout` returned `204` and the sign-in screen opened. |
| Restart the server and sign in again | The same profile ID, name and summary were returned from the persisted JSON. |

A separate HTTP check against the running server returned `401` for an unauthenticated profile request, `404` for private post 31, and `422` for a PATCH with another user's ID. The second account still returned its original profile. The same token that received `204` at logout then received `401` at `GET /me`. The automated server tests also exercised expiry with a controlled clock.

## Runtime inspection

The Dart VM debugger reported `PauseBreakpoint` in [`_saveProfile`](../../../tool/assessment_server.dart#L300) just before writing the JSON. The Flutter form showed a disabled “Saving...” button while the server was paused.

| Value | Observed |
| --- | --- |
| `current.id` | `1` |
| `name` | `API Review` |
| `bio` | `Runtime evidence profile` |
| After resuming | HTTP `200` returned the same ID, name and summary in `data`. |

## Error, correction and retest

The login regression test failed against the prototype adapter with “Live sign-in has not been connected yet.” The adapter threw before sending an HTTP request. After implementing `POST /login` and mapping its profile response, the same test passed. The browser then showed a real login request returning `200` and loading the first feed page.

## Cleanup and coverage

After the browser session closed and the Flutter web server quit, Ctrl+C stopped the Dart server with exit code `0` and the message `Assessment API stopped.`. Both local ports closed and a follow-up API connection was refused.

`flutter analyze` reported no issues, all 17 tests passed and `flutter build web` succeeded. Resizing the Chrome mobile-emulation viewport triggered a Flutter debug `ViewInsets` assertion, so the recorded browser run used desktop Chrome. A native Android device or configured emulator was unavailable for this run.
