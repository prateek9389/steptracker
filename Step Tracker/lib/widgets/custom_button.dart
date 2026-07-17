import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

enum ButtonType {
  primary,
  secondary,
  accent,
  outline,
}

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback? onPressed;
  final ButtonType type;
  final Widget? icon;
  final bool isLoading;
  final double width;
  final double height;
  final double borderRadius;

  const CustomButton({
    Key? key,
    required this.text,
    this.onPressed,
    this.type = ButtonType.primary,
    this.icon,
    this.isLoading = false,
    this.width = double.infinity,
    this.height = 56.0,
    this.borderRadius = 16.0,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    Gradient? gradient;
    Color? textColor;
    Border? border;
    List<BoxShadow>? shadow;

    switch (type) {
      case ButtonType.primary:
        gradient = AppColors.primaryGradient;
        textColor = Colors.black;
        shadow = [
          BoxShadow(
            color: AppColors.primary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ];
        break;
      case ButtonType.secondary:
        gradient = AppColors.neonBlueGradient;
        textColor = Colors.white;
        shadow = [
          BoxShadow(
            color: AppColors.secondary.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ];
        break;
      case ButtonType.accent:
        gradient = AppColors.neonPurpleGradient;
        textColor = Colors.white;
        shadow = [
          BoxShadow(
            color: AppColors.accent.withOpacity(0.35),
            blurRadius: 16,
            offset: const Offset(0, 6),
          )
        ];
        break;
      case ButtonType.outline:
        gradient = null;
        textColor = isDark ? Colors.white : Colors.black;
        border = Border.all(
          color: isDark ? const Color(0x33FFFFFF) : const Color(0x33000000),
          width: 1.5,
        );
        break;
    }

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient,
        border: border,
        boxShadow: shadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(
                        type == ButtonType.primary ? Colors.black : Colors.white,
                      ),
                      strokeWidth: 2.5,
                    ),
                  )
                : Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      if (icon != null) ...[
                        icon!,
                        const SizedBox(width: 10),
                      ],
                      Text(
                        text,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              color: textColor,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                      ),
                    ],
                  ),
          ),
        ),
      ),
    );
  }
}
