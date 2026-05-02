import 'package:flutter/material.dart';

class AppTheme {
  // === MONOCHROME PALETTE ===
  static const Color black = Color(0xFF000000);
  static const Color darkest = Color(0xFF0A0A0A);
  static const Color dark = Color(0xFF111111);
  static const Color darkMid = Color(0xFF1A1A1A);
  static const Color darkGray = Color(0xFF222222);
  static const Color midGray = Color(0xFF444444);
  static const Color gray = Color(0xFF666666);
  static const Color lightGray = Color(0xFF888888);
  static const Color silver = Color(0xFFAAAAAA);
  static const Color lightSilver = Color(0xFFCCCCCC);
  static const Color offWhite = Color(0xFFE8E8E8);
  static const Color white = Color(0xFFFFFFFF);

  // Glass colors
  static const Color glassWhite = Color(0x1AFFFFFF);
  static const Color glassWhiteMid = Color(0x26FFFFFF);
  static const Color glassWhiteStrong = Color(0x40FFFFFF);
  static const Color glassDark = Color(0x1A000000);
  static const Color glassDarkMid = Color(0x33000000);
  static const Color glassBorder = Color(0x33FFFFFF);
  static const Color glassBorderDark = Color(0x22000000);

  // Accent
  static const Color accent = Color(0xFFFFFFFF);
  static const Color accentDark = Color(0xFF000000);

