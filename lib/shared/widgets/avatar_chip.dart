import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';
import 'casama_avatar.dart';
import 'status_chip.dart';

class AvatarChip extends StatelessWidget {
  final String name;
  final String? avatarUrl;
  final bool isHome;
  final bool isCurrentUser;
  final VoidCallback? onTap;

  const AvatarChip({
    super.key,
    required this.name,
    this.avatarUrl,
    required this.isHome,
    this.isCurrentUser = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            children: [
              CasamaAvatar(
                avatarUrl: avatarUrl,
                radius: 26,
                name: name,
                borderWidth: isCurrentUser ? 2.5 : 0,
                borderColor: CasamaColors.primaryCoral,
              ),
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: isHome
                        ? CasamaColors.homeGreen
                        : CasamaColors.outGray,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            isCurrentUser ? 'You' : name.split(' ').first,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          StatusChip(
            label: isHome ? 'Home' : 'Out',
            variant: isHome ? ChipVariant.home : ChipVariant.out,
            fontSize: 10,
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          ),
        ],
      ),
    );
  }
}
