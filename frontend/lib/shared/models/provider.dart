import 'package:flutter/foundation.dart';

class ProviderMatchedService {
  final String? providerServiceId;
  final String? serviceId;
  final String? subcategory; // service key
  final String? title;       // human readable name
  final double? hourlyRate;  // per-service rate
  final int? experienceYears; // per-service experience (may mirror provider base)
  final bool emergencyEnabled;

  const ProviderMatchedService({
    this.providerServiceId,
    this.serviceId,
    this.subcategory,
    this.title,
    this.hourlyRate,
    this.experienceYears,
    this.emergencyEnabled = false,
  });

  factory ProviderMatchedService.fromJson(Map<String, dynamic> json) {
    return ProviderMatchedService(
      providerServiceId: json['providerServiceId']?.toString(),
      serviceId: json['serviceId']?.toString(),
      subcategory: json['subcategory']?.toString(),
      title: json['title']?.toString(),
      hourlyRate: (json['hourlyRate'] is int)
          ? (json['hourlyRate'] as int).toDouble()
          : (json['hourlyRate'] as num?)?.toDouble(),
      experienceYears: json['experienceYears'] is int ? json['experienceYears'] as int : (json['experienceYears'] as num?)?.toInt(),
      emergencyEnabled: json['emergencyEnabled'] == true,
    );
  }
}

class ProviderModel {
  final String id;
  final int? providerId; // 4-digit unique provider ID
  final String name;
  final String city;
  final String phone;
  final int experienceYears; // base experience (may differ from per-service)
  final List<String> languages;
  final double hourlyRate; // representative (e.g. min of matched services or base)
  final List<String> services; // matched service keys
  final double ratingAverage;
  final int ratingCount;
  final String? avatarUrl;
  final List<ProviderMatchedService> matchedServices; // detailed per-service linkage

  const ProviderModel({
    required this.id,
    this.providerId,
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
    this.matchedServices = const [],
  });

  factory ProviderModel.fromJson(Map<String, dynamic> json) {
    // Allow passing expanded endpoint shape by normalizing externally OR detecting nested provider object.
    if (json.containsKey('provider') && json['provider'] is Map) {
      final prov = json['provider'] as Map<String, dynamic>;
      final matchedRaw = (json['matchedServices'] as List?) ?? const [];
      final matched = matchedRaw
          .whereType<Map<String, dynamic>>()
          .map((m) => ProviderMatchedService.fromJson(m))
          .toList();
      // Derive representative hourlyRate (min of matched service rates, else provider baseHourlyRate)
      double derivedHourly = prov['baseHourlyRate'] is num ? (prov['baseHourlyRate'] as num).toDouble() : 0.0;
      if (matched.isNotEmpty) {
        final withRates = matched.where((m) => (m.hourlyRate ?? 0) > 0).toList();
        if (withRates.isNotEmpty) {
          withRates.sort((a, b) => (a.hourlyRate ?? 0).compareTo(b.hourlyRate ?? 0));
          derivedHourly = withRates.first.hourlyRate ?? derivedHourly;
        }
      }
      return ProviderModel(
        id: prov['_id']?.toString() ?? UniqueKey().toString(),
        providerId: prov['providerId'] as int?,
        name: [prov['firstName'] ?? '', prov['lastName'] ?? ''].where((e) => (e as String).isNotEmpty).join(' ').trim().isNotEmpty
            ? [prov['firstName'] ?? '', prov['lastName'] ?? ''].where((e) => (e as String).isNotEmpty).join(' ').trim()
            : (json['name'] ?? prov['name'] ?? 'Provider'),
        city: prov['city']?.toString() ?? 'Palestine',
        phone: prov['phone']?.toString() ?? '',
        experienceYears: prov['baseExperienceYears'] is num ? (prov['baseExperienceYears'] as num).toInt() : 0,
        languages: const [], // not provided by expanded endpoint yet
        hourlyRate: derivedHourly,
        services: matched.map((m) => m.subcategory).whereType<String>().toList(),
        ratingAverage: prov['rating'] is Map ? ((prov['rating']['average'] as num?)?.toDouble() ?? 0.0) : 0.0,
        ratingCount: prov['rating'] is Map ? ((prov['rating']['count'] as num?)?.toInt() ?? 0) : 0,
        avatarUrl: prov['avatarUrl']?.toString(),
        matchedServices: matched,
      );
    }
    return ProviderModel(
      id: json['_id']?.toString() ?? json['id']?.toString() ?? UniqueKey().toString(),
      providerId: json['providerId'] as int?,
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
      matchedServices: const [],
    );
  }
}
