import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundora/presentation/MainWrapper/cubit/cubit/navigation_cubit.dart';

void main() {
  group('NavigationCubit', () {
    late NavigationCubit cubit;

    setUp(() {
      cubit = NavigationCubit();
    });

    tearDown(() {
      cubit.close();
    });

    test('initial state is 0 (Home)', () {
      expect(cubit.state, 0);
    });

    blocTest<NavigationCubit, int>(
      'emits [1] when updateIndex(1) is called',
      build: () => NavigationCubit(),
      act: (cubit) => cubit.updateIndex(1),
      expect: () => [1],
    );

    blocTest<NavigationCubit, int>(
      'emits [2] when updateIndex(2) is called',
      build: () => NavigationCubit(),
      act: (cubit) => cubit.updateIndex(2),
      expect: () => [2],
    );

    blocTest<NavigationCubit, int>(
      'emits [1, 2] when called twice',
      build: () => NavigationCubit(),
      act: (cubit) {
        cubit.updateIndex(1);
        cubit.updateIndex(2);
      },
      expect: () => [1, 2],
    );
  });
}
