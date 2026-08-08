import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/presentation/CategoryPage/category_screen.dart';

class PodcastsSectionWidget extends StatelessWidget {
  const PodcastsSectionWidget({super.key});

  static const List<Map<String, dynamic>> _podcasts = [
    {'name': 'Joe Rogan', 'imageUrl': '', 'type': 'Comedy'},
    {'name': 'Lex Fridman', 'imageUrl': '', 'type': 'Technology'},
    {'name': 'Huberman Lab', 'imageUrl': '', 'type': 'Science'},
    {'name': 'The Daily', 'imageUrl': '', 'type': 'News'},
    {'name': 'Crime Junkie', 'imageUrl': '', 'type': 'True Crime'},
    {'name': 'TED Talks', 'imageUrl': '', 'type': 'Education'},
    {'name': 'Serial', 'imageUrl': '', 'type': 'Storytelling'},
    {'name': 'Radiolab', 'imageUrl': '', 'type': 'Science'},
  ];

  static const List<Color> _colors = [
    Color(0xFFE91E63),
    Color(0xFF9C27B0),
    Color(0xFF3F51B5),
    Color(0xFF009688),
    Color(0xFFFF5722),
    Color(0xFF795548),
    Color(0xFF607D8B),
    Color(0xFFFF9800),
  ];

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: EdgeInsets.symmetric(horizontal: 16.w),
          child: Text(
            'Podcasts',
            style: TextStyle(
              fontSize: 20.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ),
        SizedBox(height: 12.h),
        SizedBox(
          height: 160.h,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: EdgeInsets.symmetric(horizontal: 16.w),
            itemCount: _podcasts.length,
            separatorBuilder: (_, __) => SizedBox(width: 12.w),
            itemBuilder: (context, index) {
              final podcast = _podcasts[index];
              return GestureDetector(
                onTap: () {
                  Navigator.push(context, MaterialPageRoute(
                    builder: (_) => CategoryScreen(
                      categoryName: '${podcast['name']} - ${podcast['type']}',
                      categoryColor: _colors[index % _colors.length],
                      categoryIcon: Icons.podcasts,
                    ),
                  ));
                },
                child: SizedBox(
                  width: 120.w,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        width: 120.w,
                        height: 120.w,
                        decoration: BoxDecoration(
                          color: _colors[index % _colors.length].withOpacity(0.2),
                          borderRadius: BorderRadius.circular(12.r),
                        ),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(
                              Icons.podcasts,
                              color: _colors[index % _colors.length],
                              size: 36.sp,
                            ),
                            SizedBox(height: 6.h),
                            Text(
                              podcast['type'] as String,
                              style: TextStyle(
                                fontSize: 10.sp,
                                color: Colors.white54,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 6.h),
                      Text(
                        podcast['name'] as String,
                        style: TextStyle(
                          fontSize: 12.sp,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