  static ThemeData get darkTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.dark,
        scaffoldBackgroundColor: darkest,
        colorScheme: const ColorScheme.dark(
          primary: white,
          onPrimary: black,
          secondary: silver,
          onSecondary: black,
          surface: darkMid,
          onSurface: white,
          background: darkest,
          onBackground: white,
          error: Color(0xFFFF4444),
        ),
        fontFamily: 'JetBrainsMono',
        textTheme: _buildTextTheme(isDark: true),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: white),
          titleTextStyle: TextStyle(
            fontFamily: 'Syne',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: white,
          ),
        ),
        iconTheme: const IconThemeData(color: white),
        dividerColor: midGray,
        cardTheme: CardThemeData(
          color: darkMid,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: _inputDecorationTheme(isDark: true),
        elevatedButtonTheme: _elevatedButtonTheme(isDark: true),
        textButtonTheme: _textButtonTheme(isDark: true),
        outlinedButtonTheme: _outlinedButtonTheme(isDark: true),
        chipTheme: _chipTheme(isDark: true),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          selectedItemColor: white,
          unselectedItemColor: gray,
          elevation: 0,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      );

  static ThemeData get lightTheme => ThemeData(
        useMaterial3: true,
        brightness: Brightness.light,
        scaffoldBackgroundColor: offWhite,
        colorScheme: const ColorScheme.light(
          primary: black,
          onPrimary: white,
          secondary: midGray,
          onSecondary: white,
          surface: white,
          onSurface: black,
          background: offWhite,
          onBackground: black,
          error: Color(0xFFCC0000),
        ),
        fontFamily: 'JetBrainsMono',
        textTheme: _buildTextTheme(isDark: false),
        appBarTheme: const AppBarTheme(
          backgroundColor: Colors.transparent,
          elevation: 0,
          iconTheme: IconThemeData(color: black),
          titleTextStyle: TextStyle(
            fontFamily: 'Syne',
            fontSize: 20,
            fontWeight: FontWeight.w700,
            color: black,
          ),
        ),
        iconTheme: const IconThemeData(color: black),
        dividerColor: lightSilver,
        cardTheme: CardThemeData(
          color: white,
          elevation: 0,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
        ),
        inputDecorationTheme: _inputDecorationTheme(isDark: false),
        elevatedButtonTheme: _elevatedButtonTheme(isDark: false),
        textButtonTheme: _textButtonTheme(isDark: false),
        outlinedButtonTheme: _outlinedButtonTheme(isDark: false),
        chipTheme: _chipTheme(isDark: false),
        bottomNavigationBarTheme: const BottomNavigationBarThemeData(
          backgroundColor: Colors.transparent,
          selectedItemColor: black,
          unselectedItemColor: lightGray,
          elevation: 0,
        ),
        pageTransitionsTheme: const PageTransitionsTheme(
          builders: {
            TargetPlatform.android: CupertinoPageTransitionsBuilder(),
            TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
          },
        ),
      );

  static TextTheme _buildTextTheme({required bool isDark}) {
    final Color primary = isDark ? white : black;
    final Color secondary = isDark ? silver : gray;

    return TextTheme(
      displayLarge: TextStyle(
        fontFamily: 'Syne',
        fontSize: 57,
        fontWeight: FontWeight.w800,
        color: primary,
        letterSpacing: -2,
      ),
      displayMedium: TextStyle(
        fontFamily: 'Syne',
        fontSize: 45,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: -1,
      ),
      displaySmall: TextStyle(
        fontFamily: 'Syne',
        fontSize: 36,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      headlineLarge: TextStyle(
        fontFamily: 'Syne',
        fontSize: 32,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      headlineMedium: TextStyle(
        fontFamily: 'Syne',
        fontSize: 28,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      headlineSmall: TextStyle(
        fontFamily: 'Syne',
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      titleLarge: TextStyle(
        fontFamily: 'Syne',
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: primary,
      ),
      titleMedium: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 16,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      titleSmall: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      bodyLarge: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodyMedium: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: primary,
      ),
      bodySmall: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondary,
      ),
      labelLarge: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 14,
        fontWeight: FontWeight.w700,
        color: primary,
        letterSpacing: 1.5,
      ),
      labelMedium: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 12,
        fontWeight: FontWeight.w500,
        color: secondary,
        letterSpacing: 1.2,
      ),
      labelSmall: TextStyle(
        fontFamily: 'JetBrainsMono',
        fontSize: 10,
        fontWeight: FontWeight.w400,
        color: secondary,
        letterSpacing: 1.0,
      ),
    );
  }

  static InputDecorationTheme _inputDecorationTheme({required bool isDark}) {
    return InputDecorationTheme(
      filled: true,
      fillColor: isDark ? glassWhite : glassDark,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? glassBorder : glassBorderDark,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? glassBorder : glassBorderDark,
          width: 1,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: BorderSide(
          color: isDark ? white : black,
          width: 1.5,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(12),
        borderSide: const BorderSide(color: Color(0xFFFF4444)),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      hintStyle: TextStyle(
        color: isDark ? gray : lightGray,
        fontFamily: 'JetBrainsMono',
        fontSize: 14,
      ),
      labelStyle: TextStyle(
        color: isDark ? silver : gray,
        fontFamily: 'JetBrainsMono',
        fontSize: 14,
      ),
    );
  }

  static ElevatedButtonThemeData _elevatedButtonTheme({required bool isDark}) {
    return ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: isDark ? white : black,
        foregroundColor: isDark ? black : white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 14,
          fontWeight: FontWeight.w700,
          letterSpacing: 1.2,
        ),
      ),
    );
  }

  static TextButtonThemeData _textButtonTheme({required bool isDark}) {
    return TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: isDark ? white : black,
        textStyle: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static OutlinedButtonThemeData _outlinedButtonTheme({required bool isDark}) {
    return OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: isDark ? white : black,
        side: BorderSide(color: isDark ? glassBorder : glassBorderDark),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        textStyle: const TextStyle(
          fontFamily: 'JetBrainsMono',
          fontSize: 14,
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }

  static ChipThemeData _chipTheme({required bool isDark}) {
    return ChipThemeData(
      backgroundColor: isDark ? glassWhite : glassDark,
      side: BorderSide(color: isDark ? glassBorder : glassBorderDark),
      labelStyle: TextStyle(
        color: isDark ? white : black,
        fontFamily: 'JetBrainsMono',
        fontSize: 12,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
    );
  }
}
