/// 사용자/아이돌 아바타. URL 없으면 이니셜 표시.
library;

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

class Avatar extends StatelessWidget {
  const Avatar({
    super.key,
    this.imageUrl,
    required this.fallbackText,
    this.size = 40,
  });

  final String? imageUrl;
  final String fallbackText;
  final double size;

  @override
  Widget build(BuildContext context) {
    final initial = fallbackText.isNotEmpty ? fallbackText[0].toUpperCase() : '?';

    if (imageUrl == null || imageUrl!.isEmpty) {
      return CircleAvatar(
        radius: size / 2,
        child: Text(initial, style: TextStyle(fontSize: size * 0.4)),
      );
    }

    return ClipOval(
      child: CachedNetworkImage(
        imageUrl: imageUrl!,
        width: size,
        height: size,
        fit: BoxFit.cover,
        placeholder: (_, __) => CircleAvatar(radius: size / 2),
        errorWidget: (_, __, ___) => CircleAvatar(
          radius: size / 2,
          child: Text(initial, style: TextStyle(fontSize: size * 0.4)),
        ),
      ),
    );
  }
}
