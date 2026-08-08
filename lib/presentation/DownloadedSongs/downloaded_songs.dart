import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart' show SizeExtension;
import 'package:hive_flutter/hive_flutter.dart';
import 'package:soundora/common/appbar/basic_appbar.dart';
import 'package:soundora/core/services/offline_downloads.dart';
import 'package:soundora/data/models/songs/songs_model.dart';

import '../songsPlayPage/songs_play_page.dart';
import 'cubit/download_songs_for_offline_cubit.dart';
import 'cubit/download_songs_for_offline_state.dart';

class DownloadedsongsPage extends StatelessWidget {
  const DownloadedsongsPage({super.key});

  Future<void> _confirmRemove(
      BuildContext context, String songId, String title) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Ø­Ø°Ù Ø§Ù„ØªØ­Ù…ÙŠÙ„ØŸ'),
        content: Text('$title Ø³ÙŠØªØ­Ø°Ù Ù…Ù† Ø¬Ù‡Ø§Ø²Ùƒ. ÙŠÙ…ÙƒÙ†Ùƒ Ø¥Ø¹Ø§Ø¯Ø© ØªØ­Ù…ÙŠÙ„Ù‡ Ù„Ø§Ø­Ù‚Ù‹Ø§.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Ø¥Ù„ØºØ§Ø¡'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Ø­Ø°Ù'),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      await OfflineDownloads.remove(songId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: BasicAppbar(
          title: Row(
            children: [
              Text(
                "Downloaded Songs",
                style: TextStyle(fontSize: 27.sp, fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ),
        body: ValueListenableBuilder(
            valueListenable: Hive.box(OfflineDownloads.boxName).listenable(),
            builder: (context, Box pathBox, _) {
              final downloadedIds = pathBox.keys.toList();
              if (downloadedIds.isEmpty) {
                return const Center(child: Text("No offline music yet"));
              }
              return ListView.builder(
                  itemCount: downloadedIds.length,
                  itemBuilder: (context, index) {
                    final String songId = downloadedIds[index];
                    final metaBox = Hive.box("songs_metadata");
                    final dynamic rawData = metaBox.get(songId);

                    // 2. SAFETY CHECK: If metadata doesn't exist yet, don't crash
                    if (rawData == null || rawData is! Map) {
                      return const SizedBox
                          .shrink(); // Hide the item if metadata is missing
                    }
                    final Map<String, dynamic> songMap =
                        Map<String, dynamic>.from(rawData);

                    final song = SongModel.fromJson(songMap);
                    final expired = OfflineDownloads.isExpiredEntry(songId);
                    final remaining = OfflineDownloads.remainingDays(songId);

                    return BlocBuilder<DownloadSongsForOfflineCubit,
                        DownloadSongsForOfflineState>(
                      builder: (context, dlState) {
                        final inProgress =
                            dlState is DownloadSongsForOfflineLoaded &&
                                (dlState.downloads[songId] ?? 0.0) > 0 &&
                                (dlState.downloads[songId] ?? 0.0) < 1;
                        return ListTile(
                          leading: ClipRRect(
                            borderRadius: BorderRadius.circular(8.r),
                            child: CachedNetworkImage(
                                imageUrl: song.imageUrl,
                                width: 50.w,
                                height: 50.h,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                      width: 50.w,
                                      height: 50.h,
                                      color: Colors.grey[900],
                                    ),
                                errorWidget: (_, __, ___) => Container(
                                      width: 50.w,
                                      height: 50.h,
                                      color: Colors.grey[900],
                                    )),
                          ),
                          title: Text(song.title),
                          subtitle: Text(song.artist),
                          trailing: expired
                              ? TextButton.icon(
                                  onPressed: inProgress
                                      ? null
                                      : () => context
                                          .read<
                                              DownloadSongsForOfflineCubit>()
                                          .downloadSongsForOffline(song),
                                  icon: inProgress
                                      ? SizedBox(
                                          width: 14.w,
                                          height: 14.w,
                                          child: const CircularProgressIndicator(
                                              strokeWidth: 2),
                                        )
                                      : const Icon(Icons.download_rounded,
                                          size: 18),
                                  label: Text('Ù…Ù†ØªÙ‡ÙŠØ© â€” Ø¥Ø¹Ø§Ø¯Ø© ØªØ­Ù…ÙŠÙ„',
                                      style: TextStyle(fontSize: 11.sp)),
                                )
                              : Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    const Icon(Icons.check_circle,
                                        color: Colors.green),
                                    if (remaining != null) ...[
                                      SizedBox(height: 3.h),
                                      Text(
                                        remaining == 0
                                            ? 'Ø³ØªÙ†ØªÙ‡ÙŠ Ù‚Ø±ÙŠØ¨Ù‹Ø§'
                                            : 'Ù…ØªØ¨Ù‚ÙŠ $remaining ÙŠÙˆÙ…',
                                        style: TextStyle(
                                          fontSize: 10.sp,
                                          color: Colors.white.withOpacity(0.55),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                          onTap: expired || inProgress
                              ? null
                              : () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(
                                      builder: (context) => SongsPlayPage(
                                        songModel: song,
                                        songs: [
                                          song
                                        ], // You can pass an empty list or fetch related songs
                                        index:
                                            0, // Since it's a single song, index can be 0
                                      ),
                                    ),
                                  );
                                },
                          onLongPress: expired || inProgress
                              ? null
                              : () => _confirmRemove(context, songId, song.title),
                        );
                      },
                    );
                  });
            }));
  }
}
