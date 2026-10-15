import 'package:flutter/material.dart';

class AppColors {
  static const background = Color(0xff0c1322);
  static const surfaceLow = Color(0xff141b2b);
  static const surface = Color(0xff191f2f);
  static const surfaceHigh = Color(0xff232a3a);
  static const outline = Color(0xff3d494c);
  static const text = Color(0xffdce2f7);
  static const muted = Color(0xffbcc9cd);
  static const cyan = Color(0xff4cd7f6);
  static const cyanStrong = Color(0xff06b6d4);
  static const green = Color(0xff4edea3);
  static const amber = Color(0xffffb74d);
  static const red = Color(0xffff7f8b);
}

class AppTheme {
  static ThemeData get dark => ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: AppColors.background,
        colorScheme: const ColorScheme.dark(primary: AppColors.cyan, secondary: AppColors.green, surface: AppColors.surface),
        dividerColor: AppColors.outline,
        cardColor: AppColors.surface,
        navigationRailTheme: const NavigationRailThemeData(backgroundColor: AppColors.background, indicatorColor: Color(0x3322d3ee), selectedIconTheme: IconThemeData(color: AppColors.cyan), selectedLabelTextStyle: TextStyle(color: AppColors.cyan, fontSize: 11), unselectedIconTheme: IconThemeData(color: AppColors.muted), unselectedLabelTextStyle: TextStyle(color: AppColors.muted, fontSize: 11)),
        inputDecorationTheme: InputDecorationTheme(filled: true, fillColor: AppColors.surfaceLow, border: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.outline)), enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.outline)), focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(10), borderSide: const BorderSide(color: AppColors.cyan))),
        textTheme: const TextTheme(bodyMedium: TextStyle(color: AppColors.text), bodySmall: TextStyle(color: AppColors.muted), titleLarge: TextStyle(color: AppColors.text, fontWeight: FontWeight.w700), titleMedium: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600), titleSmall: TextStyle(color: AppColors.text, fontWeight: FontWeight.w600), labelSmall: TextStyle(color: AppColors.muted, letterSpacing: .5)),
      );
}

class Panel extends StatelessWidget {
  const Panel({required this.child, this.padding = const EdgeInsets.all(18), super.key});
  final Widget child;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) => Container(padding: padding, decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(16), border: Border.all(color: AppColors.outline.withValues(alpha: .7))), child: child);
}

class Mono extends StatelessWidget {
  const Mono(this.text, {this.color, this.size = 12, super.key});
  final String text;
  final Color? color;
  final double size;

  @override
  Widget build(BuildContext context) => Text(text, style: TextStyle(fontFamily: 'monospace', color: color ?? AppColors.text, fontSize: size));
}
