import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

enum CasamaButtonStyle { primary, navy, secondary, ghost }

class CasamaButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final CasamaButtonStyle style;
  final bool isLoading;
  final bool isFullWidth;
  final double? height;
  final bool isPill;

  const CasamaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.icon,
    this.style = CasamaButtonStyle.primary,
    this.isLoading = false,
    this.isFullWidth = true,
    this.height = 50,
    this.isPill = false,
  });

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;
    BorderSide? border;

    switch (style) {
      case CasamaButtonStyle.primary:
        bgColor = CasamaColors.primaryCoral;
        fgColor = Colors.white;
        border = null;
        break;
      case CasamaButtonStyle.navy:
        bgColor = CasamaColors.midnightNavy;
        fgColor = Colors.white;
        border = null;
        break;
      case CasamaButtonStyle.secondary:
        bgColor = CasamaColors.white;
        fgColor = CasamaColors.ink;
        border = const BorderSide(color: CasamaColors.borderGray, width: 1.5);
        break;
      case CasamaButtonStyle.ghost:
        bgColor = Colors.transparent;
        fgColor = CasamaColors.primaryCoral;
        border = null;
        break;
    }

    final shape = isPill
        ? const StadiumBorder()
        : RoundedRectangleBorder(borderRadius: CasamaSpacing.roundedMd);

    Widget content = isLoading
        ? SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(
              strokeWidth: 2.5,
              valueColor: AlwaysStoppedAnimation<Color>(fgColor),
            ),
          )
        : Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fgColor),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: TextStyle(
                  color: fgColor,
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
            ],
          );

    final button = Material(
      color: onPressed == null ? bgColor.withValues(alpha: 0.5) : bgColor,
      shape: border != null && !isPill
          ? RoundedRectangleBorder(
              borderRadius: CasamaSpacing.roundedMd,
              side: border,
            )
          : shape,
      child: InkWell(
        onTap: isLoading ? null : onPressed,
        customBorder: shape,
        child: Container(
          height: height,
          padding: const EdgeInsets.symmetric(horizontal: 20),
          alignment: Alignment.center,
          child: content,
        ),
      ),
    );

    if (isFullWidth) {
      return SizedBox(width: double.infinity, child: button);
    }
    return button;
  }
}
