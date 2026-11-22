\# PR 7 — Profile and Settings Testing



\## Test Environment



\- \*\*Device:\*\* Pixel 7 emulator

\- \*\*Android version:\*\* 15 (API 35)

\- \*\*Device ID:\*\* emulator-5554

\- \*\*Date:\*\* 22 November 2026

\- \*\*Testing mode:\*\* Local API

\- \*\*Application:\*\* NMTAFE Alumni Mobile



\## Manual Test Results



| Test | Actual Result | Status |

|---|---|---|

| Launch application | Application built and launched successfully on the Android emulator. | Pass |

| Login | Logged in using the admin account and Home screen appeared. | Pass |

| Profile display | Displayed the correct name, email and professional summary for the logged-in user. | Pass |

| Profile editing | Updated the name to JUAN TEST and the biography to "Testing profile editing". The application displayed "Profile saved." and showed the updated information. | Pass |

| Profile persistence | JUAN TEST remained visible on Home after restarting Flutter. | Pass |

| Theme persistence | Dark theme remained selected after restarting the application. | Pass |

| Larger text persistence | Larger text remained enabled after restarting the application. | Pass |

| Account separation | Admin displayed JUAN TEST with the updated biography. Sam displayed Sam Taylor with no summary. Switching back restored the admin profile. | Pass |

| Cancel profile editing | Unsaved changes were discarded and the original saved name and biography were restored. | Pass |

| Profile validation | Empty names and biographies exceeding 1,000 characters were rejected. | Pass |

| API error handling | Not tested. | Not tested |

| API server restart | Profile persistence after restarting the backend was not verified. | Not tested |

| Physical phone testing | Application was not tested on a physical Android device. | Not tested |



\## Automated Test Results



\- \*\*Test file:\*\* `test/profile\_settings\_test.dart`

\- \*\*Result:\*\* 4 tests passed

\- \*\*Flutter analysis:\*\* Not recorded

\- \*\*Full test suite:\*\* Not recorded



\## Screenshots



Screenshots were captured during emulator testing and saved in `docs/evidence/juan/screenshots/`.



Evidence includes:



\- Profile before editing

\- Profile after updating the name and biography

\- Updated profile information after restarting Flutter

\- Dark theme and larger text enabled

\- Separate profiles for admin and Sam Taylor



\## Testing Limitations



Testing was completed using the Pixel 7 Android emulator running Android 15.



Physical phone testing was not performed. API failure handling and profile persistence after restarting the backend were also not verified.



\## Conclusion



The completed emulator tests confirmed that Profile and Settings functionality worked as expected. Profile information could be updated and remained visible after restarting the application. Dark theme and larger text preferences were also retained.



Profile validation, Cancel functionality and account separation behaved as expected during testing.



The remaining untested scenarios are documented above and require additional verification to complete the full testing scope.

