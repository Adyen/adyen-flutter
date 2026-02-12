import 'package:flutter/material.dart';

/// A simplified theme for customizing 3DS2 challenge screens.
///
/// Provides a Flutter-idiomatic API that internally maps to
/// platform-specific native SDK customization options.
final class Adyen3DSTheme {
  final Color? primaryColor; // Submit/action button background
  final Color? textColor; // Primary text (labels)
  final Color? backgroundColor; // Screen background (only on Android)

  // Header
  final Adyen3DSHeaderTheme? headerTheme;

  // Inputs
  final Adyen3DSInputDecorationTheme? inputDecorationTheme;

  // Optional per-button overrides (falls back to primary/onPrimary defaults)
  final Adyen3DSButtonTheme? submitButtonTheme;
  final Adyen3DSButtonTheme? continueButtonTheme;
  final Adyen3DSButtonTheme? nextButtonTheme;
  final Adyen3DSButtonTheme? cancelButtonTheme;
  final Adyen3DSButtonTheme? resendButtonTheme;

  /// Creates an Adyen3DSTheme from a Flutter ThemeData.

  const Adyen3DSTheme({
    this.primaryColor,
    this.backgroundColor,
    this.textColor,

    this.headerTheme,
    this.inputDecorationTheme,
    this.submitButtonTheme,
    this.continueButtonTheme,
    this.nextButtonTheme,
    this.cancelButtonTheme,
    this.resendButtonTheme,
  });

  ///
  /// Automatically maps Flutter theme values to 3DS customization,
  /// providing consistent branding with minimal configuration.
  factory Adyen3DSTheme.fromThemeData(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final headingStyle = textTheme.titleMedium ?? textTheme.titleLarge;

    return Adyen3DSTheme(
      primaryColor: colorScheme.primary,
      backgroundColor: colorScheme.surface,
      textColor: colorScheme.onPrimary,
      headerTheme: Adyen3DSHeaderTheme(
        backgroundColor: colorScheme.surface,
        textColor: colorScheme.onSurface,
        fontSize: headingStyle?.fontSize,
      ),
      inputDecorationTheme: Adyen3DSInputDecorationTheme(
        borderColor: colorScheme.outline,
        textColor: colorScheme.onSurface,
      ),
    );
  }
}

final class Adyen3DSInputDecorationTheme {
  final Color? borderColor;
  final Color? textColor;
  final double? borderWidth;
  final double? cornerRadius;

  const Adyen3DSInputDecorationTheme({
    this.borderColor,
    this.textColor,
    this.borderWidth,
    this.cornerRadius,
  });
}

final class Adyen3DSHeaderTheme {
  final Color? backgroundColor;
  final Color? textColor;
  final double? fontSize;
  final String? cancelButtonText;

  const Adyen3DSHeaderTheme({
    this.backgroundColor, // This has no effect on iOS
    this.textColor,
    this.fontSize,
    this.cancelButtonText,
  });
}

/// Optional per-button overrides.
final class Adyen3DSButtonTheme {
  final Color? backgroundColor;
  final Color? textColor;
  final double? cornerRadius;
  final double? fontSize;

  const Adyen3DSButtonTheme({
    this.backgroundColor,
    this.textColor,
    this.cornerRadius,
    this.fontSize,
  });
}
