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
    Widget avatar;
    if (imageUrl.isEmpty) {
      avatar = CircleAvatar(
        radius: radius,
        backgroundColor: Colors.grey.shade200,
        child: Icon(Icons.person, size: radius, color: Colors.grey.shade400),
      );
    } else {
      ImageProvider imageProvider;
      if (kIsWeb) {
        imageProvider = NetworkImage(imageUrl);
      } else if (imageUrl.startsWith('http')) {
        imageProvider = NetworkImage(imageUrl);
      } else {
        imageProvider = FileImage(File(imageUrl));
      }

      avatar = CircleAvatar(
        radius: radius,
        backgroundImage: imageProvider,
      );
    }

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
          boxShadow: [
            BoxShadow(
              color: Colors.orangeAccent,
              blurRadius: 8,
              spreadRadius: 1,
            ),
          ],
        ),
        child: avatar,
      );
    } else if (frame == 'silver') {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFE0E0E0), Color(0xFFBDBDBD), Color(0xFF9E9E9E)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: avatar,
      );
    } else if (frame == 'bronze') {
      return Container(
        padding: const EdgeInsets.all(4),
        decoration: const BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: [Color(0xFFCD7F32), Color(0xFFA0522D), Color(0xFF8B4513)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
        ),
        child: avatar,
      );
    }

    return avatar; // none
  }
}
