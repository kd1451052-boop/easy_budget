import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ProfileAvatar extends StatelessWidget {
  final String imageUrl;
  final String frame;
  final double radius;

  const ProfileAvatar({
    super.key,
    required this.imageUrl,
    required this.frame,
    this.radius = 35,
  });

  @override
  Widget build(BuildContext context) {
    ImageProvider imageProvider;
    if (kIsWeb) {
      imageProvider = NetworkImage(imageUrl);
    } else if (imageUrl.startsWith('http')) {
      imageProvider = NetworkImage(imageUrl);
    } else {
      imageProvider = FileImage(File(imageUrl));
    }

    Widget avatar = CircleAvatar(
      radius: radius,
      backgroundImage: imageProvider,
    );

    if (frame == 'gold') {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Colors.yellow, Colors.orange, Colors.amber],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: avatar,
      );
    } else if (frame == 'neon') {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: Colors.cyanAccent.withValues(alpha: 0.8),
              blurRadius: 10,
              spreadRadius: 2,
            ),
          ],
          border: Border.all(color: Colors.cyanAccent, width: 2),
        ),
        child: avatar,
      );
    } else if (frame == 'minimal') {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade400, width: 2),
        ),
        child: avatar,
      );
    }

    return avatar; // none
  }
}
