import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/core/widgets/shimmer_widgets.dart';
import 'package:soundora/presentation/TimeMachine/cubit/time_machine_cubit.dart';
import 'package:soundora/presentation/TimeMachine/cubit/time_machine_state.dart';

class TimeMachinePage extends StatefulWidget {
  const TimeMachinePage({super.key});

  @override
  State<TimeMachinePage> createState() => _TimeMachinePageState();
}

class _TimeMachinePageState extends State<TimeMachinePage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int? _selectedDecade;

  final List<int> _decades = [1960, 1970, 1980, 1990, 2000, 2010, 2020];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    context.read<TimeMachineCubit>().loadOnThisDay();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
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
          'Time Machine',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          dividerColor: Colors.transparent,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primaryColor,
          tabs: [
            Tab(text: 'On This Day'),
            Tab(text: 'Decades'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOnThisDay(),
          _buildDecadesBrowser(),
        ],
      ),
    );
  }

  Widget _buildOnThisDay() {
    final now = DateTime.now();
    const months = [
      '', 'January', 'February', 'March', 'April', 'May', 'June',
      'July', 'August', 'September', 'October', 'November', 'December',
    ];
    final dateStr = '${months[now.month]} ${now.day}';

    return BlocBuilder<TimeMachineCubit, TimeMachineState>(
      buildWhen: (prev, curr) => curr is OnThisDayLoaded || curr is TimeMachineLoading || curr is TimeMachineFailure,
      builder: (context, state) {
        if (state is TimeMachineLoading) {
          return const SongListShimmer();
        }
        if (state is TimeMachineFailure) {
          return Center(
            child: Text(
              state.message,
              style: TextStyle(color: Colors.white, fontSize: 16.sp),
            ),
          );
        }
        if (state is OnThisDayLoaded) {
          return Column(
            children: [
              Container(
                margin: EdgeInsets.all(16.w),
                padding: EdgeInsets.all(16.w),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      AppColors.primaryColor.withOpacity(0.3),
                      AppColors.primaryDark.withOpacity(0.3),
                    ],
                  ),
                  borderRadius: BorderRadius.circular(14.r),
                ),
                child: Row(
                  children: [
                    Icon(Icons.calendar_today,
                        color: AppColors.primaryColor, size: 28.sp),
                    SizedBox(width: 12.w),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'On This Day',
                          style: TextStyle(
                            fontSize: 18.sp,
                            fontWeight: FontWeight.bold,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          dateStr,
                          style: TextStyle(
                            fontSize: 13.sp,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: state.songs.isEmpty
                    ? Center(
                        child: Text(
                          'No songs found for this day',
                          style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                        ),
                      )
                    : ListView.separated(
                        padding: EdgeInsets.symmetric(horizontal: 16.w),
                        itemCount: state.songs.length,
                        separatorBuilder: (_, __) => SizedBox(height: 8.h),
                        itemBuilder: (context, index) {
                          final song = state.songs[index];
                          return _buildSongTile(song, index + 1);
                        },
                      ),
              ),
            ],
          );
        }
        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildDecadesBrowser() {
    return Column(
      children: [
        SizedBox(
          height: 56.h,
          child: ListView.separated(
            padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 10.h),
            scrollDirection: Axis.horizontal,
            itemCount: _decades.length,
            separatorBuilder: (_, __) => SizedBox(width: 8.w),
            itemBuilder: (context, index) {
              final decade = _decades[index];
              final isSelected = _selectedDecade == decade;
              return GestureDetector(
                onTap: () {
                  setState(() => _selectedDecade = decade);
                  context.read<TimeMachineCubit>().loadDecade(decade);
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  padding: EdgeInsets.symmetric(horizontal: 18.w),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primaryColor
                        : Colors.grey[900],
                    borderRadius: BorderRadius.circular(20.r),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primaryColor
                          : Colors.grey[800]!,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      "${decade}s",
                      style: TextStyle(
                        fontSize: 14.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        SizedBox(height: 8.h),
        Expanded(
          child: BlocBuilder<TimeMachineCubit, TimeMachineState>(
            buildWhen: (prev, curr) =>
                curr is DecadeLoaded || curr is TimeMachineLoading || curr is TimeMachineFailure,
            builder: (context, state) {
              if (state is TimeMachineLoading) {
                return const SongListShimmer();
              }
              if (state is TimeMachineFailure) {
                return Center(
                  child: Text(
                    state.message,
                    style: TextStyle(color: Colors.white, fontSize: 14.sp),
                  ),
                );
              }
              if (state is DecadeLoaded) {
                if (state.songs.isEmpty) {
                  return Center(
                    child: Text(
                      'No songs found for this decade',
                      style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                    ),
                  );
                }
                return ListView.separated(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  itemCount: state.songs.length,
                  separatorBuilder: (_, __) => SizedBox(height: 8.h),
                  itemBuilder: (context, index) {
                    return _buildSongTile(state.songs[index], index + 1);
                  },
                );
              }
              return Center(
                child: Text(
                  'Select a decade to explore',
                  style: TextStyle(color: Colors.grey, fontSize: 14.sp),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildSongTile(dynamic song, int index) {
    return Container(
      padding: EdgeInsets.all(10.w),
      decoration: BoxDecoration(
        color: Colors.grey[900],
        borderRadius: BorderRadius.circular(10.r),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 28.w,
            child: Text(
              '$index',
              style: TextStyle(
                fontSize: 14.sp,
                fontWeight: FontWeight.bold,
                color: AppColors.primaryColor,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          SizedBox(width: 10.w),
          ClipRRect(
            borderRadius: BorderRadius.circular(8.r),
            child: CachedNetworkImage(
              imageUrl: song.imageUrl,
              width: 46.w,
              height: 46.w,
              fit: BoxFit.cover,
              errorWidget: (_, __, ___) => Container(
                width: 46.w,
                height: 46.w,
                color: Colors.grey[800],
                child: Icon(Icons.music_note, color: Colors.grey, size: 20.sp),
              ),
            ),
          ),
          SizedBox(width: 12.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  song.title,
                  style: TextStyle(
                    fontSize: 13.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                SizedBox(height: 2.h),
                Text(
                  song.artist,
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          Icon(Icons.history, color: Colors.grey[600], size: 18.sp),
        ],
      ),
    );
  }
}
