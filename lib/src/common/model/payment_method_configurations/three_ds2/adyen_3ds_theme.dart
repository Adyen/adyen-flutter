import 'package:flutter/material.dart';

/// A simplified theme for customizing 3DS2 challenge screens.
///
/// Provides a Flutter-idiomatic API that internally maps to
/// platform-specific native SDK customization options.
final class Adyen3DSTheme {
  // Primary colors
  final Color? primaryColor; // Submit/action button background
  final Color? onPrimaryColor; // Text on primary buttons

  // Background colors
  final Color? backgroundColor; // Screen background
  final Color? headerBackgroundColor; // Toolbar/header background

  // Text colors
  final Color? textColor; // Primary text (labels)
  final Color? secondaryTextColor; // Secondary text, hints
  final Color? headingTextColor; // Heading text
  final Color? errorColor; // Error messages

  // Input styling
  final Color? inputBorderColor; // TextBox border
  final Color? inputTextColor; // TextBox text
  final double? inputBorderWidth;

  // Typography
  final String? fontFamily; // Font for all text
  final double? labelFontSize;
  final double? headingFontSize;
  final double? buttonFontSize;

  // Shape
  final double? buttonCornerRadius;
  final double? inputCornerRadius;

  // Optional per-button overrides (falls back to primary/onPrimary defaults)
  final Adyen3DSButtonTheme? submitButtonTheme;
  final Adyen3DSButtonTheme? continueButtonTheme;
  final Adyen3DSButtonTheme? nextButtonTheme;
  final Adyen3DSButtonTheme? cancelButtonTheme;
  final Adyen3DSButtonTheme? resendButtonTheme;

  const Adyen3DSTheme({
    this.primaryColor,
    this.onPrimaryColor,
    this.backgroundColor,
    this.headerBackgroundColor,
    this.textColor,
    this.secondaryTextColor,
    this.headingTextColor,
    this.errorColor,
    this.inputBorderColor,
    this.inputTextColor,
    this.inputBorderWidth,
    this.fontFamily,
    this.labelFontSize,
    this.headingFontSize,
    this.buttonFontSize,
    this.buttonCornerRadius,
    this.inputCornerRadius,
    this.submitButtonTheme,
    this.continueButtonTheme,
    this.nextButtonTheme,
    this.cancelButtonTheme,
    this.resendButtonTheme,
  });

  /// Creates an Adyen3DSTheme from a Flutter ThemeData.
  ///
  /// Automatically maps Flutter theme values to 3DS customization,
  /// providing consistent branding with minimal configuration.
  factory Adyen3DSTheme.fromThemeData(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    final labelStyle = textTheme.bodyMedium;
    final headingStyle = textTheme.titleMedium ?? textTheme.titleLarge;
    final buttonStyle = textTheme.labelLarge ?? textTheme.labelMedium;

    final fontFamily = labelStyle?.fontFamily?.trim().isEmpty ?? true
        ? null
        : labelStyle?.fontFamily;

    return Adyen3DSTheme(
      primaryColor: colorScheme.primary,
      onPrimaryColor: colorScheme.onPrimary,
      backgroundColor: colorScheme.surface,
      headerBackgroundColor: colorScheme.surface,
      textColor: colorScheme.onSurface,
      secondaryTextColor: colorScheme.onSurfaceVariant,
      headingTextColor: colorScheme.onSurface,
      errorColor: colorScheme.error,
      inputBorderColor: colorScheme.outline,
      inputTextColor: colorScheme.onSurface,
      fontFamily: fontFamily,
      labelFontSize: labelStyle?.fontSize,
      headingFontSize: headingStyle?.fontSize,
      buttonFontSize: buttonStyle?.fontSize,
    );
  }
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
