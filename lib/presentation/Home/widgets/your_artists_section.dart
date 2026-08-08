import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/presentation/CategoryPage/category_screen.dart';

class YourArtistsSection extends StatelessWidget {
  const YourArtistsSection({super.key});

  static const List<Map<String, dynamic>> _artists = [
    {'name': 'The Weeknd', 'imageUrl': '', 'genre': 'Pop'},
    {'name': 'Arctic Monkeys', 'imageUrl': '', 'genre': 'Rock'},
    {'name': 'Travis Scott', 'imageUrl': '', 'genre': 'Hip-Hop'},
    {'name': 'Billie Eilish', 'imageUrl': '', 'genre': 'Pop'},
    {'name': 'Pink Floyd', 'imageUrl': '', 'genre': 'Rock'},
    {'name': 'Drake', 'imageUrl': '', 'genre': 'Hip-Hop'},
    {'name': 'Daft Punk', 'imageUrl': '', 'genre': 'Electronic'},
    {'name': 'Adele', 'imageUrl': '', 'genre': 'Pop'},
  ];

  static const List<Color> _colors = [
    Color(0xFFE91E63),
    Color(0xFF3F51B5),
    Color(0xFFFF9800),
    Color(0xFF9C27B0),
    Color(0xFF607D8B),
    Color(0xFFFF5722),
    Color(0xFF00BCD4),
    Color(0xFF8D6E63),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Your Artists',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 140.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _artists.length,
            separatorBuilder: (_, __) => SizedBox(width: 16.w),
            itemBuilder: (context, index) {
              final artist = _artists[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CategoryScreen(
                      categoryName: artist['name'] as String,
                      categoryColor: _colors[index % _colors.length],
                      categoryIcon: Icons.person,
                    ),
                  ));
                },
                child: SizedBox(
                  width: 80.w,
                  child: Column(
                    children: [
                      Container(
                        width: 72.w,
                        height: 72.w,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _colors[index % _colors.length],
                              _colors[index % _colors.length].withOpacity(0.5),
                            ],
                          ),
                        ),
                        child: Center(
                          child: Text(
                            (artist['name'] as String)[0],
                            style: TextStyle(
                              fontSize: 28.sp,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 8.h),
                      Text(
                        artist['name'] as String,
                        style: TextStyle(
                          fontSize: 11.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
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
