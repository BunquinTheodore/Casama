import 'package:flutter/material.dart';

enum CasPose {
  hero,
  waving,
  jumping,
  standing,
  deliveries,
  tasks,
  roulette,
  together,
  chatting,
}

class CasMascotView extends StatelessWidget {
  final CasPose pose;
  final double? width;
  final double? height;
  final BoxFit fit;

  const CasMascotView({
    super.key,
    this.pose = CasPose.hero,
    this.width,
    this.height,
    this.fit = BoxFit.contain,
  });

  String get _assetPath {
    switch (pose) {
      case CasPose.hero:
        return 'assets/images/cas/cas_hero.png';
      case CasPose.waving:
        return 'assets/images/cas/cas_waving.png';
      case CasPose.jumping:
        return 'assets/images/cas/cas_jumping.png';
      case CasPose.standing:
        return 'assets/images/cas/cas_standing.png';
      case CasPose.deliveries:
        return 'assets/images/cas/cas_deliveries.png';
      case CasPose.tasks:
        return 'assets/images/cas/cas_tasks.png';
      case CasPose.roulette:
        return 'assets/images/cas/cas_roulette.png';
      case CasPose.together:
        return 'assets/images/cas/cas_together.png';
      case CasPose.chatting:
        return 'assets/images/cas/cas_chatting.png';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      _assetPath,
      width: width,
      height: height,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        // Fallback friendly placeholder if asset loading has an issue
        return Container(
          width: width ?? 80,
          height: height ?? 80,
          decoration: const BoxDecoration(
            color: Color(0xFFFFF8F1),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: const Text('🦉', style: TextStyle(fontSize: 32)),
        );
      },
    );
  }
}
