import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/presentation/SearchPage/search_page.dart';

class HomeGenresWidget extends StatelessWidget {
  const HomeGenresWidget({super.key});

  static final List<Map<String, dynamic>> _genres = [
    {'name': 'Pop', 'icon': Icons.star, 'color': const Color(0xFFE91E63)},
    {'name': 'Hip-Hop', 'icon': Icons.mic_external_on, 'color': const Color(0xFFFF9800)},
    {'name': 'Rock', 'icon': Icons.electric_bolt, 'color': const Color(0xFFF44336)},
    {'name': 'R&B', 'icon': Icons.favorite, 'color': const Color(0xFF9C27B0)},
    {'name': 'Electronic', 'icon': Icons.equalizer, 'color': const Color(0xFF00BCD4)},
    {'name': 'Jazz', 'icon': Icons.piano, 'color': const Color(0xFFFFEB3B)},
    {'name': 'Arabic', 'icon': Icons.language, 'color': const Color(0xFF4CAF50)},
    {'name': 'Latin', 'icon': Icons.local_fire_department, 'color': const Color(0xFFFF5722)},
    {'name': 'Classical', 'icon': Icons.music_note, 'color': const Color(0xFF607D8B)},
    {'name': 'K-Pop', 'icon': Icons.auto_awesome, 'color': const Color(0xFF3F51B5)},
    {'name': 'Country', 'icon': Icons.terrain, 'color': const Color(0xFF795548)},
    {'name': 'Indie', 'icon': Icons.blur_on, 'color': const Color(0xFF8BC34A)},
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Wrap(
        spacing: 10.w,
        runSpacing: 10.h,
        children: _genres.map((genre) {
          return GestureDetector(
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => SearchPage(initialQuery: genre['name'] as String),
                ),
              );
            },
            child: Container(
              padding: EdgeInsets.symmetric(horizontal: 14.w, vertical: 10.h),
              decoration: BoxDecoration(
                color: (genre['color'] as Color).withOpacity(0.12),
                borderRadius: BorderRadius.circular(20.r),
                border: Border.all(
                  color: (genre['color'] as Color).withOpacity(0.25),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    genre['icon'] as IconData,
                    color: genre['color'] as Color,
                    size: 16.sp,
                  ),
                  SizedBox(width: 6.w),
                  Text(
                    genre['name'] as String,
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
        }).toList(),
      ),
    );
  }
}
