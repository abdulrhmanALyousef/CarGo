import 'package:flutter/material.dart';
import 'package:cargo/core/constants/app_size.dart';
import 'package:cargo/core/theme/light_color.dart';

ThemeData lightTheme = ThemeData(
  useMaterial3: true,
  brightness: Brightness.light,
  colorScheme: const ColorScheme.light(
    primary: LightColors.primaryColor,
  ),
  scaffoldBackgroundColor: const Color(0xFFf5f5f5),
  primaryColor: LightColors.primaryColor,
  appBarTheme: AppBarTheme(
    backgroundColor: const Color(0xFFFFFFFF),
    titleTextStyle: TextStyle(fontSize: AppSizes.sp16, fontWeight: FontWeight.w700, color: LightColors.textColor),
  ),
  progressIndicatorTheme: const ProgressIndicatorThemeData(color: Colors.white),

  elevatedButtonTheme: ElevatedButtonThemeData(
    style: ElevatedButton.styleFrom(
      backgroundColor: LightColors.primaryColor,
      foregroundColor: LightColors.textColor,
      textStyle: TextStyle(fontSize: AppSizes.sp16, fontWeight: FontWeight.w400, color: LightColors.textColor),
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
      minimumSize: Size.fromHeight(AppSizes.h52),
    ),
  ),
  textButtonTheme: TextButtonThemeData(style: TextButton.styleFrom(foregroundColor: LightColors.textColor)),

  inputDecorationTheme: const InputDecorationTheme(
    hintStyle: TextStyle(color: LightColors.textColor),
    filled: true,
    fillColor: Color(0xFFFFFFFF),
    focusColor: Color(0xFFD1DAD6),
    errorBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Colors.red, width: 0.5),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Color(0xFFD1DAD6), width: 0.5),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Color(0xFFD1DAD6), width: 0.5),
    ),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.zero,
      borderSide: BorderSide(color: Color(0xFFD1DAD6), width: 0.5),
    ),
  ),

  bottomNavigationBarTheme: const BottomNavigationBarThemeData(
    backgroundColor: Color(0xFFB5B3B3),
    type: BottomNavigationBarType.fixed,
    selectedItemColor: LightColors.primaryColor,
    unselectedItemColor: LightColors.textColor,
    showUnselectedLabels: true,
  ),
);