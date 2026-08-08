import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart' show BlocBuilder, ReadContext;
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';
import 'package:soundora/presentation/Home/pages/home_page.dart';
import 'package:soundora/presentation/Home/widgets/miniPlayerBar/mini_player.dart';
import 'package:soundora/presentation/Library/library_page.dart';
import 'package:soundora/presentation/MainWrapper/cubit/cubit/navigation_cubit.dart';
import 'package:soundora/presentation/PremiumHub/premium_features_page.dart';

import '../SearchPage/search_page.dart';

class MainWrapper extends StatefulWidget {
  const MainWrapper({super.key});

  @override
  State<MainWrapper> createState() => _MainWrapperState();
}

class _MainWrapperState extends State<MainWrapper> {
  late final List<Widget> _screens;
  DateTime? _lastBackPress;

  @override
  void initState() {
    super.initState();
    _screens = const [
      HomePage(),
      SearchPage(),
      LibraryPage(),
      PremiumFeaturesPage(),
    ];
  }

  /// Back behaviour on the root screen:
  /// - from a non-Home tab it returns to Home instead of exiting,
  /// - on Home the first press warns the user, a second press within 2s exits.
  Future<bool> _handleBack() async {
    final nav = context.read<NavigationCubit>();
    if (nav.state != 0) {
      nav.updateIndex(0);
      return false;
    }

    final now = DateTime.now();
    if (_lastBackPress == null ||
        now.difference(_lastBackPress!) > const Duration(seconds: 2)) {
      _lastBackPress = now;
      final messenger = ScaffoldMessenger.of(context);
      messenger
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text('Press back again to exit'),
            duration: Duration(seconds: 2),
            behavior: SnackBarBehavior.floating,
          ),
        );
      return false;
    }

    _lastBackPress = null;
    return true;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _handleBack().then((shouldExit) {
          if (shouldExit) SystemNavigator.pop();
        });
      },
      child: BlocBuilder<NavigationCubit, int>(
        builder: (context, currentIndex) {
          return Scaffold(
            extendBody: true,
            body: Stack(
              children: [
                IndexedStack(
                  index: currentIndex,
                  children: _screens,
                ),
                Positioned(
                  bottom: kBottomNavigationBarHeight + 21.h,
                  left: 0,
                  right: 0,
                  child: const MiniPlayer(),
                )
              ],
            ),
            bottomNavigationBar: ClipRect(
                child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
              child: BottomNavigationBar(
                currentIndex: currentIndex,
                onTap: (value) {
                  context.read<NavigationCubit>().updateIndex(value);
                },
                backgroundColor: Colors.transparent,
                elevation: 0,
                selectedItemColor: AppColors.primaryColor,
                unselectedItemColor: Colors.white.withOpacity(0.7),
                items: const [
                  BottomNavigationBarItem(
                      icon: Icon(Icons.home), label: 'الرئيسية'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.search), label: 'البحث'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.library_music), label: 'مكتبتي'),
                  BottomNavigationBarItem(
                      icon: Icon(Icons.explore), label: 'اكتشف'),
                ],
              ),
            )));
        },
      ),
    );
  }
}
