# Changelog — Grand Elephants Flutter

All notable changes to the Grand Elephants app. Format:
[Keep a Changelog](https://keepachangelog.com/).

## [Unreleased] — 2026-09-25

### Added
- **Session persistence**: `AuthProvider.ready` Completer + splash gate +
  non-lazy provider (cold start no longer dumps users to /login); inactivity
  logout now 14 days and truly resets on touch/resume (`resetSession` wired in
  `HomeShell`); logout navigates to `/login` via global `navigatorKey`
  (no more zombie sessions).
- **Dead routes fixed**: `'/'` now resolves to `HomeShell` (kills the phantom
  "Route not found" root), wishlist empty-state returns `/home`, banner links
  validated against a safe-prefix allowlist, entry points created for `/scan`
  (home search bar) and `/orders/track` (Track Delivery button on order
  detail); dead screens deleted (`employee_portal`, `rider_dashboard`,
  `tracking_detail`, `admin/order_detail`).
- **Virtual try-on functional**: "Virtual Try-On" button on product detail,
  real `Product` passed via route arguments, real `CartProvider.addToCart` →
  checkout (synthetic try-on products removed), drag/pinch overlay + reset +
  freeze-frame capture, iOS camera/photo usage descriptions added.
- **Branding**: launcher icons regenerated from `grandelephants_icon.jpg`
  (adaptive Android icon, iOS, web icons/favicon via `flutter_launcher_icons`);
  iOS display name "Sell On App" → "Grand Elephants"; slogan
  **"Move With Conviction"** everywhere (AppConfig, config fallback, web
  title/meta/manifest); bags-first copy (pubspec, appDescription, onboarding).
- **Bags-only merchandising**: home got New Arrivals / Trending Now /
  Suggested For You carousels fed by `/api/products/new|trending|suggested`
  (`lib/services/product_feed_service.dart`), each with skeleton loading and
  silent hide-on-empty.
- **Buyer TPIN**: optional 10-digit ZRA TPIN field on checkout (client
  validation, sent as `tpin` on `POST /api/orders`), shown on the receipt.
- **Printable receipts**: `pdf` + `printing` packages, branded PDF receipt
  (business TPIN, buyer TPIN, VAT breakdown, payment refs) with Print/Share
  on the receipt and order-detail screens (`lib/services/receipt_service.dart`).
- **Business tax center**: `/business/tax` screen — VAT collected / taxable
  sales / sales count summary, per-sale VAT list with buyer TPINs, period
  selector, record-payment dialog + history (server auto-calculates from paid
  orders; ZRA Smart Invoice submission stubbed server-side).
- **Roles**: business onboarding (`/business/apply`, "Become a Seller"),
  business order-status progression, staff add, payout requests, Taxes tile;
  employee dashboard now shows real `/api/employee/stats` (fake clock-in
  removed); rider proof-of-delivery photos (camera → base64 → `proofPhoto`);
  superadmin console wired via profile tile + `/superadmin/dashboard` route;
  collection numbers now server-backed (local-only storage removed).
- **Admin**: business approvals screen (`/admin/businesses`) wired to the
  dashboard banner, admin product management via `/api/admin/products`
  (works without owning a business), `superadmin` in the role picker
  (superadmin-only), Lipila balance + business payouts on Finance, shared
  `ProductImage` widget + `imageToDataUri` pipeline (data URI/file/http),
  fake banners/marketing/export flows replaced with real ones or removed.

### Fixed
- `User.fromJson` `businessId` int-vs-string crash that broke business-user
  logins and profile refresh.
- Rider approval now yields a working fleet row server-side; reject flow
  (`riderStatus: rejected`) no longer 400s.

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
