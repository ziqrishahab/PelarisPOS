# Mobile POS App - Pelaris.id

> Aplikasi mobile Point of Sale untuk Android menggunakan Flutter

---

## Daftar Isi

- [Overview](#overview)
- [Tech Stack](#tech-stack)
- [Setup Development](#setup-development)
- [Features](#features)
- [Architecture](#architecture)
- [Build & Deploy](#build--deploy)
- [Troubleshooting](#troubleshooting)

---

## Overview

Aplikasi mobile POS dibangun dengan Flutter untuk platform Android. Digunakan oleh kasir di toko untuk melakukan transaksi penjualan dengan fitur real-time sync ke backend server.

**Target Users:**
- Kasir toko
- Owner/Manager (untuk monitoring mobile)

**Key Features:**
- Real-time product sync via WebSocket
- Barcode scanning (camera)
- Multiple payment methods
- Split payment support
- Bluetooth thermal printing (58mm/80mm)
- Transaction history
- Return request
- Offline-ready with local storage
- Multi-branch selection (Owner/Manager)

---

## Tech Stack

| Technology | Version | Purpose |
|-----------|---------|---------|
| **Flutter** | 3.9+ | UI framework |
| **Dart** | 3.x | Programming language |
| **Provider** | Latest | State management |
| **Dio** | Latest | HTTP client |
| **Socket.io Client** | Latest | Real-time sync |
| **Hive** | Latest | Local storage |
| **mobile_scanner** | Latest | Barcode scanning |
| **blue_thermal_printer** | Latest | Bluetooth printing |
| **intl** | Latest | Date formatting |
| **shared_preferences** | Latest | User preferences |

**Minimum Android SDK:** 21 (Android 5.0 Lollipop)

---

## Setup Development

### 1. Prerequisites

- Flutter SDK 3.9 atau lebih baru
- Android Studio dengan Android SDK
- Java JDK 11+
- Backend API running (http://localhost:5100)

Install Flutter:
```bash
# Windows (via Chocolatey)
choco install flutter

# Mac (via Homebrew)
brew install flutter

# Verify installation
flutter doctor
```

### 2. Clone & Install Dependencies

```bash
cd pelaris.id  # Mobile app folder
flutter pub get
```

### 3. Configuration

Edit `lib/config/app_config.dart`:

```dart
class AppConfig {
  // Development (use computer IP, bukan localhost!)
  static const String BASE_URL = 'http://192.168.1.100:5100/api';
  
  // Production
  // static const String BASE_URL = 'https://api.pelaris.id/api';
  
  static const String APP_NAME = 'Pelaris.id';
  static const String APP_VERSION = '2.0.0';
}
```

**Penting:** Gunakan IP address komputer Anda, bukan `localhost` atau `127.0.0.1`!

**Cara cek IP:**
```bash
# Windows
ipconfig

# Mac/Linux
ifconfig
```

### 4. Run on Emulator/Device

```bash
# Check connected devices
flutter devices

# Run app
flutter run

# Run in release mode (faster)
flutter run --release
```

---

## Features

### 1. Authentication

**Login Flow:**
1. User input email & password
2. API validate credentials
3. Store JWT token locally
4. Redirect to dashboard

**Auto Branch Selection:**
- Owner/Manager: Pilih cabang
- Kasir: Auto select assigned cabang

**Token Refresh:**
- Auto refresh setiap 6 hari
- Logout otomatis jika token expired

### 2. Dashboard

Menampilkan:
- Total penjualan hari ini
- Jumlah transaksi
- Branch info (nama, alamat)
- Quick actions (POS, Produk, Riwayat)

### 3. Point of Sale

**Product Search:**
- Search by nama produk
- Scan barcode via camera
- Filter by kategori

**Shopping Cart:**
- Add/remove items
- Adjust quantity
- Auto calculate total

**Payment Methods:**
- Cash (dengan kembalian)
- Transfer Bank
- QRIS
- Debit Card

**Split Payment:**
- Kombinasi 2 metode payment
- Example: Cash Rp 50.000 + Transfer Rp 50.000

**Receipt Printing:**
- Bluetooth thermal printer 58mm/80mm
- Print otomatis setelah transaksi (optional)
- Print ulang dari history

### 4. Product Management

**Product List:**
- View semua produk dengan stok
- Filter by kategori
- Search by nama/SKU

**Product Detail:**
- Nama, kategori, harga
- Variants (ukuran, warna, dll)
- Stok per variant
- Images

**Note:** Create/Edit/Delete produk hanya di web dashboard.

### 5. Transaction History

**Features:**
- List semua transaksi
- Filter by date range
- Filter by payment method
- View transaction detail
- Print ulang struk
- Create return request

### 6. Return Management

**Process:**
1. Select transaction dari history
2. Pilih item yang di-return
3. Pilih alasan (Cacat, Salah Barang, Kadaluarsa, etc)
4. Submit request
5. Menunggu approval dari Manager/Owner

**Approval:**
- Owner/Manager approve via web dashboard
- Stock otomatis restore setelah approved

### 7. Settings

**Available Settings:**
- Printer configuration
- Store info (sync dari web)
- Low stock threshold
- Auto-print toggle
- Theme (Light/Dark)
- Language (Indonesia)

**Sync Settings:**
Settings di-sync dari web dashboard, tidak bisa edit di mobile.

---

## Architecture

### Folder Structure

```
lib/
├── main.dart                 # Entry point
├── config/
│   └── app_config.dart       # Configuration
├── core/
│   ├── models/               # Data models
│   │   ├── user.dart
│   │   ├── product.dart
│   │   ├── transaction.dart
│   │   └── ...
│   ├── services/             # Business logic
│   │   ├── auth_service.dart
│   │   ├── api_service.dart
│   │   ├── socket_service.dart
│   │   ├── printer_service.dart
│   │   └── ...
│   └── providers/            # State management (Provider)
│       ├── auth_provider.dart
│       ├── product_provider.dart
│       ├── cart_provider.dart
│       └── ...
├── screens/                  # UI screens
│   ├── splash_screen.dart
│   ├── login_screen.dart
│   ├── dashboard_screen.dart
│   ├── pos_screen.dart
│   ├── products_screen.dart
│   ├── transactions_screen.dart
│   ├── returns_screen.dart
│   └── settings_screen.dart
├── widgets/                  # Reusable widgets
│   ├── custom_button.dart
│   ├── product_card.dart
│   ├── transaction_item.dart
│   └── ...
└── utils/                    # Utilities
    ├── constants.dart
    ├── helpers.dart
    └── validators.dart
```

### State Management

Menggunakan **Provider** pattern:

```dart
// Define provider
class CartProvider extends ChangeNotifier {
  List<CartItem> _items = [];
  
  void addItem(Product product) {
    _items.add(CartItem(product: product, quantity: 1));
    notifyListeners();
  }
  
  double get total => _items.fold(0, (sum, item) => sum + item.subtotal);
}

// Register provider
MultiProvider(
  providers: [
    ChangeNotifierProvider(create: (_) => AuthProvider()),
    ChangeNotifierProvider(create: (_) => CartProvider()),
    // ...
  ],
  child: MyApp(),
)

// Use in widget
class POSScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    
    return Text('Total: Rp ${cart.total}');
  }
}
```

### API Integration

```dart
class ApiService {
  final Dio dio = Dio(BaseOptions(
    baseUrl: AppConfig.BASE_URL,
    connectTimeout: Duration(seconds: 10),
    receiveTimeout: Duration(seconds: 10),
  ));
  
  // Add auth token to all requests
  void setAuthToken(String token) {
    dio.options.headers['Authorization'] = 'Bearer $token';
  }
  
  // Example API call
  Future<List<Product>> getProducts() async {
    final response = await dio.get('/products');
    return (response.data['data'] as List)
        .map((json) => Product.fromJson(json))
        .toList();
  }
}
```

### Real-time Sync

```dart
class SocketService {
  IO.Socket? socket;
  
  void connect(String token) {
    socket = IO.io(AppConfig.BASE_URL.replaceAll('/api', ''), 
      IO.OptionBuilder()
        .setTransports(['websocket'])
        .setAuth({'token': token})
        .build()
    );
    
    socket!.connect();
    
    // Listen events
    socket!.on('product:updated', (data) {
      // Refresh products
    });
    
    socket!.on('stock:updated', (data) {
      // Update stock in UI
    });
  }
}
```

---

## Build & Deploy

### Debug Build (Testing)

```bash
# APK
flutter build apk --debug

# Install to device
flutter install
```

### Release Build (Production)

```bash
# Generate keystore (first time only)
keytool -genkey -v -keystore ~/pelaris-release-key.jks \
  -keyalg RSA -keysize 2048 -validity 10000 \
  -alias pelaris

# Build signed APK
flutter build apk --release

# Build App Bundle (for Play Store)
flutter build appbundle --release
```

Output:
- APK: `build/app/outputs/flutter-apk/app-release.apk`
- Bundle: `build/app/outputs/bundle/release/app-release.aab`

### Signing Configuration

Edit `android/app/build.gradle`:

```gradle
android {
    signingConfigs {
        release {
            storeFile file("~/pelaris-release-key.jks")
            storePassword "your-password"
            keyAlias "pelaris"
            keyPassword "your-password"
        }
    }
    
    buildTypes {
        release {
            signingConfig signingConfigs.release
        }
    }
}
```

**PENTING:** Jangan commit keystore atau passwords ke Git!

### Deploy to Play Store

1. Build app bundle: `flutter build appbundle --release`
2. Login ke Google Play Console
3. Create new app
4. Upload app bundle
5. Fill store listing (screenshots, description)
6. Submit for review

---

## Bluetooth Printer Setup

### Supported Printers

- Thermal printer 58mm
- Thermal printer 80mm
- ESC/POS compatible

### Pairing Process

1. **Enable Bluetooth** di Android
2. **Pair printer** di Settings > Bluetooth
3. **Open app** → Settings → Printer
4. **Select printer** dari list
5. **Test print** untuk verify

### Print Format

```dart
Future<void> printReceipt(Transaction transaction) async {
  bluetooth.printNewLine();
  bluetooth.printCustom("PELARIS.ID", 3, 1);  // Store name (large, center)
  bluetooth.printCustom("Jl. Example No. 123", 0, 1);  // Address
  bluetooth.printNewLine();
  bluetooth.printLeftRight("No: ${transaction.id}", "Date: ${transaction.date}", 0);
  bluetooth.printNewLine();
  
  // Items
  for (var item in transaction.items) {
    bluetooth.printLeftRight(
      "${item.name} x${item.qty}",
      "Rp ${item.subtotal}",
      0
    );
  }
  
  bluetooth.printNewLine();
  bluetooth.printLeftRight("TOTAL", "Rp ${transaction.total}", 1);
  bluetooth.printNewLine();
  bluetooth.printCustom("Terima kasih", 0, 1);
  bluetooth.printNewLine();
  bluetooth.printNewLine();
  bluetooth.printNewLine();
  bluetooth.paperCut();  // Cut paper (if supported)
}
```

---

## Troubleshooting

### Cannot connect to API

**Solusi:**
1. Pastikan backend running
2. Gunakan IP address komputer (bukan localhost!)
3. Cek firewall: allow port 5100
4. Test di browser: `http://[IP]:5100/api/health`

### Barcode scanner tidak work

**Solusi:**
1. Grant camera permission
2. Restart app
3. Check `mobile_scanner` package version

### Bluetooth printer tidak terdetect

**Solusi:**
1. Pastikan printer ON & charged
2. Pair ulang di Android Settings
3. Restart Bluetooth
4. Restart app

### Build error: Gradle sync failed

**Solusi:**
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
flutter build apk
```

### App crash on startup

**Solusi:**
1. Check logs: `flutter logs`
2. Verify dependencies: `flutter pub get`
3. Clear app data di Android Settings
4. Reinstall app

---

## Development Tips

### Hot Reload

Saat development, gunakan hot reload untuk fast development:

- **Hot Reload:** `r` (preserve state)
- **Hot Restart:** `R` (reset state)
- **Quit:** `q`

### Debug Mode

```dart
// Print debug logs
if (kDebugMode) {
  print('Debug: $variable');
}

// Show debug banner
debugShowCheckedModeBanner: false,
```

### Performance

```bash
# Check performance
flutter run --profile

# Analyze app size
flutter build apk --analyze-size
```

---

## Testing

### Unit Tests

```bash
flutter test
```

### Integration Tests

```bash
flutter drive \
  --driver=test_driver/integration_test.dart \
  --target=integration_test/app_test.dart
```

---

## Scripts Reference

```bash
# Development
flutter run                  # Run debug mode
flutter run --release        # Run release mode
flutter run -d <device>      # Run on specific device

# Build
flutter build apk            # Build APK
flutter build appbundle      # Build App Bundle
flutter build apk --split-per-abi  # Split APK by ABI

# Testing
flutter test                 # Unit tests
flutter analyze              # Static analysis

# Clean
flutter clean                # Clean build artifacts
flutter pub get              # Get dependencies
```

---

## Support

- **Flutter Docs:** https://flutter.dev/docs
- **Internal Help:** Contact Mobile team
- **Bug Reports:** Include device model, Android version, error logs

---

**Last Updated:** January 2026
