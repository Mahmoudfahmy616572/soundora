// Basic smoke test for the Soundora theme and widget tree.
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:soundora/core/config/theme/app_theme.dart';

void main() {
  testWidgets('AppTheme dark theme renders a text widget', (tester) async {
    await tester.pumpWidget(
      ScreenUtilInit(
        designSize: const Size(375, 812),
        minTextAdapt: true,
        builder: (context, child) => MaterialApp(
          theme: AppTheme.darkTheme,
          home: const Scaffold(body: Center(child: Text('Soundora'))),
        ),
      ),
    );

    expect(find.text('Soundora'), findsOneWidget);
    final context = tester.element(find.text('Soundora'));
    expect(Theme.of(context).brightness, Brightness.dark);
  });
}
