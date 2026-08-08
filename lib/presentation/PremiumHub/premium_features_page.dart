import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get_it/get_it.dart';
import 'package:soundora/common/appbar/basic_appbar.dart';import 'package:soundora/presentation/Gamification/achievements_page.dart';
import 'package:soundora/presentation/Gamification/cubit/achievement_cubit.dart';
import 'package:soundora/presentation/KaraokeMode/karaoke_page.dart';
import 'package:soundora/presentation/ListeningParty/cubit/listening_party_cubit.dart';
import 'package:soundora/presentation/ListeningParty/listening_party_page.dart';
import 'package:soundora/presentation/LyricsMemory/lyrics_memory_page.dart';
import 'package:soundora/presentation/MoodMap/cubit/mood_map_cubit.dart';
import 'package:soundora/presentation/MoodMap/mood_map_page.dart';
import 'package:soundora/presentation/MusicCard/music_card_page.dart';
import 'package:soundora/presentation/Quran/cubit/quran_cubit.dart';
import 'package:soundora/presentation/Quran/quran_page.dart';
import 'package:soundora/presentation/SmartDJ/cubit/smart_dj_cubit.dart';
import 'package:soundora/presentation/SmartDJ/smart_dj_page.dart';
import 'package:soundora/presentation/SpatialAudio/spatial_audio_page.dart';
import 'package:soundora/presentation/TimeMachine/cubit/time_machine_cubit.dart';
import 'package:soundora/presentation/TimeMachine/time_machine_page.dart';

class PremiumFeaturesPage extends StatelessWidget {
  const PremiumFeaturesPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: BasicAppbar(
        isLeading: true,
        title: Text(
          'Discover',
          style: TextStyle(
            fontSize: 27.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 16.h),
            Text(
              'Soundora Experiences',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 4.h),
            Text(
              'Tools that understand your music and make it yours',
              style: TextStyle(
                fontSize: 14.sp,
                color: Colors.white54,
              ),
            ),
            SizedBox(height: 20.h),
            Expanded(
              child: GridView.builder(
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12.w,
                  mainAxisSpacing: 12.h,
                  childAspectRatio: 1.1,
                ),
                itemCount: _features.length,
                itemBuilder: (context, index) {
                  final feature = _features[index];
                  return _buildFeatureCard(context, feature);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeatureCard(BuildContext context, _FeatureItem feature) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => feature.pageBuilder(context)),
        );
      },
      child: Container(
        padding: EdgeInsets.all(14.r),
        decoration: BoxDecoration(
          color: feature.color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(
            color: feature.color.withOpacity(0.25),
            width: 1,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 48.w,
              height: 48.h,
              decoration: BoxDecoration(
                color: feature.color.withOpacity(0.2),
                shape: BoxShape.circle,
              ),
              child: Icon(
                feature.icon,
                color: feature.color,
                size: 24.sp,
              ),
            ),
            SizedBox(height: 10.h),
            Text(
              feature.title,
              style: TextStyle(
                fontSize: 13.sp,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 4.h),
            Text(
              feature.description,
              style: TextStyle(
                fontSize: 10.sp,
                color: Colors.white54,
              ),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}

class _FeatureItem {
  final String title;
  final String description;
  final IconData icon;
  final Color color;
  final Widget Function(BuildContext) pageBuilder;

  const _FeatureItem({
    required this.title,
    required this.description,
    required this.icon,
    required this.color,
    required this.pageBuilder,
  });
}

final _features = [
  _FeatureItem(
    title: 'Mood Map',
    description: 'Discover music by mood',
    icon: Icons.mood,
    color: const Color(0xFFFF6B6B),
    pageBuilder: (_) => BlocProvider(
      create: (_) => MoodMapCubit(),
      child: const MoodMapPage(),
    ),
  ),
  _FeatureItem(
    title: 'Smart DJ',
    description: 'Auto-generated playlists',
    icon: Icons.headphones,
    color: const Color(0xFF4ECDC4),
    pageBuilder: (_) => BlocProvider(
      create: (_) => SmartDJCubit(),
      child: const SmartDJPage(),
    ),
  ),
  _FeatureItem(
    title: 'Time Machine',
    description: 'Music from any era',
    icon: Icons.history,
    color: const Color(0xFFFFBE0B),
    pageBuilder: (_) => BlocProvider(
      create: (_) => TimeMachineCubit(),
      child: const TimeMachinePage(),
    ),
  ),
  _FeatureItem(
    title: 'Listening Party',
    description: 'Listen together',
    icon: Icons.group,
    color: const Color(0xFF845EC2),
    pageBuilder: (_) => BlocProvider(
      create: (_) => ListeningPartyCubit(),
      child: const ListeningPartyPage(),
    ),
  ),
  _FeatureItem(
    title: 'Karaoke Mode',
    description: 'Sing along with lyrics',
    icon: Icons.mic,
    color: const Color(0xFFFF6F91),
    pageBuilder: (_) => const KaraokePage(),
  ),
  _FeatureItem(
    title: 'Achievements',
    description: 'Track your progress',
    icon: Icons.emoji_events,
    color: const Color(0xFFFFD93D),
    pageBuilder: (_) => BlocProvider(
      create: (_) => GetIt.instance<AchievementCubit>()..loadAchievements(),
      child: const AchievementsPage(),
    ),
  ),
  _FeatureItem(
    title: 'Music Card',
    description: 'Share beautiful cards',
    icon: Icons.card_giftcard,
    color: const Color(0xFF6C5CE7),
    pageBuilder: (_) => const MusicCardPage(),
  ),
  _FeatureItem(
    title: 'Lyrics Memory',
    description: 'Your musical journey',
    icon: Icons.auto_stories,
    color: const Color(0xFF00B894),
    pageBuilder: (_) => const LyricsMemoryPage(),
  ),
  _FeatureItem(
    title: 'Spatial Audio',
    description: '3D sound experience',
    icon: Icons.surround_sound,
    color: const Color(0xFF00B894),
    pageBuilder: (_) => const SpatialAudioPage(),
  ),
  _FeatureItem(
    title: 'Quran',
    description: 'المصحف · ترتيل وتلاوة',
    icon: Icons.menu_book,
    color: const Color(0xFF4CAF50),
    pageBuilder: (_) => BlocProvider(
      create: (_) => QuranCubit(),
      child: const QuranPage(),
    ),
  ),
];
