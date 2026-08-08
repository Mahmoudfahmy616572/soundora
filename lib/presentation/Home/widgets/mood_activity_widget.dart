import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/presentation/MoodMap/cubit/mood_map_cubit.dart';
import 'package:soundora/presentation/MoodMap/mood_map_page.dart';
import 'package:soundora/serviece_locator.dart';

class MoodActivityWidget extends StatelessWidget {
  const MoodActivityWidget({super.key});

  static const List<Map<String, dynamic>> _moods = [
    {'name': 'Workout', 'icon': Icons.fitness_center, 'gradient': [Color(0xFFFF6B35), Color(0xFFD32F2F)]},
    {'name': 'Chill', 'icon': Icons.spa, 'gradient': [Color(0xFF00BCD4), Color(0xFF006064)]},
    {'name': 'Party', 'icon': Icons.celebration, 'gradient': [Color(0xFFE91E63), Color(0xFF880E4F)]},
    {'name': 'Focus', 'icon': Icons.psychology, 'gradient': [Color(0xFF7B1FA2), Color(0xFF311B92)]},
    {'name': 'Sleep', 'icon': Icons.nights_stay, 'gradient': [Color(0xFF303F9F), Color(0xFF1A237E)]},
    {'name': 'Romance', 'icon': Icons.favorite, 'gradient': [Color(0xFFE91E63), Color(0xFFAD1457)]},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Mood & Activity',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 100.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _moods.length,
            separatorBuilder: (_, __) => SizedBox(width: 10.w),
            itemBuilder: (context, index) {
              final mood = _moods[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => BlocProvider(
                      create: (_) => getIt<MoodMapCubit>(),
                      child: const MoodMapPage(),
                    ),
                  ));
                },
                child: Container(
                  width: 100.w,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: mood['gradient'] as List<Color>,
                    ),
                    borderRadius: BorderRadius.circular(14.r),
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        mood['icon'] as IconData,
                        color: Colors.white,
                        size: 28.sp,
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        mood['name'] as String,
                        style: TextStyle(
                          fontSize: 12.sp,
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
        ),
      ],
    );
  }
}
