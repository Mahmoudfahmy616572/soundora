import 'dart:io';
import 'dart:ui' as ui;

import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class LyricShareCard extends StatelessWidget {
  final String lyricText;
  final String songTitle;
  final String artistName;
  final Color accentColor;
  final Color bgColor;

  const LyricShareCard({
    super.key,
    required this.lyricText,
    required this.songTitle,
    required this.artistName,
    required this.accentColor,
    this.bgColor = const Color(0xFF0E0E10),
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(minHeight: 420),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            bgColor,
            Color.lerp(bgColor, accentColor, 0.18)!,
            bgColor,
          ],
        ),
        borderRadius: BorderRadius.circular(28),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          const _ArabicHeader(accentColor: Color(0xFFC9A96A)),
          const SizedBox(height: 40),
          Icon(Icons.format_quote_rounded, size: 52, color: accentColor.withOpacity(0.5)),
          const SizedBox(height: 16),
          Text(
            lyricText,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 28,
              height: 1.7,
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontFamily: 'Satoshi',
              shadows: [
                Shadow(
                  color: accentColor.withOpacity(0.35),
                  blurRadius: 20,
                ),
              ],
            ),
          ),
          const SizedBox(height: 40),
          Container(
            width: 64,
            height: 1.5,
            color: accentColor.withOpacity(0.4),
          ),
          const SizedBox(height: 20),
          Text(
            songTitle,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Satoshi',
            ),
          ),
          const SizedBox(height: 6),
          Text(
            artistName,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 14,
              color: Colors.white.withOpacity(0.55),
              fontFamily: 'Satoshi',
            ),
          ),
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.asset(
                'assets/images/app_icon_transparent.png',
                width: 18,
                height: 18,
              ),
              const SizedBox(width: 8),
              Text(
                'SOUNDORA',
                style: TextStyle(
                  fontSize: 12,
                  letterSpacing: 4,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withOpacity(0.4),
                  fontFamily: 'Satoshi',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ArabicHeader extends StatelessWidget {
  final Color accentColor;
  const _ArabicHeader({required this.accentColor});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Container(width: 56, height: 1, color: accentColor.withOpacity(0.6)),
        const SizedBox(width: 12),
        Transform.rotate(
          angle: 0.785398,
          child: Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              border: Border.all(color: accentColor, width: 1.4),
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(width: 56, height: 1, color: accentColor.withOpacity(0.6)),
      ],
    );
  }
}

class LyricShareService {
  static Future<void> shareCard({
    required GlobalKey boundaryKey,
    required String songTitle,
    required String artistName,
  }) async {
    final boundary = boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) return;

    final image = await boundary.toImage(pixelRatio: 3);
    final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
    if (byteData == null) return;

    final tempDir = await getTemporaryDirectory();
    final file = await File('${tempDir.path}/lyric_card_${DateTime.now().millisecondsSinceEpoch}.png')
        .writeAsBytes(byteData.buffer.asUint8List());

    await Share.shareXFiles(
      [XFile(file.path, mimeType: 'image/png')],
      text: '$songTitle — $artistName on Soundora',
    );
  }
}
