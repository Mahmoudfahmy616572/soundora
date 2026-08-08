import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/core/services/maqam_detector.dart';
import 'package:soundora/presentation/Maqam/cubit/maqam_cubit.dart';
import 'package:soundora/presentation/Maqam/maqam_catalog.dart';
import 'package:soundora/presentation/Maqam/maqam_discovery_page.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';
import 'package:soundora/serviece_locator.dart';

class MaqamDiscoverWidget extends StatefulWidget {
  const MaqamDiscoverWidget({super.key});

  @override
  State<MaqamDiscoverWidget> createState() => _MaqamDiscoverWidgetState();
}

class _MaqamDiscoverWidgetState extends State<MaqamDiscoverWidget> {
  MaqamResult? _maqam;
  StreamSubscription<dynamic>? _playerSub;

  @override
  void initState() {
    super.initState();
    _maqam = getIt<SongPlayerCubit>().currentMaqam;
    _playerSub = getIt<SongPlayerCubit>().stream.listen((_) {
      final next = getIt<SongPlayerCubit>().currentMaqam;
      if (next != _maqam && mounted) {
        setState(() => _maqam = next);
      }
    });
  }

  @override
  void dispose() {
    _playerSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final info = MaqamInfo.fromResult(_maqam);
    final accent = info?.color ?? AppColors.primaryColor;
    return GestureDetector(
      onTap: _openDiscovery,
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16.w),
        padding: EdgeInsets.all(16.w),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              accent.withOpacity(0.40),
              AppColors.primaryColor.withOpacity(0.20),
              const Color(0xFF1C1C2E),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(16.r),
          border: Border.all(color: accent.withOpacity(0.35)),
        ),
        child: Row(
          children: [
            Container(
              width: 54.w,
              height: 54.w,
              decoration: BoxDecoration(
                color: accent,
                shape: BoxShape.circle,
              ),
              child: Icon(
                info?.icon ?? Icons.graphic_eq,
                color: const Color(0xFF121212),
                size: 28.sp,
              ),
            ),
            SizedBox(width: 14.w),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _maqam == null ? 'اكتشف مقامك' : 'مقامك الحالي',
                    style: TextStyle(
                      fontSize: 17.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(height: 3.h),
                  Text(
                    _maqam == null
                        ? 'المقامات الثمانية وأغانيها في مكان واحد'
                        : '${info?.arabicName ?? _maqam!.englishName} · الثقة ${(_maqam!.confidence * 100).round()}%',
                    style: TextStyle(fontSize: 12.sp, color: Colors.white70),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Container(
              padding: EdgeInsets.symmetric(horizontal: 12.w, vertical: 8.h),
              decoration: BoxDecoration(
                color: accent.withOpacity(0.25),
                borderRadius: BorderRadius.circular(24.r),
              ),
              child: Text(
                'استكشف',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.bold,
                  color: accent,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _openDiscovery() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => BlocProvider(
          create: (_) => MaqamCubit(),
          child: const MaqamDiscoveryPage(),
        ),
      ),
    );
  }
}
