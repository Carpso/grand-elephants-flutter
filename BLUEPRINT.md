# Grand Elephants / Sell On App — Flutter App Blueprint

Premium marketplace & luxury heritage storefront. Multi-role: customers, riders,
businesses, employees, admins and superadmins share one app with role-based tabs
and navigation guards.

## Stack

- Flutter 3.35+ (Material 3, soft UI design system)
- `provider` for state (Auth, Cart, Catalog, Config, Wishlist, Notifications,
  Rider, Admin, AppData, CollectionNumber)
- Cloudflare Worker backend (see `grand-elephants-api`) with JWT auth
- `flutter_secure_storage` for the token, `shared_preferences` for cached data
- `camera`/`image_picker` for scanning, try-on, delivery proof, photos
- Hosted PMTiles vector map (Zambia) for order tracking (`lib/widgets/hosted_map.dart`)
- Lipila payments handled **server-side** (checkout posts the order; the worker
  sends the MoMo prompt and webhook-confirms payment)

## Roles

The app adapts per role (see `lib/screens/home/home_shell.dart`):

- **user** — Home / Explore / Profile
- **rider** — Home / Deliveries / Profile (real fleet via `RiderProvider`)
- **business** — Home / Business / Profile (`BusinessHomeScreen` = real finance + orders)
- **employee** — Home / Work / Profile (`EmployeeDashboardScreen`)
- **admin / superadmin** — Home / Business / Admin / Profile; admin routes are
  guarded in `main.dart` (non-admin → redirected home with a toast)

Every admin route in `onGenerateRoute` checks the role before building the page.

## Data flow

- `ApiClient` (`lib/services/api_client.dart`) — HTTP + bearer token from secure
  storage, JSON decode, typed `ApiException`, 30s timeouts.
- Providers call the API and `notifyListeners()`; screens `context.watch`.
- Cart + wishlist + user cache persist via `StorageService` (shared_preferences).
- Orders always come from the server (`CartProvider.loadOrders/fetchOrder`).

## Money

Checkout → `POST /api/orders`. The worker computes totals (VAT 16%, delivery
K25 + K10/km, Lipila fee) server-side, sends the MoMo prompt to the customer
phone, and confirms via webhook. **Never trust client-side totals** — the order
response reflects the server's numbers.

## Map

`lib/widgets/hosted_map.dart` wraps `flutter_map` + `vector_map_tiles` +
`vector_map_tiles_pmtiles` loading Zambia tiles from
`https://maps.churchonapp.com/zambia.pmtiles` (no API key) with an OSM raster
fallback. Used on the order-tracking screen. Marker helpers included.

## Build

```
flutter analyze            # must be 0 issues
flutter test               # model/unit tests
flutter build web --release          # website (served by the worker)
flutter build apk --release          # Android APK
flutter build appbundle --release    # Android AAB (Play Store)
```

The web build output (`build/web`) is served by the Cloudflare worker — deploy
from the `grand-elephants-api` repo (`.\deploy.ps1`).

## Key directories

- `lib/providers/` — state providers (real API-backed)
- `lib/screens/` — feature screens grouped by area (auth, home, explore, product,
  cart, checkout, orders, rider, business, employee, admin, profile, scan, tryon, support)
- `lib/widgets/` — soft UI system + `ProductImage`, `HostedMap`, toast
- `lib/models/` — Product, CartItem/Order, User, BusinessCollectionNumber
- `lib/services/` — ApiClient, StorageService