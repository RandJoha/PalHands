import 'package:flutter/material.dart';

class UserMenuItem {
  final String title;
  final IconData icon;
  final int index;
  final String? badge;
  final bool isActive;

  const UserMenuItem({
    required this.title,
    required this.icon,
    required this.index,
    this.badge,
    this.isActive = false,
  });

  UserMenuItem copyWith({
    String? title,
    IconData? icon,
    int? index,
    String? badge,
    bool? isActive,
  }) {
    return UserMenuItem(
      title: title ?? this.title,
      icon: icon ?? this.icon,
      index: index ?? this.index,
      badge: badge ?? this.badge,
      isActive: isActive ?? this.isActive,
    );
  }
} 