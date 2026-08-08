import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/data/sources/listening_history/listening_data_source.dart';
import 'package:soundora/presentation/TimeCapsule/cubit/time_capsule_cubit.dart';

class TimeCapsuleSheet extends StatefulWidget {
  const TimeCapsuleSheet({super.key});

  @override
  State<TimeCapsuleSheet> createState() => _TimeCapsuleSheetState();
}

class _TimeCapsuleSheetState extends State<TimeCapsuleSheet> {
  @override
  void initState() {
    super.initState();
    context.read<TimeCapsuleCubit>().loadCapsule();
  }

  static const _gold = Color(0xFFC9A96A);

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<TimeCapsuleCubit, TimeCapsuleState>(
      builder: (context, state) {
        if (state.isLoading) {
          return const SizedBox(
            height: 260,
            child: Center(child: CircularProgressIndicator()),
          );
        }
        final memories = state.todayMemories;
        final lastYear = state.thisDayLastYear;

        return Padding(
          padding: EdgeInsets.fromLTRB(24.w, 8.h, 24.w, 32.h),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 36,
                    height: 4,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                SizedBox(height: 20.h),
                Center(
                  child: Text(
                    'ðŸ•°ï¸ ÙƒØ¨Ø³ÙˆÙ„Ø© Ø²Ù…Ù†ÙŠØ©',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Center(
                  child: Text(
                    'ÙÙŠ Ù…Ø«Ù„ Ù‡Ø°Ø§ Ø§Ù„ÙŠÙˆÙ…',
                    style: TextStyle(
                      fontSize: 13.sp,
                      color: Colors.white.withOpacity(0.5),
                      fontFamily: 'Satoshi',
                    ),
                  ),
                ),
                SizedBox(height: 24.h),

                if (lastYear.isNotEmpty) ...[
                  _SectionLabel('Ø§Ù„Ø°ÙƒØ±Ù‰ Ø§Ù„Ø£Ø«Ù…Ù† â€” Ù‚Ø¨Ù„ Ø¹Ø§Ù…'),
                  SizedBox(height: 12.h),
                  ...lastYear.take(3).map(
                        (e) => _MemoryTile(event: e, gold: _gold),
                      ),
                  SizedBox(height: 24.h),
                ],

                if (memories.isNotEmpty) ...[
                  _SectionLabel(
                    'Ø§Ù„ÙŠÙˆÙ… â€” ${memories.length} Ø§Ø³ØªÙ…Ø§Ø¹',
                  ),
                  SizedBox(height: 12.h),
                  ...memories.take(4).map((e) => _MemoryTile(event: e, gold: _gold)),
                  SizedBox(height: 24.h),
                ],

                _YearSummaryCard(state: state, gold: _gold),

                if (memories.isEmpty && lastYear.isEmpty) ...[
                  SizedBox(height: 12.h),
                  Center(
                    child: Text(
                      'Ù„Ø§ ØªÙˆØ¬Ø¯ Ø°ÙƒØ±ÙŠØ§Øª Ø¨Ø¹Ø¯â€¦\nØ§Ø¨Ø¯Ø£ Ø¨Ø§Ù„Ø§Ø³ØªÙ…Ø§Ø¹ ÙˆØ³Ù†Ø­ÙØ¸ Ø§Ù„Ù„Ø­Ø¸Ø§Øª Ù„Ùƒ.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.white.withOpacity(0.5),
                        height: 1.6,
                        fontFamily: 'Satoshi',
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _SectionLabel extends StatelessWidget {
  final String text;
  const _SectionLabel(this.text);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(width: 20, height: 2, color: _TimeCapsuleSheetState._gold),
        const SizedBox(width: 8),
        Text(
          text,
          style: TextStyle(
            fontSize: 13.sp,
            fontWeight: FontWeight.w700,
            color: _TimeCapsuleSheetState._gold,
            fontFamily: 'Satoshi',
          ),
        ),
      ],
    );
  }
}

class _MemoryTile extends StatelessWidget {
  final PlayEvent event;
  final Color gold;
  const _MemoryTile({required this.event, required this.gold});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: EdgeInsets.only(bottom: 10.h),
      padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 14.h),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.05),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withOpacity(0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: gold.withOpacity(0.15),
              border: Border.all(color: gold.withOpacity(0.4)),
            ),
            child: Icon(
              event.wasSkipped ? Icons.skip_next_rounded : Icons.music_note,
              color: gold,
              size: 20,
            ),
          ),
          SizedBox(width: 14.w),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  event.title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                    fontFamily: 'Satoshi',
                  ),
                ),
                SizedBox(height: 3.h),
                Text(
                  '${event.artist}  â€¢  ${event.timestamp.year}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.white.withOpacity(0.5),
                    fontFamily: 'Satoshi',
                  ),
                ),
              ],
            ),
          ),
          Text(
            event.listenedDuration.inSeconds >= 60
                ? '${event.listenedDuration.inMinutes} Ø¯'
                : '${event.listenedDuration.inSeconds} Ø«',
            style: TextStyle(
              fontSize: 12.sp,
              color: gold.withOpacity(0.8),
              fontFamily: 'Satoshi',
            ),
          ),
        ],
      ),
    );
  }
}

