import 'package:basketball_academy/core/constants/app_colors.dart';
import 'package:flutter/material.dart';

/// Builds the app's (only) [ThemeData].
ThemeData buildLightTheme(String fontFamily, TextTheme textTheme) {
  final colorScheme = ColorScheme.fromSeed(
    seedColor: AppColors.primary,
    brightness: Brightness.light,
    primary: AppColors.primary,
    onPrimary: AppColors.white,
    primaryContainer: AppColors.primaryContainer,
    onPrimaryContainer: AppColors.primaryDark,
    secondary: AppColors.secondary,
    onSecondary: AppColors.white,
    secondaryContainer: AppColors.secondaryContainer,
    error: AppColors.error,
    onError: AppColors.white,
    errorContainer: AppColors.errorLight,
    onErrorContainer: AppColors.errorDark,
    surface: AppColors.surface,
    onSurface: AppColors.grey900,
  );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    fontFamily: fontFamily,
    colorScheme: colorScheme,
    scaffoldBackgroundColor: AppColors.background,
    appBarTheme: AppBarTheme(
      centerTitle: true,
      elevation: 0,
      scrolledUnderElevation: 1,
      backgroundColor: AppColors.surface,
      foregroundColor: AppColors.grey900,
      iconTheme: IconThemeData(color: AppColors.grey900),
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.grey900,
      ),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: AppColors.border),
      ),
      color: AppColors.card,
      clipBehavior: Clip.antiAlias,
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: colorScheme.primary,
        side: BorderSide(color: colorScheme.primary, width: 1.5),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        textStyle: TextStyle(
          fontFamily: fontFamily,
          fontSize: 16,
          fontWeight: FontWeight.w600,
        ),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(foregroundColor: colorScheme.primary),
    ),
    iconTheme: IconThemeData(color: AppColors.grey700),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.grey50,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(color: colorScheme.error, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      labelStyle: TextStyle(fontFamily: fontFamily, color: AppColors.grey600),
      hintStyle: TextStyle(fontFamily: fontFamily, color: AppColors.grey400),
    ),
    dividerTheme: DividerThemeData(
      color: AppColors.border,
      thickness: 1,
      space: 1,
    ),
    snackBarTheme: SnackBarThemeData(
      behavior: SnackBarBehavior.floating,
      backgroundColor: AppColors.grey900,
      contentTextStyle: TextStyle(fontFamily: fontFamily, color: AppColors.white),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      titleTextStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 18,
        fontWeight: FontWeight.w700,
        color: AppColors.grey900,
      ),
      contentTextStyle: TextStyle(
        fontFamily: fontFamily,
        fontSize: 14,
        color: AppColors.grey700,
      ),
    ),
    bottomSheetTheme: BottomSheetThemeData(
      backgroundColor: AppColors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
    ),
    bottomNavigationBarTheme: BottomNavigationBarThemeData(
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.grey500,
    ),
    navigationBarTheme: NavigationBarThemeData(
      backgroundColor: AppColors.surface,
      indicatorColor: AppColors.primaryContainer,
    ),
    drawerTheme: DrawerThemeData(backgroundColor: AppColors.surface),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.grey100,
      selectedColor: AppColors.primaryContainer,
      labelStyle: TextStyle(fontFamily: fontFamily, color: AppColors.grey700),
      side: BorderSide(color: AppColors.border),
    ),
    popupMenuTheme: PopupMenuThemeData(
      color: AppColors.surface,
      textStyle: TextStyle(fontFamily: fontFamily, color: AppColors.grey900),
    ),
    dropdownMenuTheme: DropdownMenuThemeData(
      menuStyle: MenuStyle(backgroundColor: WidgetStatePropertyAll(AppColors.surface)),
    ),
    progressIndicatorTheme: ProgressIndicatorThemeData(color: AppColors.primary),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.android: ZoomPageTransitionsBuilder(),
      },
    ),
    textTheme: textTheme.apply(
      bodyColor: AppColors.grey900,
      displayColor: AppColors.grey900,
    ),
  );
}
