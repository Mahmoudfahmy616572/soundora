import 'dart:io';
import 'package:image/image.dart' as img;

void main() {
  final file = File('assets/images/app_icon_source.jpeg');
  final bytes = file.readAsBytesSync();
  final image = img.decodeImage(bytes);

  if (image == null) {
    print('Could not decode image');
    return;
  }

  print('Image size: ${image.width}x${image.height}');

  // Step 1: Create a binary mask - white where logo is, black where background is
  // Use strict criteria: pixel must be clearly colorful AND bright enough
  final mask = List.generate(
    image.height,
    (y) => List.generate(image.width, (x) => false),
  );

  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      final pixel = image.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      // Calculate how "colorful" this pixel is
      final maxC = [r, g, b].reduce((a, b) => a > b ? a : b);
      final minC = [r, g, b].reduce((a, b) => a < b ? a : b);
      final range = maxC - minC;

      // A pixel is part of the logo if:
      // 1. It has significant color range (not gray/black)
      // 2. It's not too dark
      final isLogo = range > 30 && maxC > 40;

      mask[y][x] = isLogo;
    }
  }

  // Step 2: Dilate the mask slightly to clean up edges
  // (expand logo area by 2 pixels to avoid cutting into anti-aliased edges)
  final dilated = List.generate(
    image.height,
    (y) => List.generate(image.width, (x) => false),
  );

  final radius = 3;
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      if (mask[y][x]) {
        for (int dy = -radius; dy <= radius; dy++) {
          for (int dx = -radius; dx <= radius; dx++) {
            final ny = y + dy;
            final nx = x + dx;
            if (ny >= 0 && ny < image.height && nx >= 0 && nx < image.width) {
              dilated[ny][nx] = true;
            }
          }
        }
      }
    }
  }

  // Step 3: Find bounding box of dilated mask
  int minX = image.width, maxX = 0, minY = image.height, maxY = 0;
  for (int y = 0; y < image.height; y++) {
    for (int x = 0; x < image.width; x++) {
      if (dilated[y][x]) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }

  print('Logo bounds: ($minX,$minY) to ($maxX,$maxY)');

  // Step 4: Crop and apply mask
  final cropX = (minX - 2).clamp(0, image.width - 1);
  final cropY = (minY - 2).clamp(0, image.height - 1);
  final cropW = (maxX - minX + 4).clamp(1, image.width - cropX);
  final cropH = (maxY - minY + 4).clamp(1, image.height - cropY);

  final cropped = img.copyCrop(image, x: cropX, y: cropY, width: cropW, height: cropH);
  final dilatedCropped = List.generate(
    cropH,
    (y) => List.generate(cropW, (x) => dilated[cropY + y][cropX + x]),
  );

  final transparent = img.Image(width: cropW, height: cropH);

  int kept = 0, removed = 0;
  for (int y = 0; y < cropH; y++) {
    for (int x = 0; x < cropW; x++) {
      final pixel = cropped.getPixel(x, y);
      final r = pixel.r.toInt();
      final g = pixel.g.toInt();
      final b = pixel.b.toInt();

      if (dilatedCropped[y][x]) {
        transparent.setPixelRgba(x, y, r, g, b, 255);
        kept++;
      } else {
        transparent.setPixelRgba(x, y, 0, 0, 0, 0);
        removed++;
      }
    }
  }

  print('Kept: $kept, Removed: $removed');

  final output = File('assets/images/app_icon_transparent.png');
  output.writeAsBytesSync(img.encodePng(transparent));
  print('Output: ${output.path} (${output.lengthSync()} bytes)');
}
