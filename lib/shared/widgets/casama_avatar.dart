import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../core/constants/colors.dart';

class CasamaAvatar extends StatelessWidget {
  final String? avatarUrl;
  final double radius;
  final String? name;
  final VoidCallback? onTap;
  final bool showEditBadge;
  final Color? backgroundColor;
  final Color? borderColor;
  final double borderWidth;

  const CasamaAvatar({
    super.key,
    this.avatarUrl,
    this.radius = 24,
    this.name,
    this.onTap,
    this.showEditBadge = false,
    this.backgroundColor,
    this.borderColor,
    this.borderWidth = 0,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveBg =
        backgroundColor ??
        (context.isDark ? CasamaColors.darkCard : CasamaColors.dustyBlue);
    final size = radius * 2;

    Widget avatarContent;
    final url = avatarUrl?.trim();

    if (url != null && url.isNotEmpty) {
      if (url.startsWith('data:image')) {
        try {
          final commaIndex = url.indexOf(',');
          final base64Str = commaIndex != -1
              ? url.substring(commaIndex + 1)
              : url;
          final bytes = base64Decode(base64Str);
          avatarContent = Image.memory(
            bytes,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildFallback(context),
          );
        } catch (_) {
          avatarContent = _buildFallback(context);
        }
      } else if (url.startsWith('http://') || url.startsWith('https://')) {
        avatarContent = Image.network(
          url,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, _, _) => _buildFallback(context),
        );
      } else if (!kIsWeb && (url.startsWith('/') || url.startsWith('file:'))) {
        try {
          final filePath = url.startsWith('file://')
              ? url.replaceFirst('file://', '')
              : url;
          final file = File(filePath);
          avatarContent = Image.file(
            file,
            width: size,
            height: size,
            fit: BoxFit.cover,
            errorBuilder: (_, _, _) => _buildFallback(context),
          );
        } catch (_) {
          avatarContent = _buildFallback(context);
        }
      } else {
        avatarContent = _buildFallback(context);
      }
    } else {
      avatarContent = _buildFallback(context);
    }

    Widget mainAvatar = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: effectiveBg,
        shape: BoxShape.circle,
        border: borderWidth > 0
            ? Border.all(
                color:
                    borderColor ??
                    (context.isDark ? CasamaColors.darkBorder : Colors.white),
                width: borderWidth,
              )
            : null,
      ),
      child: ClipOval(child: avatarContent),
    );

    if (showEditBadge) {
      mainAvatar = Stack(
        clipBehavior: Clip.none,
        children: [
          mainAvatar,
          Positioned(
            bottom: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: CasamaColors.primaryCoral,
                shape: BoxShape.circle,
                border: Border.all(
                  color: context.isDark
                      ? CasamaColors.darkSurface
                      : Colors.white,
                  width: 2,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.2),
                    blurRadius: 4,
                  ),
                ],
              ),
              child: const Icon(
                Icons.camera_alt_rounded,
                color: Colors.white,
                size: 14,
              ),
            ),
          ),
        ],
      );
    }

    if (onTap != null) {
      return GestureDetector(onTap: onTap, child: mainAvatar);
    }

    return mainAvatar;
  }

  Widget _buildFallback(BuildContext context) {
    final letter = (name != null && name!.trim().isNotEmpty)
        ? name!.trim()[0].toUpperCase()
        : '?';

    return Center(
      child: Text(
        letter,
        style: TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.bold,
          fontSize: radius * 0.85,
        ),
      ),
    );
  }
}
