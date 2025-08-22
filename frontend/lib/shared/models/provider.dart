import 'package:flutter/foundation.dart';

class ProviderModel {
  final String id;
  final String name;
  final String city;
  final String phone;
  final int experienceYears;
  final List<String> languages;
  final double hourlyRate;
  final List<String> services;
  final double ratingAverage;
  final int ratingCount;
  final String? avatarUrl;

  const ProviderModel({
    required this.id,
    required this.name,
    required this.city,
    required this.phone,
    required this.experienceYears,
    required this.languages,
    required this.hourlyRate,
    required this.services,
    required this.ratingAverage,
    required this.ratingCount,
    this.avatarUrl,
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    return ProviderModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? UniqueKey().toString(),
      name: json['name'] ?? 'Provider',
      city: json['city'] ?? json['location'] ?? 'Palestine',
      phone: json['phone'] ?? '',
      experienceYears: (json['experienceYears'] ?? 0) as int,
      languages: (json['languages'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      hourlyRate: (json['hourlyRate'] is int)
          ? (json['hourlyRate'] as int).toDouble()
          : (json['hourlyRate'] as num?)?.toDouble() ?? 0.0,
      services: (json['services'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      ratingAverage: (json['rating'] is Map)
          ? (((json['rating'] as Map)['average'] as num?)?.toDouble() ?? 0.0)
          : (json['ratingAverage'] as num?)?.toDouble() ?? 0.0,
      ratingCount: (json['rating'] is Map)
          ? (((json['rating'] as Map)['count'] as num?)?.toInt() ?? 0)
          : (json['ratingCount'] as num?)?.toInt() ?? 0,
      avatarUrl: json['avatarUrl']?.toString(),
    );
  }
}
