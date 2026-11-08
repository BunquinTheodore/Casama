import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import '../../core/constants/dimensions.dart';

enum ChipVariant {
  home,
  out,
  paid,
  cod,
  urgent,
  medium,
  low,
  toBuy,
  open,
  unclaimed,
  returned,
  custom,
}

class StatusChip extends StatelessWidget {
  final String label;
  final ChipVariant variant;
  final Color? customBgColor;
  final Color? customTextColor;
  final IconData? icon;
  final double fontSize;
  final EdgeInsetsGeometry padding;

  const StatusChip({
    super.key,
    required this.label,
    this.variant = ChipVariant.custom,
    this.customBgColor,
    this.customTextColor,
    this.icon,
    this.fontSize = 11,
    this.padding = const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
  });

  @override
  Widget build(BuildContext context) {
    Color bg;
    Color fg;

    switch (variant) {
      case ChipVariant.home:
        bg = CasamaColors.homeBg;
        fg = CasamaColors.homeGreen;
        break;
      case ChipVariant.out:
        bg = CasamaColors.outBg;
        fg = CasamaColors.outGray;
        break;
      case ChipVariant.paid:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case ChipVariant.cod:
        bg = const Color(0xFFFFECE8);
        fg = CasamaColors.primaryCoral;
        break;
      case ChipVariant.urgent:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFD32F2F);
        break;
      case ChipVariant.medium:
        bg = const Color(0xFFFFF3E0);
        fg = const Color(0xFFE65100);
        break;
      case ChipVariant.low:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case ChipVariant.toBuy:
        bg = const Color(0xFFE3F2FD);
        fg = const Color(0xFF1976D2);
        break;
      case ChipVariant.open:
        bg = const Color(0xFFFFEBEE);
        fg = const Color(0xFFD32F2F);
        break;
      case ChipVariant.unclaimed:
        bg = const Color(0xFFFFF8E1);
        fg = const Color(0xFFF57F17);
        break;
      case ChipVariant.returned:
        bg = const Color(0xFFE8F5E9);
        fg = const Color(0xFF2E7D32);
        break;
      case ChipVariant.custom:
        bg = customBgColor ?? CasamaColors.softNeutral;
        fg = customTextColor ?? CasamaColors.ink;
        break;
    }

    return Container(
      padding: padding,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: CasamaSpacing.roundedPill,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: fontSize + 2, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: fg,
              fontSize: fontSize,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.2,
            ),
          ),
        ],
      ),
    );
  }
}
