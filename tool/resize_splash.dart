import 'dart:io';
import 'package:image/image.dart' as img;

void main() async {
  // Load the foreground icon
  final inputFile = File('assets/images/flutter-loading.png');
  final bytes = await inputFile.readAsBytes();
  final image = img.decodeImage(bytes);

  if (image == null) {
    print('Failed to decode image');
    return;
  }

  // Create a larger canvas (1152x1152 for best quality splash)
  const size = 1152;
  final canvas = img.Image(width: size, height: size);

  // Fill with the brand color #2862ED
  final brandColor = img.ColorRgba8(0x28, 0x62, 0xED, 255);
  img.fill(canvas, color: brandColor);

  // Scale the icon to full size (100% of canvas)
  const scale = 1.0;
  final iconSize = (size * scale).toInt();
  final resizedIcon = img.copyResize(image, width: iconSize, height: iconSize);

  // Center the icon on canvas
  final offsetX = (size - iconSize) ~/ 2;
  final offsetY = (size - iconSize) ~/ 2;

  // Composite the icon onto the canvas
  img.compositeImage(canvas, resizedIcon, dstX: offsetX, dstY: offsetY);

  // Save the result
  final outputFile = File('assets/images/splash_icon.png');
  await outputFile.writeAsBytes(img.encodePng(canvas));

  print(
    'Created splash_icon.png (${size}x$size) with icon at ${(scale * 100).toInt()}% size',
  );
}
