# AGENTS.md — Grand Elephants Flutter

Guidance for AI coding agents working in this repository.

## Commands

- `flutter analyze` — MUST be clean (0 issues) before finishing any task
- `flutter test` — run the model/unit tests
- `flutter build web --release` — build the website
- `flutter build apk --release` / `flutter build appbundle --release` — Android builds
- `flutter pub get` / `flutter pub add <pkg>` — dependencies

## Conventions

- **No simulated features.** Every screen must read/write real data through a
  provider that calls `ApiClient`. If a backend endpoint is missing, add it in
  the `grand-elephants-api` repo — do NOT fake it here.
- **Server is the source of truth** for orders, prices, payment status. Client
  computes estimates only for display (delivery fee preview); the server
  returns final totals.
- **Role checks server-side.** Client guards are UX only — never use them to
  gate sensitive data.
- Money is displayed in ZMW (K) via `ConfigProvider.formatPrice`. Internally the
  API deals in cents; models carry both `price` and `priceCents`.
- Keep the soft UI system consistent: `SoftCard`, `SoftButton`, `SoftInput`,
  `ToastProvider`, `AppColors`. Do not invent a second design language.
- Use `context.read` for actions, `context.watch` for reactive reads.
- After editing, run `flutter analyze` and fix everything you introduced.

## State providers (all real API-backed)

| provider | purpose |
|---|---|
| `AuthProvider` | session, OTP, profile, 60-min inactivity logout |
| `CatalogProvider` | products, categories, banners, search |
| `CartProvider` | cart + orders + checkout |
| `ConfigProvider` | branding, categories, tax rate, currency |
| `NotificationProvider` | user notifications (server) |
| `WishlistProvider` | wishlist (local) |
| `RiderProvider` | rider profile, deliveries, payouts, location |
| `AdminProvider` | admin stats, users, fleet, payouts, Lipila wallet |
| `AppDataProvider` | addresses + support chat |
| `CollectionNumberProvider` | business mobile-money numbers |

Register new providers in `lib/main.dart` `MultiProvider`.

## Backend contract

Base URL: `https://grand-elephants-api.godfreymoseskalambo.workers.dev`
(default; override at build time with `--dart-define=API_BASE_URL=...`).

`ApiClient` auto-attaches `Authorization: Bearer <token>` (from
`flutter_secure_storage`). Public catalog calls pass `withAuth: false`.

## Branding & platform (do not regress)

- Product name is **Grand Elephants** everywhere: `AppConfig.appName`,
  `MaterialApp.title`, web `<title>`/`manifest.json`, Android label, SMS brand
  prefix (`GRANDELEPHANTS:`). The old `sell_on_app` / "Sell On App" naming is
  retired — never reintroduce it (the Dart package is `grand_elephants`).
- Logo asset: `assets/images/grandelephants_icon.jpg` (used by `lib/widgets/logo.dart`).
- Android: applicationId/namespace `com.grandelephants.shop`; MainActivity lives
  at `android/app/src/main/kotlin/com/grandelephants/shop/MainActivity.kt`.
- Firebase FCM is wired: `firebase_core` + `firebase_messaging`, the device
  token is sent with `verifyOtp` so the worker can push notifications.
- SMS is sent server-side only (Africa's Talking, production) — the app never
  sends SMS itself.

## Repository layout

- `lib/main.dart` — provider wiring, routes, admin role guards
- `lib/constants/` — `AppConfig` (API base URL), `AppTheme`
- `lib/services/` — `ApiClient`, `StorageService`
- `lib/providers/` — state
- `lib/screens/` — features by role/area
- `lib/widgets/` — reusable UI
- `lib/models/` — entities
- `test/` — model tests

## Deployment

Website = `flutter build web --release`; the worker serves `build/web`. Run the
deploy script from the `grand-elephants-api` repo.