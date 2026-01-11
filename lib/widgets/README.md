# Loading Screen Widget

Widget loading screen dengan background brand color (#545efd) dan app icon.

## Penggunaan

### 1. Full Screen Loading
Untuk loading screen penuh (halaman loading):

```dart
import 'package:pelaris/widgets/loading_screen.dart';

// Di dalam widget build
return const LoadingScreen(
  message: 'Memuat data...', // Optional
);
```

### 2. Loading Dialog/Overlay
Untuk menampilkan loading di atas screen yang ada:

```dart
import 'package:pelaris/widgets/loading_screen.dart';

// Show loading
showLoadingDialog(context, message: 'Memproses...');

// Hide loading
hideLoadingDialog(context);
```

### 3. Contoh Implementasi di Function

```dart
Future<void> _processData() async {
  // Show loading
  showLoadingDialog(context, message: 'Memproses data...');
  
  try {
    // Do something async
    await someAsyncOperation();
    
    // Hide loading
    hideLoadingDialog(context);
    
    // Show success
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Berhasil!')),
    );
  } catch (e) {
    // Hide loading
    hideLoadingDialog(context);
    
    // Show error
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('Error: $e')),
    );
  }
}
```

## Customization

Background color dan app icon sudah disesuaikan dengan brand:
- **Background**: `#545efd`
- **Icon**: `assets/images/app_icon.png`
- **Loading color**: White

Jika perlu ubah, edit file `lib/widgets/loading_screen.dart`.