class _YearSummaryCard extends StatelessWidget {
  final TimeCapsuleState state;
  final Color gold;
  const _YearSummaryCard({required this.state, required this.gold});

  @override
  Widget build(BuildContext context) {
    final days = state.yearSummary;
    if (days.isEmpty) return const SizedBox.shrink();
    final topDays = days.entries.toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final top = topDays.take(3);

    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(20.w),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            gold.withOpacity(0.12),
            Colors.white.withOpacity(0.03),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: gold.withOpacity(0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Ù…Ù„Ø®Øµ Ø§Ù„Ø¹Ø§Ù… Ø§Ù„Ù…Ø§Ø¶ÙŠ',
            style: TextStyle(
              fontSize: 15.sp,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              fontFamily: 'Satoshi',
            ),
          ),
          SizedBox(height: 12.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _Stat(icon: Icons.calendar_month, value: '${days.length}', label: 'Ø£ÙŠØ§Ù…'),
              _Stat(icon: Icons.graphic_eq, value: '${days.values.reduce((a, b) => a + b)}', label: 'Ø§Ø³ØªÙ…Ø§Ø¹'),
              _Stat(icon: Icons.star, value: '${topDays.length}', label: 'Ø£Ø¨Ø±Ø² Ù„Ø­Ø¸Ø©'),
            ],
          ),
          SizedBox(height: 14.h),
          ...top.map((e) {
            final month = e.key.split('-')[0];
            final day = e.key.split('-')[1];
            return Padding(
              padding: EdgeInsets.only(top: 4.h),
              child: Row(
                children: [
                  Icon(Icons.local_fire_department, size: 14, color: gold),
                  SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$day/$month',
                      style: TextStyle(
                        fontSize: 12.sp,
                        color: Colors.white.withOpacity(0.7),
                        fontFamily: 'Satoshi',
                      ),
                    ),
                  ),
                  Text(
                    '${e.value} Ø§Ø³ØªÙ…Ø§Ø¹',
                    style: TextStyle(
                      fontSize: 12.sp,
                      color: gold,
                      fontWeight: FontWeight.w600,
                      fontFamily: 'Satoshi',
                    ),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}

class _Stat extends StatelessWidget {
  final IconData icon;
  final String value;
  final String label;
  const _Stat({required this.icon, required this.value, required this.label});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, color: _TimeCapsuleSheetState._gold, size: 20),
        SizedBox(height: 6),
        Text(
          value,
          style: TextStyle(
            fontSize: 16.sp,
            fontWeight: FontWeight.w800,
            color: Colors.white,
            fontFamily: 'Satoshi',
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 11.sp,
            color: Colors.white.withOpacity(0.5),
            fontFamily: 'Satoshi',
          ),
        ),
      ],
    );
  }
}
