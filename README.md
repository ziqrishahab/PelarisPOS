# Pelaris.id

[![Flutter](https://img.shields.io/badge/Flutter-3.9.2-02569B?logo=flutter)](https://flutter.dev/)
[![Dart](https://img.shields.io/badge/Dart-3.x-0175C2?logo=dart)](https://dart.dev/)
[![Android](https://img.shields.io/badge/Android-21+-3DDC84?logo=android)](https://www.android.com/)

Mobile POS App untuk Pelaris.id omnichannel retail system (Android).

**Repository:** [https://github.com/rejaldev/Pelaris.id-POS](https://github.com/rejaldev/Pelaris.id-POS)

## Features

- **Real-time Sync** - WebSocket auto-refresh product & stock dari web dashboard
- Product search & barcode scanning (mobile_scanner)
- Cart management dengan variant support
- Multiple payment methods (Cash, Transfer, QRIS, Debit)
- Split payment support (multi-method dalam 1 transaksi)
- Bluetooth thermal printing (58mm/80mm format)
- Transaction history dengan filter & pagination
- Return request management
- Settings sync dari web dashboard
- Offline-ready dengan local storage

## Quick Start

```bash
flutter pub get
flutter run
```

## Tech Stack

| Technology | Purpose |
|------------|---------|
| Flutter 3.9.2 | UI Framework |
| Provider | State Management |
| Dio | HTTP Client |
| Socket.IO Client 3.1.3 | Real-time WebSocket |
| print_bluetooth_thermal | Thermal Printer |
| mobile_scanner | Barcode/QR Scanner |
| shared_preferences | Local Storage |
| auto_route | Navigation |

## Project Structure

```
lib/
├── core/
│   ├── constants/      # API config, theme
│   ├── services/       # Socket service
│   └── utils/          # Formatters, helpers
├── data/
│   ├── api/            # HTTP client
│   ├── models/         # Data models
│   ├── repositories/   # Data layer
│   └── services/       # Print, auth services
├── providers/          # State management (Provider pattern)
└── screens/
    ├── auth/           # Login
    ├── pos/            # POS, cart, checkout
    ├── main/           # Product & transaction list
    └── settings/       # Printer & app settings
```

## Build

```bash
# Debug APK
flutter build apk --debug

# Release APK
flutter build apk --release

# App Bundle (Play Store)
flutter build appbundle --release
```

Output: `build/app/outputs/flutter-apk/app-release.apk`

## Configuration

Backend API URL sudah hardcoded ke production server:
- API: `https://api.Pelaris.id.ziqrishahab.com/api`
- WebSocket: `https://api.Pelaris.id.ziqrishahab.com`

Untuk development, edit di:
- `lib/core/constants/api_constants.dart` (HTTP API)
- `lib/core/services/socket_service.dart` (WebSocket URL)

## Requirements

- Flutter SDK >= 3.9.2
- Dart SDK >= 3.x
- Android SDK 21+ (Android 5.0 Lollipop)
- Bluetooth thermal printer (58mm/80mm)

## Permissions

App membutuhkan permissions berikut:
- `BLUETOOTH` & `BLUETOOTH_ADMIN` - Printer connection
- `BLUETOOTH_CONNECT` & `BLUETOOTH_SCAN` - Android 12+
- `CAMERA` - Barcode scanning
- `INTERNET` - API calls

## Known Issues

**Kotlin Incremental Compilation Error (Windows):**
Project di D: drive, pub cache di C: drive menyebabkan Kotlin compiler error saat build. Sudah di-workaround dengan `kotlin.incremental=false` di `android/gradle.properties`. Build tetap berhasil meskipun ada error log.

## Changelog

### 2026-01-09
- Added comprehensive unit tests (110 tests passing)
- Test coverage: models, repositories, services, providers, formatters
- Fixed branch selection modal UX (only shows for Owner/Manager roles)

### 2026-01-07
- Improved socket reconnection logic
- Better error handling for offline mode

### 2026-01-05
- Added split payment support
- Fixed thermal print formatting

- Backend: Hono.js + PostgreSQL 18 + Prisma ORM
- Frontend Dashboard: Next.js 16 + React 19
- WebSocket: Socket.IO 4.8.1
- Deployment: Ubuntu VPS dengan PM2 + Nginx

## Changelog

### 2026-01-06
- Updated all app icons to new Pelaris.id branding
- Regenerated native splash screen with new icon
- Updated launcher icons (all densities: mdpi to xxxhdpi)
- Updated adaptive icons for Android 12+
- Updated Flutter loading screen icon (app_icon.png)

### 2026-01-05
- Enhanced product search: client-side filtering with multi-word AND logic for instant results
- Optimized search behavior: filter at variant level, only show matching variants
- Updated receipt printing: product name and variant info now display on separate lines
- Added Product.copyWith method for variant filtering support
