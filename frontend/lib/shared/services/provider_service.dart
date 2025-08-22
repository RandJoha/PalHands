import 'dart:math';

import '../models/provider.dart';
import 'base_api_service.dart';

class ProviderService with BaseApiService {
  // Front-end-only mode to bypass backend calls for Our Services tab.
  // Intentionally hard-disabled backend usage to keep the UI snappy.
  static bool frontendOnly = true;
  static void useFrontendMocks([bool value = true]) => frontendOnly = value;

  // Fetch providers matching any of the selected services and optional city
  Future<List<ProviderModel>> fetchProviders({
    required List<String> servicesAny,
    String? city,
    String? sortBy, // 'rating' or 'price'
    String? sortOrder, // 'asc' | 'desc'
  }) async {
    // Always use mock data to avoid any backend latency on the Our Services tab
    final items = _mockProviders();
    return items.where((p) {
      final matchesServices = servicesAny.isEmpty || p.services.any((s) => servicesAny.contains(s));
      final matchesCity = city == null || city.isEmpty || p.city.toLowerCase() == city.toLowerCase();
      return matchesServices && matchesCity;
    }).toList()
      ..sort((a, b) {
        if (sortBy == 'price') {
          return sortOrder == 'asc' ? a.hourlyRate.compareTo(b.hourlyRate) : b.hourlyRate.compareTo(a.hourlyRate);
        } else if (sortBy == 'rating') {
          // Weighted rating using Bayesian average to consider review count
          // score = (v/(v+C))*R + (C/(v+C))*m, where m is global mean and C is prior weight
          final m = items.isEmpty ? 0.0 : items.map((e) => e.ratingAverage).reduce((x, y) => x + y) / items.length;
          const C = 20.0;
          double score(ProviderModel p) {
            final v = p.ratingCount.toDouble();
            final R = p.ratingAverage;
            return (v / (v + C)) * R + (C / (v + C)) * m;
          }
          final sA = score(a);
          final sB = score(b);
          return sortOrder == 'asc' ? sA.compareTo(sB) : sB.compareTo(sA);
        }
        return 0;
      });
  }

  List<ProviderModel> _mockProviders() {
    // Curated, realistic mock providers ensuring at least one provider per service
    final rnd = Random(3);
    final cities = ['Ramallah', 'Nablus', 'Jerusalem', 'Hebron', 'Bethlehem', 'Gaza'];
    final languagePools = [
      ['Arabic'],
      ['Arabic', 'English'],
      ['Arabic', 'Hebrew'],
      ['Arabic', 'Turkish'],
    ];

    // All service keys used in categories UI
    final allServices = <String>[
      // Cleaning
      'bedroomCleaning','livingRoomCleaning','kitchenCleaning','bathroomCleaning','windowCleaning','doorCabinetCleaning','floorCleaning','carpetCleaning','furnitureCleaning','gardenCleaning','entranceCleaning','stairCleaning','garageCleaning','postEventCleaning','postConstructionCleaning','apartmentCleaning','regularCleaning',
      // Organizing
      'bedroomOrganizing','kitchenOrganizing','closetOrganizing','storageOrganizing','livingRoomOrganizing','postPartyOrganizing','fullHouseOrganizing','childrenOrganizing',
      // Cooking
      'mainDishes','desserts','specialRequests',
      // Childcare
      'homeBabysitting','schoolAccompaniment','homeworkHelp','educationalActivities','childrenMealPrep','sickChildCare',
      // Elderly
      'homeElderlyCare','medicalTransport','healthMonitoring','medicationAssistance','emotionalSupport','mobilityAssistance',
      // Maintenance
      'electricalWork','plumbingWork','aluminumWork','carpentryWork','painting','hangingItems','satelliteInstallation','applianceMaintenance',
      // New Home
      'furnitureMoving','packingUnpacking','furnitureWrapping','newHomeArrangement','newApartmentCleaning','preOccupancyRepairs','kitchenSetup','applianceInstallation',
      // Misc
      'documentDelivery','shoppingDelivery','specialErrands','billPayment','prescriptionPickup',
    ];

    final names = <String>[
      // English
      'Rami Services','Maya Haddad','Omar Khalil','Sara Nasser','Khaled Mansour','Yara Saleh','Hadi Suleiman','Noor Ali','Lina Faris','Osama T.',
      'Adam Q.', 'Layla Z.', 'Sami R.', 'Dana M.', 'Fares K.',
      // Arabic
      'محمد العابد','سارة يوسف','ليلى حسن','أحمد درويش','نور الهدى','مريم خليل','رامي ناصر','عمر عوض','هالة سمير','رنا أحمد',
    ];

    final List<ProviderModel> providers = [];

    // Ensure coverage: create one provider per service at minimum
    for (var i = 0; i < allServices.length; i++) {
      final name = names[i % names.length];
      final city = cities[i % cities.length];
      final langs = languagePools[i % languagePools.length];
      final baseRate = 45 + (i % 50) + rnd.nextInt(20);
      providers.add(ProviderModel(
        id: 'svc_$i',
        name: name,
        city: city,
        phone: '+97059${rnd.nextInt(9999999).toString().padLeft(7, '0')}',
        experienceYears: 1 + (i % 10),
        languages: List<String>.from(langs),
        hourlyRate: baseRate.toDouble(),
        services: [allServices[i], if (i + 1 < allServices.length) allServices[i + 1]],
        ratingAverage: 3.8 + (rnd.nextDouble() * 1.2),
        ratingCount: 8 + (i % 90),
        avatarUrl: null,
      ));
    }

    // Add some multi-service, higher-review providers
    for (var j = 0; j < 18; j++) {
      final s = <String>{};
      for (var k = 0; k < 5; k++) {
        s.add(allServices[(j * 3 + k * 7) % allServices.length]);
      }
      providers.add(ProviderModel(
        id: 'pro_${j}',
        name: names[(j + 7) % names.length],
        city: cities[(j + 3) % cities.length],
        phone: '+97059${rnd.nextInt(9999999).toString().padLeft(7, '0')}',
        experienceYears: 3 + (j % 12),
        languages: List<String>.from(languagePools[(j + 1) % languagePools.length]),
        hourlyRate: 60 + rnd.nextInt(100).toDouble(),
        services: s.toList(),
        ratingAverage: 4.2 + (rnd.nextDouble() * 0.7),
        ratingCount: 40 + rnd.nextInt(260),
        avatarUrl: null,
      ));
    }

    return providers;
  }
}
