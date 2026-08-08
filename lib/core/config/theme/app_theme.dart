import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:soundora/core/config/theme/app_colors.dart';

class AppTheme {
  static final lightTheme = ThemeData(
    brightness: Brightness.light,
    fontFamily: "Satoshi",
    fontFamilyFallback: const ["Cairo"],
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.backgroundLightTheme,
    inputDecorationTheme: InputDecorationTheme(
      fillColor: Colors.transparent,
      filled: true,
      hintStyle: TextStyle(
          color: const Color(0xff383838),
          fontWeight: FontWeight.w500,
          fontSize: 16.sp),
      contentPadding: EdgeInsets.all(30.w),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.r),
        borderSide: const BorderSide(color: Colors.black),
      ),

      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.r),
        borderSide: const BorderSide(color: Colors.black, width: 0.4),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(30.r),
        borderSide: const BorderSide(color: Colors.black, width: 0.4),
      ),

      errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.all(Radius.circular(30.r)),
          borderSide: const BorderSide(
            width: 1,
            color: Color.fromARGB(255, 255, 108, 59),
          )),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.all(Radius.circular(30.r)),
        borderSide: const BorderSide(
          width: 1,
          color: Colors.redAccent,
        ),
      ),

      // suffixIcon: suffexIcon,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          textStyle: TextStyle(
              fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r))),
    ),
  );

  static final darkTheme = ThemeData(
    brightness: Brightness.dark,
    fontFamily: "Satoshi",
    fontFamilyFallback: const ["Cairo"],
    primaryColor: AppColors.primaryColor,
    scaffoldBackgroundColor: AppColors.backgroundDarkTheme,
    inputDecorationTheme: InputDecorationTheme(
      fillColor: const Color(0xFF1C1C2E),
      filled: true,
      hintStyle: TextStyle(
          color: const Color(0xFF6B6B80),
          fontWeight: FontWeight.w400,
          fontSize: 15.sp),
      contentPadding: EdgeInsets.symmetric(horizontal: 20.w, vertical: 18.h),
      disabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: Color(0xFF2A2A3E), width: 1.2),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: Color(0xFF2A2A3E), width: 1.2),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: AppColors.primaryColor, width: 1.8),
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(color: Color(0xFF2A2A3E), width: 1.2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(width: 1.2, color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14.r),
        borderSide: const BorderSide(width: 1.8, color: Colors.redAccent),
      ),
      prefixIconColor: const Color(0xFF6B6B80),
      suffixIconColor: const Color(0xFF6B6B80),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primaryColor,
          textStyle: TextStyle(
              fontSize: 20.sp, fontWeight: FontWeight.bold, color: Colors.white),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(30.r))),
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: const Color(0xFF1C1C2E),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14.r),
        side: const BorderSide(color: Color(0xFF2A2A3E), width: 1),
      ),
      contentTextStyle: TextStyle(
        color: Colors.white,
        fontSize: 14.sp,
        fontWeight: FontWeight.w500,
      ),
      elevation: 8,
      dismissDirection: DismissDirection.horizontal,
    ),
  );
}
