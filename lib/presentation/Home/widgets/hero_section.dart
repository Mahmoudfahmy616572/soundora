import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/presentation/CategoryPage/category_screen.dart';
import 'package:soundora/presentation/MoodMap/cubit/mood_map_cubit.dart';
import 'package:soundora/presentation/MoodMap/mood_map_page.dart';
import 'package:soundora/serviece_locator.dart';

class HeroSection extends StatelessWidget {
  const HeroSection({super.key});

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }

  String _getGreetingEmoji() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'â˜€ï¸';
    if (hour < 17) return 'ðŸŒ¤ï¸';
    return 'ðŸŒ™';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: EdgeInsets.fromLTRB(16.w, 8.h, 16.w, 0),
      padding: EdgeInsets.all(20.r),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20.r),
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppColors.primaryColor.withOpacity(0.4),
            AppColors.primaryDark.withOpacity(0.2),
            const Color(0xFF1A1A2E),
          ],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                _getGreetingEmoji(),
                style: TextStyle(fontSize: 24.sp),
              ),
              SizedBox(width: 8.w),
              Text(
                _getGreeting(),
                style: TextStyle(
                  fontSize: 22.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          SizedBox(height: 4.h),
          Text(
            'What do you want to listen to?',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white60,
            ),
          ),
          SizedBox(height: 16.h),
          _buildQuickChips(context),
        ],
      ),
    );
  }

  Widget _buildQuickChips(BuildContext context) {
    final chips = [
      {'label': 'Songs', 'icon': Icons.music_note, 'color': AppColors.primaryColor},
      {'label': 'Quran', 'icon': Icons.menu_book, 'color': const Color(0xFF4CAF50)},
      {'label': 'Podcasts', 'icon': Icons.podcasts, 'color': const Color(0xFF9C27B0)},
      {'label': 'Mood', 'icon': Icons.sentiment_satisfied, 'color': const Color(0xFFFF9800)},
      {'label': 'Artists', 'icon': Icons.person, 'color': const Color(0xFF2196F3)},
    ];

    return SizedBox(
      height: 44.h,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        itemCount: chips.length,
        separatorBuilder: (_, __) => SizedBox(width: 8.w),
        itemBuilder: (context, index) {
          final chip = chips[index];
          return GestureDetector(
            onTap: () {
              if (chip['label'] == 'Mood') {
                Navigator.push(context, MaterialPageRoute(builder: (_) => BlocProvider(create: (_) => getIt<MoodMapCubit>(), child: const MoodMapPage())));
              } else {
                Navigator.push(context, MaterialPageRoute(
                  builder: (_) => CategoryScreen(
                    categoryName: chip['label'] as String,
                    categoryColor: chip['color'] as Color,
                    categoryIcon: chip['icon'] as IconData,
                  ),
                ));
              }
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: (chip['color'] as Color).withOpacity(0.15),
                borderRadius: BorderRadius.circular(22.r),
                border: Border.all(
                  color: (chip['color'] as Color).withOpacity(0.3),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(chip['icon'] as IconData, color: chip['color'] as Color, size: 16.sp),
                  SizedBox(width: 6.w),
                  Text(
                    chip['label'] as String,
                    style: TextStyle(
                      fontSize: 13.sp,
                      fontWeight: FontWeight.w500,
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
