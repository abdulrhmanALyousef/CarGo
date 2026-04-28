import 'package:flutter/material.dart';
import 'package:cargo/core/theme/light_color.dart';

// ── AppButton ─────────────────────────────────────────────────────────────────
//
// Single reusable button for the entire app.
// Replaces all ElevatedButton / OutlinedButton usages.
//
// Parameters:
//   text          — button label
//   onTap         — callback; null disables the button
//   color         — background colour (filled) or border colour (outlined)
//   textColor     — label / icon colour
//   height        — total button height (default: 52 — matches theme)
//   width         — explicit width; defaults to double.infinity (full width)
//   borderRadius  — corner radius (use 9999 for pill shape)
//   fontSize      — label font size (default: 15)
//   icon          — optional leading widget (Icon)
//   padding       — horizontal/vertical inner padding override
//   outlined      — true → transparent bg with coloured border
//   isLoading     — replaces label with a small CircularProgressIndicator
//   borderColor   — overrides the border colour independently from `color`
//                   (use when border and text colours must differ)
//
// Defaults match the primary action button style used across the app.

class AppButton extends StatelessWidget {
  final String text;
  final VoidCallback? onTap;
  final Color color;
  final Color textColor;
  final double height;
  final double? width;
  final double borderRadius;
  final double fontSize;
  final Widget? icon;
  final EdgeInsetsGeometry? padding;
  final bool outlined;
  final bool isLoading;
  final Color? borderColor;

  const AppButton({
    super.key,
    required this.text,
    this.onTap,
    this.color = LightColors.primaryColor,
    this.textColor = Colors.white,
    this.height = 52,
    this.width = double.infinity,
    this.borderRadius = 12,
    this.fontSize = 15,
    this.icon,
    this.padding,
    this.outlined = false,
    this.isLoading = false,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final bool disabled = onTap == null && !isLoading;
    final Color effectiveBorder = borderColor ?? color;

    final Color bgColor = outlined
        ? Colors.transparent
        : disabled
            ? color.withValues(alpha: 0.5)
            : color;

    final Color borderC = disabled
        ? effectiveBorder.withValues(alpha: 0.4)
        : effectiveBorder;

    final Color labelColor =
        disabled ? textColor.withValues(alpha: 0.5) : textColor;

    Widget inner;
    if (isLoading) {
      inner = SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(color: textColor, strokeWidth: 2),
      );
    } else if (icon != null) {
      inner = Row(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          icon!,
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              fontSize: fontSize,
              fontWeight: FontWeight.w600,
              color: labelColor,
            ),
          ),
        ],
      );
    } else {
      inner = Text(
        text,
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w600,
          color: labelColor,
        ),
      );
    }

    return SizedBox(
      height: height,
      width: width,
      child: Material(
        color: bgColor,
        borderRadius: BorderRadius.circular(borderRadius),
        child: InkWell(
          onTap: (disabled || isLoading) ? null : onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          splashColor: (outlined ? effectiveBorder : Colors.white)
              .withValues(alpha: 0.15),
          highlightColor: (outlined ? effectiveBorder : Colors.white)
              .withValues(alpha: 0.08),
          child: Container(
            height: height,
            padding: padding ?? const EdgeInsets.symmetric(horizontal: 16),
            decoration: outlined
                ? BoxDecoration(
                    border: Border.all(color: borderC),
                    borderRadius: BorderRadius.circular(borderRadius),
                  )
                : null,
            child: Center(child: inner),
          ),
        ),
      ),
    );
  }
}
