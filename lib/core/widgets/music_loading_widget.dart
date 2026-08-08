import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';

class MusicLoadingWidget extends StatefulWidget {
  final String? message;
  final double barCount;
  final Color color;

  const MusicLoadingWidget({
    super.key,
    this.message,
    this.barCount = 5,
    this.color = AppColors.primaryColor,
  });

  @override
  State<MusicLoadingWidget> createState() => _MusicLoadingWidgetState();
}

class _MusicLoadingWidgetState extends State<MusicLoadingWidget>
    with TickerProviderStateMixin {
  late final List<AnimationController> _controllers;
  late final List<Animation<double>> _animations;

  @override
  void initState() {
    super.initState();
    _controllers = List.generate(
      widget.barCount.toInt(),
      (index) => AnimationController(
        vsync: this,
        duration: Duration(milliseconds: 400 + (index * 100)),
      )..repeat(reverse: true),
    );
    _animations = _controllers.map((c) {
      return Tween<double>(begin: 0.3, end: 1.0).animate(
        CurvedAnimation(parent: c, curve: Curves.easeInOut),
      );
    }).toList();
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        SizedBox(
          height: 40.h,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: List.generate(widget.barCount.toInt(), (index) {
              return AnimatedBuilder(
                animation: _animations[index],
                builder: (context, child) {
                  return Container(
                    width: 4.w,
                    height: _animations[index].value * 32.h,
                    margin: EdgeInsets.symmetric(horizontal: 2.w),
                    decoration: BoxDecoration(
                      color: widget.color.withOpacity(_animations[index].value),
                      borderRadius: BorderRadius.circular(2.r),
                    ),
                  );
                },
              );
            }),
          ),
        ),
        if (widget.message != null) ...[
          SizedBox(height: 16.h),
          Text(
            widget.message!,
            style: TextStyle(
              color: Colors.grey,
              fontSize: 14.sp,
            ),
          ),
        ],
      ],
    );
  }
}
