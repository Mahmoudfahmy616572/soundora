import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/presentation/CategoryPage/category_screen.dart';
import 'package:soundora/presentation/MoodMap/cubit/mood_map_cubit.dart';
import 'package:soundora/presentation/MoodMap/mood_map_page.dart';
import 'package:soundora/serviece_locator.dart';

class HeroSection extends StatefulWidget {
  const HeroSection({super.key});

  @override
  State<HeroSection> createState() => _HeroSectionState();
}

class _HeroSectionState extends State<HeroSection>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 6),
    )..repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'قعدة سهر متأخرة';
    if (hour < 12) return 'صباح الخير';
    if (hour < 17) return 'نهارك سعيد';
    return 'مساء الخير';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 5) return '🌙';
    if (hour < 12) return '☀️';
    if (hour < 17) return '🌤️';
    return '🌙';
  }

  String _getSubGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 5) return 'هدّي بالك وقولنا إيه اللي يريّحك؟';
    if (hour < 12) return 'إيه اللي يبدأ يومك معاك النهارده؟';
    if (hour < 17) return 'لسه بدرّي… حدد مزاجك ونبدأ';
    return 'بعد يوم طويل… حان وقت الاسترخاء';
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final drift = math.sin(_controller.value * 2 * math.pi);
        return Container(
          width: double.infinity,
          margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(24.r),
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [Color(0xFF1E1B33), Color(0xFF12121E), Color(0xFF181326)],
            ),
          ),
          child: Stack(
            children: [
              _buildAuraOrb(
                top: -60.h,
                right: -80.w + drift * 30.w,
                size: 260.w,
                color: AppColors.primaryColor.withOpacity(0.45),
              ),
              _buildAuraOrb(
                bottom: -90.h,
                left: -60.w - drift * 24.w,
                size: 240.w,
                color: AppColors.primaryLight.withOpacity(0.30),
              ),
              Positioned(
                top: 30.h,
                right: 22.w,
                child: Icon(
                  Icons.graphic_eq,
                  size: 34.sp,
                  color: Colors.white.withOpacity(0.06),
                ),
              ),
              Padding(
                padding: EdgeInsets.all(20.r),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Text(
                          _getGreetingEmoji(),
                          style: TextStyle(fontSize: 26.sp),
                        ),
                        SizedBox(width: 10.w),
                        Expanded(
                          child: Text(
                            _getGreeting(),
                            style: TextStyle(
                              fontSize: 24.sp,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                              fontFamily: 'Satoshi',
                            ),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 6.h),
                    Text(
                      _getSubGreeting(),
                      style: TextStyle(
                        fontSize: 13.5.sp,
                        color: Colors.white70,
                        height: 1.4,
                      ),
                    ),
                    SizedBox(height: 18.h),
                    _buildQuickChips(context),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAuraOrb({
    double? top,
    double? bottom,
    double? left,
    double? right,
    required double size,
    required Color color,
  }) {
    return Positioned(
      top: top,
      bottom: bottom,
      left: left,
      right: right,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(
            colors: [color, color.withOpacity(0)],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickChips(BuildContext context) {
    final chips = [
      {'label': 'الأغاني', 'icon': Icons.music_note, 'color': AppColors.primaryColor},
      {'label': 'القرآن', 'icon': Icons.menu_book, 'color': const Color(0xFF4CAF50)},
      {'label': 'بودكاست', 'icon': Icons.podcasts, 'color': const Color(0xFF9C27B0)},
      {'label': 'المزاج', 'icon': Icons.mood, 'color': const Color(0xFFFF9800)},
      {'label': 'الفنانين', 'icon': Icons.person, 'color': const Color(0xFF2196F3)},
    ];

    return SizedBox(
      height: 40.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final chip = chips[index];
          return GestureDetector(
            onTap: () {
              if (chip['label'] == 'المزاج') {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => getIt<MoodMapCubit>(),
                      child: const MoodMapPage(),
                    ),
                  ),
                );
              } else {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => CategoryScreen(
                      categoryName: chip['label'] as String,
                      categoryColor: chip['color'] as Color,
                      categoryIcon: chip['icon'] as IconData,
                    ),
                  ),
                );
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 15.w, vertical: 9.h),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.06),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: (chip['color'] as Color).withOpacity(0.35),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    chip['icon'] as IconData,
                    color: chip['color'] as Color,
                    size: 15.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    chip['label'] as String,
                    style: TextStyle(
                      fontSize: 12.5.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
