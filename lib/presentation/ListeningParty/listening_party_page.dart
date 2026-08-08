import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/core/widgets/music_loading_widget.dart';
import 'package:soundora/presentation/ListeningParty/cubit/listening_party_cubit.dart';
import 'package:soundora/presentation/ListeningParty/cubit/listening_party_state.dart';
import 'package:soundora/presentation/songsPlayPage/cubit/song_player_cubit.dart';

class ListeningPartyPage extends StatefulWidget {
  const ListeningPartyPage({super.key});

  @override
  State<ListeningPartyPage> createState() => _ListeningPartyPageState();
}

class _ListeningPartyPageState extends State<ListeningPartyPage> {
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _codeController = TextEditingController();

  @override
  void dispose() {
    _nameController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  /// Keeps the real audio player in sync with the party state, on every
  /// device in the room, so everyone actually hears the same song.
  void _syncWithPlayer(BuildContext context, ListeningPartyActive state) {
    final player = context.read<SongPlayerCubit>();
    final currentSong = state.currentSong;
    if (currentSong == null) return;

    final alreadyCurrent = player.playList.isNotEmpty &&
        player.currentIndex < player.playList.length &&
        player.playList[player.currentIndex].id.toString() ==
            currentSong.id.toString();

    if (!alreadyCurrent) {
      player.loadSong(state.queue, state.currentIndex, currentSong.imageUrl);
      return;
    }
    if (state.isPlaying != player.audioPlayer.playing) {
      player.playOrpauseSong();
    }
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
          onPressed: () {
            context.read<ListeningPartyCubit>().leaveParty();
            Navigator.pop(context);
          },
        ),
        title: Text(
          'Listening Party',
          style: TextStyle(
            fontSize: 22.sp,
            fontWeight: FontWeight.bold,
            color: Colors.white,
          ),
        ),
      ),
      body: BlocConsumer<ListeningPartyCubit, ListeningPartyState>(
        listener: (context, state) {
          if (state is ListeningPartyError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: Colors.red[800],
              ),
            );
          }
          if (state is ListeningPartyActive) {
            _syncWithPlayer(context, state);
          }
        },
        builder: (context, state) {
          if (state is ListeningPartyLoading) {
            return const Center(
              child: MusicLoadingWidget(message: 'Joining party...'),
            );
          }
          if (state is ListeningPartyLobby) {
            return _buildLobby(state);
          }
          if (state is ListeningPartyActive) {
            return _buildActiveParty(state);
          }
          return _buildCreateJoinUI();
        },
      ),
    );
  }

  Widget _buildCreateJoinUI() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(height: 40.h),
          Icon(
            Icons.party_mode,
            size: 80.sp,
            color: AppColors.primaryColor,
          ),
          SizedBox(height: 20.h),
          Text(
            'Start a Listening Party',
            style: TextStyle(
              fontSize: 24.sp,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          SizedBox(height: 8.h),
          Text(
            'Listen to music together with friends in real-time',
            style: TextStyle(
              fontSize: 14.sp,
              color: Colors.grey,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 40.h),
          TextField(
            controller: _nameController,
            style: TextStyle(color: Colors.white, fontSize: 16.sp),
            decoration: InputDecoration(
              hintText: 'Your name',
              hintStyle: TextStyle(color: Colors.grey),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.primaryColor),
              ),
              prefixIcon: const Icon(Icons.person, color: Colors.grey),
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: ElevatedButton(
              onPressed: () {
                final name = _nameController.text.trim();
                if (name.isEmpty) return;
                context.read<ListeningPartyCubit>().createRoom(name);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primaryColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Create Room',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
          SizedBox(height: 24.h),
          Row(
            children: [
              Expanded(child: Divider(color: Colors.grey[800])),
              Padding(
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: Text(
                  'OR',
                  style: TextStyle(color: Colors.grey, fontSize: 12.sp),
                ),
              ),
              Expanded(child: Divider(color: Colors.grey[800])),
            ],
          ),
          SizedBox(height: 24.h),
          TextField(
            controller: _codeController,
            style: TextStyle(
              color: Colors.white,
              fontSize: 18.sp,
              letterSpacing: 4,
            ),
            textAlign: TextAlign.center,
            textCapitalization: TextCapitalization.characters,
            maxLength: 6,
            decoration: InputDecoration(
              hintText: 'ROOM CODE',
              hintStyle: TextStyle(color: Colors.grey, letterSpacing: 4),
              filled: true,
              fillColor: Colors.grey[900],
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: BorderSide.none,
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12.r),
                borderSide: const BorderSide(color: AppColors.primaryColor),
              ),
              prefixIcon: const Icon(Icons.vpn_key, color: Colors.grey),
              counterText: '',
            ),
          ),
          SizedBox(height: 16.h),
          SizedBox(
            width: double.infinity,
            height: 52.h,
            child: OutlinedButton(
              onPressed: () {
                final code = _codeController.text.trim();
                final name = _nameController.text.trim();
                if (code.isEmpty || name.isEmpty) return;
                context.read<ListeningPartyCubit>().joinRoom(code, name);
              },
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: AppColors.primaryColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12.r),
                ),
              ),
              child: Text(
                'Join Room',
                style: TextStyle(
                  fontSize: 16.sp,
                  fontWeight: FontWeight.w600,
                  color: AppColors.primaryColor,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLobby(ListeningPartyLobby state) {
    return SingleChildScrollView(
      padding: EdgeInsets.all(24.w),
      child: Column(
        children: [
          SizedBox(height: 20.h),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(24.w),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  AppColors.primaryColor.withOpacity(0.3),
                  AppColors.primaryDark.withOpacity(0.3),
                ],
              ),
              borderRadius: BorderRadius.circular(16.r),
              border: Border.all(
                color: AppColors.primaryColor.withOpacity(0.5),
              ),
            ),
            child: Column(
              children: [
                Text(
                  'ROOM CODE',
                  style: TextStyle(
                    fontSize: 12.sp,
                    color: Colors.grey,
                    letterSpacing: 3,
                  ),
                ),
                SizedBox(height: 8.h),
                GestureDetector(
                  onTap: () {
                    Clipboard.setData(
                        ClipboardData(text: state.roomCode));
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Room code copied!')),
                    );
                  },
                  child: Text(
                    state.roomCode,
                    style: TextStyle(
                      fontSize: 40.sp,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                      letterSpacing: 8,
                    ),
                  ),
                ),
                SizedBox(height: 4.h),
                Text(
                  'Tap to copy',
                  style: TextStyle(
                    fontSize: 11.sp,
                    color: Colors.grey,
                  ),
                ),
              ],
            ),
          ),
          SizedBox(height: 30.h),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Participants (${state.participants.length})',
              style: TextStyle(
                fontSize: 18.sp,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
          SizedBox(height: 12.h),
          ...state.participants.map((p) => Container(
                margin: EdgeInsets.only(bottom: 8.h),
                padding: EdgeInsets.all(14.w),
                decoration: BoxDecoration(
                  color: Colors.grey[900],
                  borderRadius: BorderRadius.circular(12.r),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 18.r,
                      backgroundColor: p.isHost
                          ? AppColors.primaryColor
                          : Colors.grey[700],
                      child: Text(
                        p.name.isNotEmpty ? p.name[0].toUpperCase() : '?',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 14.sp,
                        ),
                      ),
                    ),
                    SizedBox(width: 12.w),
                    Expanded(
                      child: Text(
                        p.name,
                        style: TextStyle(
                          fontSize: 16.sp,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (p.isHost)
                      Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 8.w, vertical: 3.h),
                        decoration: BoxDecoration(
                          color: AppColors.primaryColor.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(6.r),
                        ),
                        child: Text(
                          'HOST',
                          style: TextStyle(
                            fontSize: 10.sp,
                            fontWeight: FontWeight.bold,
                            color: AppColors.primaryColor,
                          ),
                        ),
                      ),
                  ],
                ),
              )),
          SizedBox(height: 40.h),
          if (state.isHost)
            SizedBox(
              width: double.infinity,
              height: 52.h,
              child: ElevatedButton(
                onPressed: () {
                  context.read<ListeningPartyCubit>().startParty();
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryColor,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12.r),
                  ),
                ),
                child: Text(
                  'Start Party',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            )
          else
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(16.w),
              decoration: BoxDecoration(
                color: Colors.grey[900],
                borderRadius: BorderRadius.circular(12.r),
              ),
              child: Text(
                'Waiting for host to start...',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14.sp,
                  color: Colors.grey,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildActiveParty(ListeningPartyActive state) {
    return Column(
      children: [
        Container(
          margin: EdgeInsets.all(16.w),
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          decoration: BoxDecoration(
            color: Colors.grey[900],
            borderRadius: BorderRadius.circular(10.r),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 8.w,
                height: 8.w,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.green,
                ),
              ),
              SizedBox(width: 8.w),
              Text(
                'LIVE  â€¢  ${state.participants.length} listening',
                style: TextStyle(
                  fontSize: 12.sp,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
        if (state.currentSong != null)
          Expanded(
            child: Center(
              child: Padding(
                padding: EdgeInsets.symmetric(horizontal: 40.w),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(16.r),
                      child: CachedNetworkImage(
                        imageUrl: state.currentSong!.imageUrl,
                        width: 260.w,
                        height: 260.w,
                        fit: BoxFit.cover,
                        errorWidget: (_, __, ___) => Container(
                          width: 260.w,
                          height: 260.w,
                          color: Colors.grey[800],
                          child: Icon(Icons.music_note,
                              color: Colors.grey, size: 60.sp),
                        ),
                      ),
                    ),
                    SizedBox(height: 24.h),
                    Text(
                      state.currentSong!.title,
                      style: TextStyle(
                        fontSize: 22.sp,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    SizedBox(height: 4.h),
                    Text(
                      state.currentSong!.artist,
                      style: TextStyle(
                        fontSize: 16.sp,
                        color: Colors.grey,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ),
          ),
        SafeArea(
          top: false,
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: 24.w, vertical: 12.h),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: Icon(Icons.skip_previous,
                      color: Colors.white, size: 36.sp),
                  onPressed: state.isHost
                      ? () =>
                          context.read<ListeningPartyCubit>().previousSong()
                      : null,
                ),
                SizedBox(width: 20.w),
                GestureDetector(
                  onTap: state.isHost
                      ? () =>
                          context.read<ListeningPartyCubit>().playPause()
                      : null,
                  child: Container(
                    width: 68.w,
                    height: 68.w,
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.primaryColor,
                    ),
                    child: Icon(
                      state.isPlaying ? Icons.pause : Icons.play_arrow,
                      color: Colors.white,
                      size: 36.sp,
                    ),
                  ),
                ),
                SizedBox(width: 20.w),
                IconButton(
                  icon: Icon(Icons.skip_next,
                      color: Colors.white, size: 36.sp),
                  onPressed: state.isHost
                      ? () =>
                          context.read<ListeningPartyCubit>().nextSong()
                      : null,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
