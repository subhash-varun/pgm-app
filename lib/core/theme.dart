import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF3B82F6);
  static const primaryDark = Color(0xFF2563EB);
  static const success = Color(0xFF10B981);
  static const warning = Color(0xFFF59E0B);
  static const danger = Color(0xFFEF4444);
  static const info = Color(0xFF06B6D4);
  static const purple = Color(0xFF8B5CF6);
  static const indigo = Color(0xFF6366F1);
  static const background = Color(0xFFF3F4F6);
  static const card = Colors.white;
  static const textDark = Color(0xFF111827);
  static const textGray = Color(0xFF6B7280);
  static const border = Color(0xFFE5E7EB);
}

@immutable
class AppPalette extends ThemeExtension<AppPalette> {
  final Color scaffold;
  final Color surface;
  final Color surfaceAlt;
  final Color border;
  final Color textPrimary;
  final Color textSecondary;
  final Color textTertiary;
  final Color primary;
  final Color success;
  final Color warning;
  final Color danger;
  final Color info;
  final Color purple;
  final Color indigo;

  const AppPalette({
    required this.scaffold,
    required this.surface,
    required this.surfaceAlt,
    required this.border,
    required this.textPrimary,
    required this.textSecondary,
    required this.textTertiary,
    required this.primary,
    required this.success,
    required this.warning,
    required this.danger,
    required this.info,
    required this.purple,
    required this.indigo,
  });

  static const light = AppPalette(
    scaffold: Color(0xFFF6F7F9),
    surface: Color(0xFFFFFFFF),
    surfaceAlt: Color(0xFFF1F2F4),
    border: Color(0xFFE5E7EB),
    textPrimary: Color(0xFF111827),
    textSecondary: Color(0xFF6B7280),
    textTertiary: Color(0xFF9CA3AF),
    primary: Color(0xFF3B82F6),
    success: Color(0xFF10B981),
    warning: Color(0xFFF59E0B),
    danger: Color(0xFFEF4444),
    info: Color(0xFF06B6D4),
    purple: Color(0xFF8B5CF6),
    indigo: Color(0xFF6366F1),
  );

  static const dark = AppPalette(
    scaffold: Color(0xFF101214),
    surface: Color(0xFF1B1F24),
    surfaceAlt: Color(0xFF23282E),
    border: Color(0xFF2E343C),
    textPrimary: Color(0xFFF2F4F7),
    textSecondary: Color(0xFF9AA3AF),
    textTertiary: Color(0xFF6B7280),
    primary: Color(0xFF60A5FA),
    success: Color(0xFF34D399),
    warning: Color(0xFFFBBF24),
    danger: Color(0xFFF87171),
    info: Color(0xFF22D3EE),
    purple: Color(0xFFA78BFA),
    indigo: Color(0xFF818CF8),
  );

  @override
  AppPalette copyWith({
    Color? scaffold,
    Color? surface,
    Color? surfaceAlt,
    Color? border,
    Color? textPrimary,
    Color? textSecondary,
    Color? textTertiary,
    Color? primary,
    Color? success,
    Color? warning,
    Color? danger,
    Color? info,
    Color? purple,
    Color? indigo,
  }) {
    return AppPalette(
      scaffold: scaffold ?? this.scaffold,
      surface: surface ?? this.surface,
      surfaceAlt: surfaceAlt ?? this.surfaceAlt,
      border: border ?? this.border,
      textPrimary: textPrimary ?? this.textPrimary,
      textSecondary: textSecondary ?? this.textSecondary,
      textTertiary: textTertiary ?? this.textTertiary,
      primary: primary ?? this.primary,
      success: success ?? this.success,
      warning: warning ?? this.warning,
      danger: danger ?? this.danger,
      info: info ?? this.info,
      purple: purple ?? this.purple,
      indigo: indigo ?? this.indigo,
    );
  }

