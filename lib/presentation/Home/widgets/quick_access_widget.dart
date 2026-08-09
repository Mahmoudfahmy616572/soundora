import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/presentation/KaraokeMode/karaoke_page.dart';
import 'package:soundora/presentation/ListeningParty/cubit/listening_party_cubit.dart';
import 'package:soundora/presentation/ListeningParty/listening_party_page.dart';
import 'package:soundora/presentation/MainWrapper/cubit/cubit/navigation_cubit.dart';
import 'package:soundora/presentation/Maqam/cubit/maqam_cubit.dart';
import 'package:soundora/presentation/Maqam/maqam_discovery_page.dart';
import 'package:soundora/presentation/MoodMap/cubit/mood_map_cubit.dart';
import 'package:soundora/presentation/MoodMap/mood_map_page.dart';
import 'package:soundora/presentation/MusicCard/music_card_page.dart';
import 'package:soundora/presentation/Quran/cubit/quran_cubit.dart';
import 'package:soundora/presentation/Quran/quran_page.dart';
import 'package:soundora/presentation/SmartDJ/cubit/smart_dj_cubit.dart';
import 'package:soundora/presentation/SmartDJ/smart_dj_page.dart';
import 'package:soundora/presentation/TimeMachine/cubit/time_machine_cubit.dart';
import 'package:soundora/presentation/TimeMachine/time_machine_page.dart';
import 'package:soundora/serviece_locator.dart';

class QuickAccessWidget extends StatelessWidget {
  const QuickAccessWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final items = [
      _QuickItem(
        label: 'القرآن',
        icon: Icons.menu_book,
        colors: const [Color(0xFF43A047), Color(0xFF1B5E20)],
        builder: (_) => BlocProvider(
          create: (_) => QuranCubit(),
          child: const QuranPage(),
        ),
      ),
      _QuickItem(
        label: 'كاريوكي',
        icon: Icons.mic,
        colors: const [Color(0xFFFF6F91), Color(0xFFB0003A)],
        builder: (_) => const KaraokePage(),
      ),
      _QuickItem(
        label: 'المزاج',
        icon: Icons.mood,
        colors: const [Color(0xFFFFB300), Color(0xFFE65100)],
        builder: (_) => BlocProvider(
          create: (_) => getIt<MoodMapCubit>(),
          child: const MoodMapPage(),
        ),
      ),
      _QuickItem(
        label: 'المقام',
        icon: Icons.graphic_eq,
        colors: const [Color(0xFF7B2FBE), Color(0xFF4A148C)],
        builder: (_) => BlocProvider(
          create: (_) => MaqamCubit(),
          child: const MaqamDiscoveryPage(),
        ),
      ),
      _QuickItem(
        label: 'سمارت DJ',
        icon: Icons.headphones,
        colors: const [Color(0xFF26A69A), Color(0xFF004D40)],
        builder: (_) => BlocProvider(
          create: (_) => SmartDJCubit(),
          child: const SmartDJPage(),
        ),
      ),
      _QuickItem(
        label: 'حفلة استماع',
        icon: Icons.group,
        colors: const [Color(0xFF5C6BC0), Color(0xFF1A237E)],
        builder: (_) => BlocProvider(
          create: (_) => ListeningPartyCubit(),
          child: const ListeningPartyPage(),
        ),
      ),
      _QuickItem(
        label: 'آلة الزمن',
        icon: Icons.history,
        colors: const [Color(0xFFFFB300), Color(0xFFBF360C)],
        builder: (_) => BlocProvider(
          create: (_) => TimeMachineCubit(),
          child: const TimeMachinePage(),
        ),
      ),
      _QuickItem(
        label: 'بطاقة موسيقية',
        icon: Icons.card_giftcard,
        colors: const [Color(0xFF7E57C2), Color(0xFF311B92)],
        builder: (_) => const MusicCardPage(),
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Row(
            children: [
              Icon(
                Icons.auto_awesome,
                color: Colors.white.withOpacity(0.9),
                size: 18.sp,
              ),
              SizedBox(width: 6.w),
              Text(
                'أكتر ما يهمك',
                style: TextStyle(
                  fontSize: 19.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                  fontFamily: 'Satoshi',
                ),
              ),
              const Spacer(),
              GestureDetector(
                onTap: () {
                  context.read<NavigationCubit>().updateIndex(3);
                },
                child: Row(
                  children: [
                    Text(
                      'الكل',
                      style: TextStyle(
                        fontSize: 13.sp,
                        color: Colors.white70,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(
                      Icons.arrow_back_ios,
                      size: 12.sp,
                      color: Colors.white70,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        SizedBox(height: 12.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 4,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
              childAspectRatio: 0.78,
            ),
            itemCount: items.length,
            itemBuilder: (context, index) {
              final item = items[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: item.builder),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: item.colors,
                    ),
                    borderRadius: BorderRadius.circular(16.r),
                    boxShadow: [
                      BoxShadow(
                        color: item.colors.first.withOpacity(0.25),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        item.icon,
                        color: Colors.white,
                        size: 24.sp,
                      ),
                      SizedBox(height: 8.h),
                      Padding(
                        padding: EdgeInsets.symmetric(horizontal: 3.w),
                        child: Text(
                          item.label,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

class _QuickItem {
  final String label;
  final IconData icon;
  final List<Color> colors;
  final Widget Function(BuildContext) builder;

  const _QuickItem({
    required this.label,
    required this.icon,
    required this.colors,
    required this.builder,
  });
}
