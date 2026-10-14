import 'package:flutter/cupertino.dart';

class AppColors {
  static const primary = Color(0xFFFF7A59);
  static const primarySoft = Color(0xFFFFF1EC);
  static const bg = Color(0xFFF4F5F9);
  static const card = Color(0xFFFFFFFF);
  static const text = Color(0xFF1E2231);
  static const muted = Color(0xFF8D94A8);
  static const line = Color(0xFFECEEF4);
  static const green = Color(0xFF28C76F);
  static const red = Color(0xFFFF4D4F);

  /// 卡片通用阴影 0 4px 18px rgba(30,34,49,.06)
  static const cardShadow = [
    BoxShadow(color: Color(0x0F1E2231), blurRadius: 18, offset: Offset(0, 4)),
  ];
}
