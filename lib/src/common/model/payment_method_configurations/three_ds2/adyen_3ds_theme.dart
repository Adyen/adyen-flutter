import 'package:flutter/material.dart';

/// A simplified theme for customizing 3DS2 challenge screens.
///
/// Provides a Flutter-idiomatic API that internally maps to
/// platform-specific native SDK customization options.
final class Adyen3DSTheme {
  final Color? textColor; // Primary text (labels)
  final Color? backgroundColor; // Screen background (only on Android)

  // Header
  final Adyen3DSHeaderTheme? headerTheme;

  // Description / body labels
  final Adyen3DSDescriptionTheme? descriptionTheme;

  // Inputs
  final Adyen3DSInputDecorationTheme? inputDecorationTheme;

  // Grouped button themes
  // Primary applies to submit/continue/next (and OOB if available)
  final Adyen3DSButtonTheme? primaryButtonTheme;

  // Secondary applies to cancel/resend
  final Adyen3DSButtonTheme? secondaryButtonTheme;

  // Selection items (e.g., switches / radio rows)
  final Adyen3DSSelectionItemTheme? selectionItemTheme;

  /// Creates an Adyen3DSTheme from a Flutter ThemeData.

  const Adyen3DSTheme({
    this.backgroundColor,
    this.textColor,
    this.headerTheme,
    this.descriptionTheme,
    this.inputDecorationTheme,
    this.primaryButtonTheme,
    this.secondaryButtonTheme,
    this.selectionItemTheme,
  });

  ///
  /// Automatically maps Flutter theme values to 3DS customization,
  /// providing consistent branding with minimal configuration.
  factory Adyen3DSTheme.fromThemeData(ThemeData theme) {
    final colorScheme = theme.colorScheme;
    final textTheme = theme.textTheme;

    return Adyen3DSTheme(
      backgroundColor: colorScheme.surface,
      textColor: colorScheme.onSurface,
      headerTheme: Adyen3DSHeaderTheme(
        backgroundColor: colorScheme.surface,
        textColor: colorScheme.onSurface,
      ),
      descriptionTheme: Adyen3DSDescriptionTheme(
        textColor: textTheme.bodyMedium?.color ?? colorScheme.onSurface,
        titleTextColor: textTheme.titleSmall?.color ?? colorScheme.onSurface,
        textFontSize: textTheme.bodyMedium?.fontSize,
        titleFontSize: textTheme.titleSmall?.fontSize,
      ),
      inputDecorationTheme: Adyen3DSInputDecorationTheme(
        borderColor: colorScheme.outline,
        textColor: colorScheme.onSurface,
      ),
      selectionItemTheme: Adyen3DSSelectionItemTheme(
        selectionIndicatorTintColor: colorScheme.primary,
        highlightedBackgroundColor: colorScheme.surfaceVariant,
        textColor: colorScheme.onSurface,
      ),
    );
  }
}

final class Adyen3DSDescriptionTheme {
  final Color? titleTextColor;
  final double? titleFontSize;
  final Color? textColor;
  final double? textFontSize;
  final Color? inputLabelTextColor;
  final double? inputLabelFontSize;

  const Adyen3DSDescriptionTheme({
    this.titleTextColor,
    this.titleFontSize,
    this.textColor,
    this.textFontSize,
    this.inputLabelTextColor,
    this.inputLabelFontSize,
  });
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
  final String? cancelButtonText;

  const Adyen3DSHeaderTheme({
    this.backgroundColor, // This has no effect on iOS
    this.textColor,
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

final class Adyen3DSSelectionItemTheme {
  final Color? selectionIndicatorTintColor;
  final Color? highlightedBackgroundColor;
  final Color? textColor;

  const Adyen3DSSelectionItemTheme({
    this.selectionIndicatorTintColor,
    this.highlightedBackgroundColor,
    this.textColor,
  });
}
