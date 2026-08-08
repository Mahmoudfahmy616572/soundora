import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/presentation/CategoryPage/category_screen.dart';

class BrowseCategoriesWidget extends StatelessWidget {
  const BrowseCategoriesWidget({super.key});

  static const List<Map<String, dynamic>> _categories = [
    {'name': 'Pop', 'icon': Icons.star, 'color': Color(0xFFE91E63), 'gradient': [Color(0xFFE91E63), Color(0xFFAD1457)]},
    {'name': 'Hip-Hop', 'icon': Icons.mic_external_on, 'color': Color(0xFFFF9800), 'gradient': [Color(0xFFFF9800), Color(0xFFE65100)]},
    {'name': 'Rock', 'icon': Icons.electric_bolt, 'color': Color(0xFFF44336), 'gradient': [Color(0xFFF44336), Color(0xFFB71C1C)]},
    {'name': 'Quran', 'icon': Icons.menu_book, 'color': Color(0xFF4CAF50), 'gradient': [Color(0xFF4CAF50), Color(0xFF1B5E20)]},
    {'name': 'Podcasts', 'icon': Icons.podcasts, 'color': Color(0xFF9C27B0), 'gradient': [Color(0xFF9C27B0), Color(0xFF6A1B9A)]},
    {'name': 'R&B', 'icon': Icons.favorite, 'color': Color(0xFF7B1FA2), 'gradient': [Color(0xFF7B1FA2), Color(0xFF4A148C)]},
    {'name': 'Electronic', 'icon': Icons.equalizer, 'color': Color(0xFF00BCD4), 'gradient': [Color(0xFF00BCD4), Color(0xFF006064)]},
    {'name': 'Jazz', 'icon': Icons.piano, 'color': Color(0xFFFFC107), 'gradient': [Color(0xFFFFC107), Color(0xFFFF8F00)]},
    {'name': 'Arabic', 'icon': Icons.language, 'color': Color(0xFF8D6E63), 'gradient': [Color(0xFF8D6E63), Color(0xFF4E342E)]},
    {'name': 'Latin', 'icon': Icons.local_fire_department, 'color': Color(0xFFFF5722), 'gradient': [Color(0xFFFF5722), Color(0xFFBF360C)]},
    {'name': 'Classical', 'icon': Icons.music_note, 'color': Color(0xFF607D8B), 'gradient': [Color(0xFF607D8B), Color(0xFF263238)]},
    {'name': 'K-Pop', 'icon': Icons.auto_awesome, 'color': Color(0xFF3F51B5), 'gradient': [Color(0xFF3F51B5), Color(0xFF1A237E)]},
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(),
        SizedBox(height: 12.h),
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 10.w,
              mainAxisSpacing: 10.h,
              childAspectRatio: 1.6,
            ),
            itemCount: _categories.length,
            itemBuilder: (context, index) {
              final cat = _categories[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CategoryScreen(
                      categoryName: cat['name'] as String,
                      categoryColor: cat['color'] as Color,
                      categoryIcon: cat['icon'] as IconData,
                    ),
                  ));
                },
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: cat['gradient'] as List<Color>,
                    ),
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: -10.w,
                        right: -10.w,
                        child: Icon(
                          cat['icon'] as IconData,
                          color: Colors.white.withOpacity(0.15),
                          size: 60.sp,
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(12.r),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            Text(
                              cat['name'] as String,
                              style: TextStyle(
                                fontSize: 15.sp,
                                fontWeight: FontWeight.bold,
                                color: Colors.white,
                              ),
                            ),
                          ],
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

  Widget _buildSectionHeader() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.w),
      child: Text(
        'Browse',
        style: TextStyle(
          fontSize: 20.sp,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }
}
