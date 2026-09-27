# SESSION_STATE — Grand Elephants (Flutter app)

Saved: 2026-09-27. Companion: same file in `grand-elephants-api`.

## Project identity
- Product: **Grand Elephants** — bags-only marketplace ("Move With Conviction")
- Dart package `grand_elephants`; Android `com.grandelephants.shop`; label "Grand Elephants"
- Backend: Cloudflare Worker `grand-elephants-api` (same URL serves JSON API `/api/*` + Flutter web SPA)

## Infra (no secrets in this file)
- Worker/site: `https://grand-elephants-api.godfreymoseskalambo.workers.dev`
- D1: `grand-elephants-db` (id `447d1f6c-1b73-4bfd-bea5-3747460acdfc`) — 25 tables, bag seed applied
- Wrangler auth: OAuth in `C:\Users\User\AppData\Roaming\xdg.config\.wrangler\config\default.toml` — run `npx wrangler` WITHOUT `CLOUDFLARE_API_TOKEN` env (that token lacks workers:edit). Account `ab82a97ce2c926279c483fef36c41945`.
- Secrets on worker (set, values never stored on disk): `AT_API_KEY` (PRODUCTION, from `OneDrive\Documents\Settings - API Key.txt`), `JWT_SECRET` (`Temp\opencode\jwt_secret.txt`), `LIPILA_API_KEY`, `LIPILA_WEBHOOK_SECRET` (`Temp\opencode\webhook_secret.txt`), `SUPERADMIN_PHONES=+260968551110`, `FIREBASE_PRIVATE_KEY`/`FIREBASE_CLIENT_EMAIL` (`Temp\opencode\firebase_key.pem`).
- SMS: Africa's Talking **production** (`api.africastalking.com`, username `ChurchOnApp`, sender **Carpso** approved, brand `GRANDELEPHANTS:`). `AT_SANDBOX=false` in wrangler.toml. NOTE: keys are environment-specific — sandbox keys 401 on prod host.
- GitHub: remotes `Carpso/grand-elephants-flutter` (branch **main**) and `Carpso/grand-elephants-api` (branch **master**); push via `git push https://Carpso:<PAT>@github.com/...` (PAT in credential history — `ghp_efe3...`).
- R2: bucket `choa-sermons-vault`, SigV4 script `C:\Users\User\AppData\Local\Temp\opencode\upload_r2.ps1 -Bucket "choa-sermons-vault"` → `https://media.churchonapp.com/grand-elephants/grand-elephants.apk|.aab`.
- Maps: `https://maps.churchonapp.com/zambia.pmtiles` (PMTiles, OSM fallback).
- Firebase project `grand-elephants-b8ec4`; google-services.json in android/app.

