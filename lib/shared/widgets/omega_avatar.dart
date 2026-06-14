import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../../app/theme/colors.dart';
import '../../../app/theme/text_styles.dart';

class OmegaAvatar extends StatelessWidget {
  final String name;
  final String? imageUrl;
  final double size;
  final bool isGroup;
  final bool isVerified;
  final bool isOnline;
  final Color? backgroundColor;

  const OmegaAvatar({
    super.key,
    required this.name,
    this.imageUrl,
    this.size = 48,
    this.isGroup = false,
    this.isVerified = false,
    this.isOnline = false,
    this.backgroundColor,
  });

  String get _initials {
    final parts = name.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return name.isNotEmpty ? name[0].toUpperCase() : '?';
  }

  Color get _bgColor {
    if (backgroundColor != null) return backgroundColor!;
    final colors = [
      const Color(0xFF5B8AF0),
      const Color(0xFF9B59B6),
      const Color(0xFF1ABC9C),
      const Color(0xFFE67E22),
      const Color(0xFFE74C3C),
      const Color(0xFF3498DB),
      const Color(0xFF27AE60),
      const Color(0xFFF39C12),
    ];
    return colors[name.length % colors.length];
  }

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        _avatar,
        if (isVerified)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.32,
              height: size * 0.32,
              decoration: const BoxDecoration(
                color: OmegaColors.primary,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.verified_rounded,
                size: size * 0.22,
                color: Colors.white,
              ),
            ),
          ),
        if (isOnline && !isVerified)
          Positioned(
            right: 0,
            bottom: 0,
            child: Container(
              width: size * 0.28,
              height: size * 0.28,
              decoration: BoxDecoration(
                color: OmegaColors.online,
                shape: BoxShape.circle,
                border: Border.all(color: Colors.white, width: 2),
              ),
            ),
          ),
      ],
    );
  }

  Widget get _avatar {
    if (imageUrl != null && imageUrl!.isNotEmpty) {
      if (imageUrl!.startsWith('http')) {
        return CachedNetworkImage(
          imageUrl: imageUrl!,
          imageBuilder: (ctx, img) => CircleAvatar(
            radius: size / 2,
            backgroundImage: img,
          ),
          placeholder: (ctx, url) => _initialsAvatar,
          errorWidget: (ctx, url, err) => _initialsAvatar,
        );
      }
      return CircleAvatar(
        radius: size / 2,
        backgroundImage: AssetImage(imageUrl!),
      );
    }
    return _initialsAvatar;
  }

  Widget get _initialsAvatar {
    return CircleAvatar(
      radius: size / 2,
      backgroundColor: _bgColor,
      child: isGroup
          ? Icon(Icons.group_rounded, color: Colors.white, size: size * 0.5)
          : Text(
              _initials,
              style: OmegaTextStyles.labelLarge.copyWith(
                color: Colors.white,
                fontSize: size * 0.34,
                fontWeight: FontWeight.w600,
              ),
            ),
    );
  }
}
