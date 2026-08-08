import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/core/widgets/music_loading_widget.dart';
import 'package:soundora/presentation/Gamification/cubit/achievement_cubit.dart';
import 'package:soundora/presentation/Gamification/cubit/achievement_state.dart';

class AchievementsPage extends StatefulWidget {
  const AchievementsPage({super.key});

  @override
  State<AchievementsPage> createState() => _AchievementsPageState();
}

class _AchievementsPageState extends State<AchievementsPage> {
  @override
  void initState() {
    super.initState();
    context.read<AchievementCubit>().loadAchievements();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF121212),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Achievements',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: BlocBuilder<AchievementCubit, AchievementState>(
        builder: (context, state) {
          if (state is AchievementLoading) {
            return const Center(child: MusicLoadingWidget(message: 'Loading achievements...'));
          }
          if (state is AchievementFailure) {
            return Center(
              child: Text(
                state.message,
                style: TextStyle(color: Colors.white, fontSize: 16.sp),
              ),
            );
          }
          if (state is AchievementLoaded) {
            return _buildContent(state);
          }
          return const SizedBox.shrink();
        },
      ),
    );
  }

  Widget _buildContent(AchievementLoaded state) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16.w),
      child: Column(
        children: [
          _buildLevelCard(state),
          SizedBox(height: 20.h),
          _buildProgressSummary(state),
          SizedBox(height: 24.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'All Achievements',
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 16.h),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12.w,
              mainAxisSpacing: 12.h,
              childAspectRatio: 0.85,
            ),
            itemCount: state.achievements.length,
            itemBuilder: (context, index) {
              return _buildAchievementCard(state.achievements[index]);
            },
          ),
          SizedBox(height: 20.h),
        ],
      ),
    );
  }

  Widget _buildLevelCard(AchievementLoaded state) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primaryDark, AppColors.primaryColor],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16.r),
      ),
      child: Column(
        children: [
          Container(
            width: 70.w,
            height: 70.w,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withOpacity(0.2),
              border: Border.all(color: Colors.white, width: 2),
            ),
            child: Center(
              child: Text(
                '${state.level}',
                style: TextStyle(
                  fontSize: 28.sp,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 12.h),
          Text(
            'Level ${state.level}',
            style: TextStyle(
              fontSize: 22.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${state.totalXp} XP earned',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.white70,
            ),
          ),
          SizedBox(height: 12.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(6.r),
            child: LinearProgressIndicator(
              value: (state.totalXp % 500) / 500,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
              minHeight: 8.h,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            '${500 - (state.totalXp % 500)} XP to next level',
            style: TextStyle(
              fontSize: 12.sp,
              color: Colors.white60,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressSummary(AchievementLoaded state) {
    return Row(
      children: [
        _buildStatBox(
          '${state.unlockedCount}',
          'Unlocked',
          Icons.emoji_events,
        ),
        SizedBox(width: 12.w),
        _buildStatBox(
          '${state.achievements.length - state.unlockedCount}',
          'Remaining',
          Icons.lock_outline,
        ),
        SizedBox(width: 12.w),
        _buildStatBox(
          '${state.totalXp}',
          'Total XP',
          Icons.bolt,
        ),
      ],
    );
  }

  Widget _buildStatBox(String value, String label, IconData icon) {
    return Expanded(
      child: Container(
        padding: EdgeInsets.symmetric(vertical: 14.h),
        decoration: BoxDecoration(
          color: Colors.grey[900],
          borderRadius: BorderRadius.circular(12.r),
        ),
        child: Column(
          children: [
            Icon(icon, color: AppColors.primaryColor, size: 22.sp),
            SizedBox(height: 6.h),
            Text(
              value,
              style: TextStyle(
                fontSize: 20.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
            SizedBox(height: 2.h),
            Text(
              label,
              style: TextStyle(
                fontSize: 11.sp,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAchievementCard(dynamic achievement) {
    final isUnlocked = achievement.isUnlocked;
    return Container(
      padding: EdgeInsets.all(14.w),
      decoration: BoxDecoration(
        color: isUnlocked
            ? AppColors.primaryColor.withOpacity(0.15)
            : Colors.grey[900],
        borderRadius: BorderRadius.circular(14.r),
        border: Border.all(
          color: isUnlocked
              ? AppColors.primaryColor.withOpacity(0.5)
              : Colors.grey[800]!,
          width: 1,
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            achievement.icon,
            style: TextStyle(
              fontSize: 36.sp,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            achievement.title,
            style: TextStyle(
              fontSize: 13.sp,
              fontWeight: FontWeight.bold,
              color: isUnlocked ? Colors.white : Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 4.h),
          Text(
            achievement.description,
            style: TextStyle(
              fontSize: 10.sp,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          SizedBox(height: 8.h),
          ClipRRect(
            borderRadius: BorderRadius.circular(4.r),
            child: LinearProgressIndicator(
              value: achievement.progress,
              backgroundColor: Colors.grey[800],
              valueColor: AlwaysStoppedAnimation(
                isUnlocked ? Colors.green : AppColors.primaryColor,
              ),
              minHeight: 4.h,
            ),
          ),
          SizedBox(height: 4.h),
          Text(
            isUnlocked
                ? 'Unlocked!'
                : '${achievement.currentProgress}/${achievement.requiredValue}',
            style: TextStyle(
              fontSize: 10.sp,
              color: isUnlocked ? Colors.green : Colors.grey,
              fontWeight: isUnlocked ? FontWeight.bold : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