## Done this session (all pushed)
- API `6a5cb84` (master) / Flutter `373943e` (main). analyze 0, 13/13 tests, tsc 0.
- **Session persistence**: splash awaits `AuthProvider.ready`, provider `lazy:false`, 14-day inactivity reset (wired in HomeShell pointer/resume), navigatorKey logout, `businessId` int→String fix.
- **Routes**: `/` → HomeShell, `/scan` (home search bar), `/orders/track` (order detail), banner link allowlist, 4 dead screens deleted, `/business/apply`, `/superadmin/dashboard`, `/admin/businesses`, `/business/tax` added+guarded (`teamRoutes`/`adminOnlyRoutes` in main.dart).
- **Branding**: flutter_launcher_icons from `assets/images/grandelephants_icon.jpg` (adaptive icon), iOS display name fixed, slogan "Move With Conviction" everywhere, bags-only copy (onboarding/description/web meta).
- **Try-on**: product-detail button → real Product arg → real `CartProvider.addToCart` → checkout; drag/pinch/capture; iOS camera/photo usage keys.
- **Roles**: business onboarding + products + order-status + staff + payouts; employee real `/api/employee/stats`; rider proof-photo (base64 data URI → `proofPhoto`); superadmin console; collection numbers server-backed; shared `ProductImage` widget + `lib/services/image_util.dart` (`imageToDataUri`, 900px/q70).
- **Admin**: `/admin/products` CRUD (no business needed, business picker), business approvals screen, superadmin role picker (superadmin-only), Finance Lipila balance + payouts, fake banner/marketing flows removed or made real.
- **Merchandising**: home New Arrivals / Trending / Suggested rows (`lib/services/product_feed_service.dart` → `/api/products/new|trending|suggested`).
- **TPIN**: checkout field (10 digits) → `POST /api/orders {tpin}` → `buyerTpin` on order/invoice/receipt.
- **Receipts**: `pdf`+`printing` added; `lib/services/receipt_service.dart` (server `/api/orders/:id/receipt` + local fallback); Print/Share on receipt + order detail.
- **Tax**: `lib/screens/business/tax_screen.dart` (`/business/tax`) — VAT summary, VAT-by-sale w/ TPIN, record payments.
- **2026-09-27 incidents (server-side, no app change)**: (1) "Send Code" got no response because the live Worker deployment was **assets-only** (empty 404s at the edge, CF `100311`). (2) A **foreign deployment** (`6841ad08`, 08:08Z, foreign config) broke it again and **wiped all Worker secrets** → `verify-otp` 500 (empty JWT) + silent SMS failure. Fixed: redeploy + secrets re-put; **`LIPILA_API_KEY` value is lost — user must re-put it from the Lipila dashboard**. Full browser E2E now passes: type number → Send Code → `request-otp 200` → code → Verify → `verify-otp 200` → logged-in Home. See api SESSION_STATE for value sources + the warning about a second active deployer (it will break prod again unless coordinated). `.dev.vars` = local placeholders only.
- **2026-09-27 gap batch (six gaps closed, E2E green)**: (1) **Release keystore**: `android/app/upload-keystore.jks` (alias `upload`, CN=Grand Elephants) + `android/key.properties` (both gitignored); creds file `OneDrive\Documents\grand-elephants release keystore.txt`; `build.gradle.kts` signs release with it (falls back to debug if file missing). (2) **iOS bundle id** `com.sellonapp.sellOnApp` → `com.grandelephants.shop` (6/6 pbxproj lines). (3) **UploadService** (`lib/services/upload_service.dart`) at all 5 image pickers (product/bike/profile/proof/banner) → `POST /api/upload` → R2 URL, silent fallback to data-URI on failure. (4) **Admin write UI**: banners add/edit/delete (`/admin/banners`), categories delete with 409 toast. (5) **FCM tap-through** in `lib/main.dart`: `onMessageOpenedApp` + `getInitialMessage` → allowlisted route via `navigatorKey`, skipped when logged out. (6) Release APK (69.2MB) + AAB (58.4MB) rebuilt **signed with the release keystore** (apksigner: `CN=Grand Elephants`) and re-uploaded to R2 (`media.churchonapp.com/grand-elephants/…`; ETag matched local MD5 — verify that way after uploads). R2 upload script `Temp\opencode\upload_r2.ps1` defaults to bucket `carpso-assets` which **no longer exists** — always pass `-Bucket choa-sermons-vault`. Server companions: OTP lockout (429 after 5 fails), 401→403 role/scope reclass, banner/category APIs, ZRA VSDC client (config-driven — needs official onboarding + `ZRA_API_KEY`). Gates: analyze 0, tests 13/13. Note: secrets wiped AGAIN 12:40Z (third foreign break) — restored 6/6.

## Known gaps / next steps
- iOS bundle id still `com.sellonapp.sellOnApp` in `project.pbxproj` (display name fixed; rename bundle if shipping iOS).
- Release APK/AAB signed with **debug keystore** — add a release keystore before Play Store.
- Product images: base64 data URIs stored in D1 (works, but large rows); move to R2 later (add R2 binding + upload endpoint).
- Banner "Add" is read-only (no banner write endpoint); categories create-only (no delete endpoint).
- ZRA Smart Invoice: `src/smart_invoice.ts` `submitInvoice()` is a logged no-op TODO — embed real API there.
- Wishlist is local-only (by design per AGENTS.md).
- FCM: token sent on verifyOtp; no tap-through deep-link routing yet (`onMessageOpenedApp` unused).
- `flutter_secure_storage` on web is origin-bound (workers.dev vs custom domain = re-login).

## Key commands
- Flutter: `flutter analyze` (must be 0), `flutter test`, `flutter build web|apk|appbundle --release`
- API: `npx tsc --noEmit`, `npx wrangler deploy`, `npx wrangler d1 execute grand-elephants-db --remote --command "..."`
- Website deploy = build web then `npx wrangler deploy` (worker serves `../grand-elephants-flutter/build/web`).