  @override
  AppPalette lerp(ThemeExtension<AppPalette>? other, double t) {
    if (other is! AppPalette) return this;
    return AppPalette(
      scaffold: Color.lerp(scaffold, other.scaffold, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      surfaceAlt: Color.lerp(surfaceAlt, other.surfaceAlt, t)!,
      border: Color.lerp(border, other.border, t)!,
      textPrimary: Color.lerp(textPrimary, other.textPrimary, t)!,
      textSecondary: Color.lerp(textSecondary, other.textSecondary, t)!,
      textTertiary: Color.lerp(textTertiary, other.textTertiary, t)!,
      primary: Color.lerp(primary, other.primary, t)!,
      success: Color.lerp(success, other.success, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      danger: Color.lerp(danger, other.danger, t)!,
      info: Color.lerp(info, other.info, t)!,
      purple: Color.lerp(purple, other.purple, t)!,
      indigo: Color.lerp(indigo, other.indigo, t)!,
    );
  }
}

extension AppThemeContext on BuildContext {
  AppPalette get palette =>
      Theme.of(this).extension<AppPalette>() ?? AppPalette.light;
}

class AppTheme {
  static ThemeData light() => _build(Brightness.light, AppPalette.light);

  static ThemeData dark() => _build(Brightness.dark, AppPalette.dark);

  static ThemeData _build(Brightness brightness, AppPalette p) {
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.primary,
      brightness: brightness,
      primary: p.primary,
      secondary: p.indigo,
      surface: p.surface,
      error: p.danger,
    );
    final base = ThemeData(
      useMaterial3: true,
      colorScheme: scheme,
      scaffoldBackgroundColor: p.scaffold,
      textTheme: _textTheme(brightness).apply(
        bodyColor: p.textPrimary,
        displayColor: p.textPrimary,
      ),
      extensions: [p],
    );
    return base.copyWith(
      appBarTheme: AppBarTheme(
        backgroundColor: p.surface,
        foregroundColor: p.textPrimary,
        elevation: 0,
        scrolledUnderElevation: 0.5,
        centerTitle: false,
        titleTextStyle: TextStyle(
          color: p.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      cardTheme: CardThemeData(
        color: p.surface,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: p.border),
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: p.primary,
          minimumSize: const Size(48, 48),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          minimumSize: const Size(48, 48),
          foregroundColor: p.textPrimary,
          side: BorderSide(color: p.border),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          textStyle: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          minimumSize: const Size(44, 44),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          textStyle: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: p.surfaceAlt,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: TextStyle(color: p.textTertiary, fontSize: 14),
        prefixIconColor: p.textTertiary,
        suffixIconColor: p.textSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(color: p.primary, width: 1.5),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: p.surface,
        indicatorColor: p.primary.withValues(alpha: 0.14),
        height: 68,
        elevation: 8,
        iconTheme: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return IconThemeData(
            color: selected ? p.primary : p.textSecondary,
            size: 24,
          );
        }),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          final selected = states.contains(WidgetState.selected);
          return TextStyle(
            fontSize: 12,
            fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
            color: selected ? p.primary : p.textSecondary,
          );
        }),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: p.surfaceAlt,
        selectedColor: p.primary,
        disabledColor: p.surfaceAlt,
        side: BorderSide(color: p.border),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        labelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: p.textPrimary,
        ),
        secondaryLabelStyle: TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: p.primary,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        showCheckmark: false,
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: p.textPrimary,
        contentTextStyle: TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: p.surface,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        elevation: 4,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: p.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        titleTextStyle: TextStyle(
          fontSize: 18,
          fontWeight: FontWeight.w700,
          color: p.textPrimary,
        ),
        contentTextStyle: TextStyle(fontSize: 14, color: p.textSecondary),
      ),
      dividerTheme: DividerThemeData(color: p.border, thickness: 1, space: 1),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return Colors.white;
          return p.textTertiary;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return p.primary;
          return p.surfaceAlt;
        }),
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(color: p.primary),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: p.primary,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        elevation: 3,
      ),
      listTileTheme: ListTileThemeData(
        iconColor: p.textSecondary,
        textColor: p.textPrimary,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      ),
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final base = brightness == Brightness.dark
        ? ThemeData.dark().textTheme
        : ThemeData.light().textTheme;
    return base
        .copyWith(
          titleLarge: const TextStyle(fontSize: 24, fontWeight: FontWeight.w800),
          titleMedium: const TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
          titleSmall: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
          bodyLarge: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          bodyMedium: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          bodySmall: const TextStyle(fontSize: 13, fontWeight: FontWeight.w400),
          labelLarge: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
          labelMedium: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          labelSmall: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
        )
        .apply(fontFamilyFallback: const ['Roboto']);
  }
}
