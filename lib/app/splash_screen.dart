import 'package:flutter/material.dart';

import '../core/theme.dart';
import '../l10n/strings.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({
    required this.strings,
    this.hasError = false,
    super.key,
  });

  final AppStrings strings;
  final bool hasError;

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: strings.direction,
      child: Scaffold(
        key: const ValueKey('branded-splash'),
        body: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 156,
                    height: 156,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.surface,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(
                        color: AppColors.cyan.withValues(alpha: .35),
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.cyan.withValues(alpha: .12),
                          blurRadius: 32,
                          spreadRadius: 4,
                        ),
                      ],
                    ),
                    child: Image.asset(
                      'assets/logo/logo.png',
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.auto_awesome,
                        size: 72,
                        color: AppColors.cyan,
                      ),
                    ),
                  ),
                  const SizedBox(height: 28),
                  Text(
                    strings.appName,
                    style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      color: AppColors.text,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    strings.startupSubtitle,
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: AppColors.muted,
                    ),
                  ),
                  const SizedBox(height: 28),
                  if (hasError) ...[
                    const Icon(
                      Icons.error_outline_rounded,
                      color: AppColors.red,
                    ),
                    const SizedBox(height: 10),
                    Text(
                      strings.startupFailed,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: AppColors.red,
                      ),
                    ),
                  ] else ...[
                    const SizedBox(
                      width: 220,
                      child: LinearProgressIndicator(
                        minHeight: 3,
                        color: AppColors.cyan,
                        backgroundColor: AppColors.surfaceHigh,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      strings.startupLoading,
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                        color: AppColors.cyan,
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
