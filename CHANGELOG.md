# Changelog — Grand Elephants Flutter

All notable changes to the Grand Elephants app. Format:
[Keep a Changelog](https://keepachangelog.com/).

## [Unreleased] — 2026-09-24

### Added
- Real-data rewiring: every previously simulated screen now reads/writes the
  real API (rider, 13 admin screens, 6 profile screens, scanner, try-on,
  delivery camera, order tracking, receipt, employee, business, support chat).
- Providers: `RiderProvider`, `AdminProvider`, `AppDataProvider`;
  `NotificationProvider` rewritten against the server; providers registered in
  `lib/main.dart`.
- Role-based tabs/navigation for user, rider, business, employee, admin and
  superadmin (`lib/screens/home/home_shell.dart`); admin route guards in
  `main.dart` `onGenerateRoute`; missing routes added (`/explore`,
  `/rider/apply`, `/business/dashboard`, `/support/chat`).
- Hosted PMTiles map (`lib/widgets/hosted_map.dart` →
  `https://maps.churchonapp.com/zambia.pmtiles`, OSM fallback) on order
  tracking.
- Android permissions: INTERNET, CAMERA, location.
- Firebase Cloud Messaging: `firebase_core` + `firebase_messaging`,
  `google-services.json` (project `grand-elephants-b8ec4`), device token sent
  with `verifyOtp`.
- Android packaging: INTERNET/CAMERA/location permissions + app label.

### Changed
- **Rebrand to Grand Elephants**: Dart package `sell_on_app` → `grand_elephants`
  (61 files), `AppConfig.appName`, `MaterialApp.title`, web `<title>`
  (`grandelephants`), PWA name/description, Android label, logo
  (`assets/images/grandelephants_icon.jpg`) — no `sell_on_app` /
  "Sell On App" references remain in lib/test/web/android.
- Android applicationId/namespace → `com.grandelephants.shop`; MainActivity
  moved to `com/grandelephants/shop/`; google-services gradle plugin added.
- Session timer now actually logs out after 60 minutes of inactivity.
- Price display prefers `priceCents` (fixes `inStock`/rounding audit bugs).
- `README.md`, `AGENTS.md`, `BLUEPRINT.md` rewritten for Grand Elephants.

### Removed
- Dead code: `database_service.dart`, `tracking_service.dart`,
  `lipila_payment_service.dart`.

### Fixed
- Comprehensive audit fixes: security hardening, code quality, UI/UX polish,
  tests (analyze 0 issues, 13/13 tests pass).
- Checkout/ordering/fulfillment against production Lipila (server-side money).

### Build
- Release APK (`com.grandelephants.shop`, label "Grand Elephants") and AAB
  built and uploaded to R2:
  `https://media.churchonapp.com/grand-elephants/grand-elephants.apk` /
  `.aab`.
- Website: `flutter build web --release`, served by the worker.
