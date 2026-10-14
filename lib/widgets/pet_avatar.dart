import 'dart:io';
import 'package:flutter/cupertino.dart';
import '../theme/app_colors.dart';

/// 宠物头像：自动区分 emoji 和图片路径
class PetAvatar extends StatelessWidget {
  final String avatar;
  final double size;
  final double radius;

  const PetAvatar({
    super.key,
    required this.avatar,
    this.size = 54,
    this.radius = 16,
  });

  /// 判断是否是文件路径（图片）
  static bool isImagePath(String s) {
    if (s.isEmpty) return false;
    return s.contains('/') ||
        s.contains('\\') ||
        s.endsWith('.jpg') ||
        s.endsWith('.jpeg') ||
        s.endsWith('.png') ||
        s.endsWith('.webp');
  }

  @override
  Widget build(BuildContext context) {
    final isImage = isImagePath(avatar);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppColors.primarySoft,
        borderRadius: BorderRadius.circular(radius),
        image: isImage
            ? DecorationImage(image: FileImage(File(avatar)), fit: BoxFit.cover)
            : null,
      ),
      child: isImage
          ? null
          : Text(
              avatar.isEmpty ? '🐾' : avatar,
              style: TextStyle(fontSize: size * 0.52, height: 1),
            ),
    );
  }
}
