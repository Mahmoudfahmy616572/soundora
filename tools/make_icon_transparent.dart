import 'dart:io';
import 'dart:collection';
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

  final W = image.width;
  final H = image.height;
  final threshold = 32;

  // Binary mask: true = background (to be removed)
  final removed = List.generate(H, (_) => List<bool>.filled(W, false));

  // BFS queue of (x, y)
  final queue = Queue<(int, int)>();

  bool isDark(int x, int y) {
    final p = image.getPixel(x, y);
    final maxC = [p.r.toInt(), p.g.toInt(), p.b.toInt()].reduce((a, b) => a > b ? a : b);
    return maxC < threshold;
  }

  void seed(int x, int y) {
    if (removed[y][x]) return;
    if (!isDark(x, y)) return;
    removed[y][x] = true;
    queue.add((x, y));
  }

  // Seed from all 4 borders
  for (int y = 0; y < H; y++) {
    seed(0, y);
    seed(W - 1, y);
  }
  for (int x = 0; x < W; x++) {
    seed(x, 0);
    seed(x, H - 1);
  }

  // BFS flood fill through dark pixels only
  const dirs = [(1, 0), (-1, 0), (0, 1), (0, -1)];
  int count = 0;
  while (queue.isNotEmpty) {
    final (x, y) = queue.removeFirst();
    count++;
    for (final (dx, dy) in dirs) {
      final nx = x + dx;
      final ny = y + dy;
      if (nx < 0 || nx >= W || ny < 0 || ny >= H) continue;
      if (removed[ny][nx]) continue;
      if (!isDark(nx, ny)) continue;
      removed[ny][nx] = true;
      queue.add((nx, ny));
    }
  }
  print('Removed background pixels: $count');

  // Compute bounding box of remaining (kept) pixels
  int minX = W, maxX = 0, minY = H, maxY = 0;
  for (int y = 0; y < H; y++) {
    for (int x = 0; x < W; x++) {
      if (!removed[y][x]) {
        if (x < minX) minX = x;
        if (x > maxX) maxX = x;
        if (y < minY) minY = y;
        if (y > maxY) maxY = y;
      }
    }
  }
  print('Kept bounds: x[$minX..$maxX] y[$minY..$maxY]');

  // Crop with a small margin
  final margin = 8;
  final cropX = (minX - margin).clamp(0, W - 1);
  final cropY = (minY - margin).clamp(0, H - 1);
  final cropW = ((maxX - minX + 1) + 2 * margin).clamp(1, W - cropX);
  final cropH = ((maxY - minY + 1) + 2 * margin).clamp(1, H - cropY);

  final out = img.Image(width: cropW, height: cropH, numChannels: 4);

  for (int y = 0; y < cropH; y++) {
    for (int x = 0; x < cropW; x++) {
      final sx = cropX + x;
      final sy = cropY + y;
      final p = image.getPixel(sx, sy);
      if (removed[sy][sx]) {
        out.setPixelRgba(x, y, 0, 0, 0, 0);
      } else {
        out.setPixelRgba(x, y, p.r.toInt(), p.g.toInt(), p.b.toInt(), 255);
      }
    }
  }

  // Place cropped logo onto a square transparent canvas (1024x1024)
  final canvasSize = 1024;
  final canvas = img.Image(width: canvasSize, height: canvasSize, numChannels: 4);

  double scale = 1.0;
  // Fit logo to ~80% of canvas
  final targetW = canvasSize * 0.8;
  final targetH = canvasSize * 0.8;
  final scaleX = targetW / cropW;
  final scaleY = targetH / cropH;
  scale = scaleX < scaleY ? scaleX : scaleY;

  final newW = (cropW * scale).round();
  final newH = (cropH * scale).round();
  final offsetX = ((canvasSize - newW) / 2).round();
  final offsetY = ((canvasSize - newH) / 2).round();

  for (int y = 0; y < newH; y++) {
    for (int x = 0; x < newW; x++) {
      final sx = (x / scale).floor().clamp(0, cropW - 1);
      final sy = (y / scale).floor().clamp(0, cropH - 1);
      final p = out.getPixel(sx, sy);
      canvas.setPixelRgba(offsetX + x, offsetY + y, p.r.toInt(), p.g.toInt(), p.b.toInt(), p.a.toInt());
    }
  }

  final output = File('assets/images/app_icon_transparent.png');
  output.writeAsBytesSync(img.encodePng(canvas));
  print('Output: ${output.path} (${output.lengthSync()} bytes) 1024x1024');
}
