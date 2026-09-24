# Grand Elephants

Premium marketplace & luxury heritage storefront — Flutter app (Android, web)
for the Grand Elephants platform.

## Stack

- Flutter 3.35+ (Material 3, soft UI design system)
- `provider` state management (Auth, Cart, Catalog, Config, Rider, Admin, …)
- Cloudflare Worker backend: `grand-elephants-api` (JWT auth, Lipila payments,
  Africa's Talking SMS, Firebase FCM push)
- Hosted PMTiles vector map (Zambia) for order tracking

## Commands

```
flutter pub get
flutter analyze              # must be 0 issues
flutter test                 # model/unit tests
flutter build web --release  # website (served by the worker)
flutter build apk --release
flutter build appbundle --release
```

## Configuration

- API base URL defaults to `https://grand-elephants-api.godfreymoseskalambo.workers.dev`
  (override: `--dart-define=API_BASE_URL=...`).
- Android applicationId / namespace: `com.grandelephants.shop`
- Firebase: `android/app/google-services.json` (project `grand-elephants-b8ec4`);
  FCM token is uploaded to the backend on OTP login for push notifications.

## Deployment

The web build (`build/web`) is served by the Cloudflare worker together with
the JSON API — deploy from the `grand-elephants-api` repo (`.\deploy.ps1`).

See `AGENTS.md` for agent conventions and `BLUEPRINT.md` for architecture.

## Resources

- [Flutter docs](https://docs.flutter.dev/)
