import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:soundora/presentation/Home/cubit/recently_played/recently_played_cubit.dart';
import 'package:soundora/presentation/Home/cubit/recently_played/recently_played_state.dart';

void main() {
  setUpAll(() async {
    TestWidgetsFlutterBinding.ensureInitialized();
    final dir = Directory.systemTemp.createTempSync('hive_test_');
    Hive.init(dir.path);
    await Hive.openBox('recently_played');
  });

  tearDownAll(() async {
    await Hive.deleteFromDisk();
  });

  group('RecentlyPlayedCubit', () {
    test('initial state is RecentlyPlayedLoaded', () async {
      final cubit = RecentlyPlayedCubit();
      await Future.delayed(const Duration(milliseconds: 200));
      expect(cubit.state, isA<RecentlyPlayedState>());
      expect(cubit.state, isA<RecentlyPlayedLoaded>());
      cubit.close();
    });
  });
}
