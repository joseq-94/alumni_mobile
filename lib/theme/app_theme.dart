import 'package:flutter/material.dart';

class AppTheme {
  // Shared brand colours from both Alumni repositories' _variables.scss.
  static const red = Color(0xFFD9272E);
  static const darkRed = Color(0xFF7F1117);
  static const charcoal = Color(0xFF333333);
  static const grey = Color(0xFF6C757D);

  static final light = _build(false);
  static final dark = _build(true);

  static ThemeData _build(bool isDark) {
    final background = isDark
        ? const Color(0xFF111111)
        : const Color(0xFFF3F4F6);
    final surface = isDark ? const Color(0xFF1E1E1E) : Colors.white;
    final text = isDark ? const Color(0xFFF2F2F2) : charcoal;
    final secondaryText = isDark ? const Color(0xFFB8BDC3) : grey;
    final border = isDark ? const Color(0xFF414141) : const Color(0xFFE0E0E0);
    // Lighter red keeps links and selected labels readable on dark surfaces.
    final accent = isDark ? const Color(0xFFFF7379) : red;
    final selected = isDark ? const Color(0xFF452126) : const Color(0xFFFBE8E9);
    final scheme = ColorScheme(
      brightness: isDark ? Brightness.dark : Brightness.light,
      primary: accent,
      onPrimary: isDark ? Colors.black : Colors.white,
      primaryContainer: selected,
      onPrimaryContainer: isDark ? accent : darkRed,
      secondary: secondaryText,
      onSecondary: surface,
      secondaryContainer: selected,
      onSecondaryContainer: accent,
      error: isDark ? const Color(0xFFFFB4AB) : const Color(0xFFB3261E),
      onError: isDark ? Colors.black : Colors.white,
      surface: surface,
      onSurface: text,
      onSurfaceVariant: secondaryText,
      outline: secondaryText,
      outlineVariant: border,
      surfaceTint: Colors.transparent,
    );
    final base = ThemeData(useMaterial3: true, colorScheme: scheme);
    final buttonShape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    );
    return base.copyWith(
      scaffoldBackgroundColor: background,
      textTheme: base.textTheme.copyWith(
        titleLarge: base.textTheme.titleLarge?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        titleMedium: base.textTheme.titleMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
        headlineMedium: base.textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.w600,
        ),
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: background,
        foregroundColor: text,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleTextStyle: TextStyle(
          color: text,
          fontSize: 22,
          fontWeight: FontWeight.w600,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
          side: BorderSide(color: border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: red,
          foregroundColor: Colors.white,
          minimumSize: const Size(48, 48),
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: accent,
          side: BorderSide(color: accent),
          minimumSize: const Size(48, 48),
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: accent,
          minimumSize: const Size(48, 48),
          shape: buttonShape,
          textStyle: const TextStyle(fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        labelStyle: TextStyle(color: secondaryText),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: border),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: accent, width: 2),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: surface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: selected,
        indicatorShape: buttonShape,
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? accent
                : secondaryText,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => TextStyle(
            color: states.contains(WidgetState.selected) ? accent : text,
            fontSize: 12,
            fontWeight: states.contains(WidgetState.selected)
                ? FontWeight.w600
                : FontWeight.w400,
          ),
        ),
      ),
      navigationRailTheme: NavigationRailThemeData(
        backgroundColor: surface,
        indicatorColor: selected,
        indicatorShape: buttonShape,
        selectedIconTheme: IconThemeData(color: accent),
        unselectedIconTheme: IconThemeData(color: secondaryText),
        selectedLabelTextStyle: TextStyle(
          color: accent,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelTextStyle: TextStyle(color: text),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : secondaryText,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected) ? red : border,
        ),
        trackOutlineColor: const WidgetStatePropertyAll(Colors.transparent),
      ),
      dropdownMenuTheme: DropdownMenuThemeData(
        menuStyle: MenuStyle(
          backgroundColor: WidgetStatePropertyAll(surface),
          surfaceTintColor: const WidgetStatePropertyAll(Colors.transparent),
        ),
      ),
      dividerColor: border,
    );
  }
}
