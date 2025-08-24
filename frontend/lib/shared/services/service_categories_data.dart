// Service Categories and Predefined Services Data

class ServiceCategory {
  final String id;
  final String name;
  final String description;
  final String? icon;
  final String? color;
  final bool isActive;

  const ServiceCategory({
    required this.id,
    required this.name,
    required this.description,
    this.icon,
    this.color,
    required this.isActive,
  });

  factory ServiceCategory.fromJson(Map<String, dynamic> json) {
    return ServiceCategory(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      description: json['description'] ?? '',
      icon: json['icon'],
      color: json['color'],
      isActive: json['isActive'] ?? true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'icon': icon,
      'color': color,
      'isActive': isActive,
    };
  }
}

class ServiceCategoriesData {
  static const List<ServiceCategory> categories = [
    ServiceCategory(
      id: 'cleaning',
      name: 'Cleaning',
      description: 'House cleaning and maintenance services',
      icon: 'cleaning',
      color: '#4CAF50',
      isActive: true,
    ),
    ServiceCategory(
      id: 'childcare',
      name: 'Childcare',
      description: 'Childcare and educational services',
      icon: 'childcare',
      color: '#FF9800',
      isActive: true,
    ),
    ServiceCategory(
      id: 'elderly',
      name: 'Elderly Care',
      description: 'Elderly care and support services',
      icon: 'elderly',
      color: '#2196F3',
      isActive: true,
    ),
    ServiceCategory(
      id: 'maintenance',
      name: 'Maintenance',
      description: 'Home maintenance and repair services',
      icon: 'maintenance',
      color: '#9C27B0',
      isActive: true,
    ),
    ServiceCategory(
      id: 'cooking',
      name: 'Cooking',
      description: 'Cooking and meal preparation services',
      icon: 'cooking',
      color: '#F44336',
      isActive: true,
    ),
    ServiceCategory(
      id: 'organizing',
      name: 'Organizing',
      description: 'Home organization and decluttering services',
      icon: 'organizing',
      color: '#795548',
      isActive: true,
    ),
    ServiceCategory(
      id: 'newhome',
      name: 'New Home',
      description: 'Moving and new home setup services',
      icon: 'newhome',
      color: '#607D8B',
      isActive: true,
    ),
    ServiceCategory(
      id: 'miscellaneous',
      name: 'Miscellaneous',
      description: 'Other specialized services',
      icon: 'miscellaneous',
      color: '#FF5722',
      isActive: true,
    ),
  ];

  static const List<PredefinedService> predefinedServices = [
    // Cleaning Services
    PredefinedService(
      id: 'bedroom_cleaning',
      title: 'Bedroom Cleaning',
      description: 'Professional bedroom cleaning service including dusting, vacuuming, and sanitizing',
      category: 'cleaning',
      subcategory: 'bedroomCleaning',
      defaultPrice: 25.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'kitchen_cleaning',
      title: 'Kitchen Cleaning',
      description: 'Deep kitchen cleaning including appliances, countertops, and cabinets',
      category: 'cleaning',
      subcategory: 'kitchenCleaning',
      defaultPrice: 30.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'bathroom_cleaning',
      title: 'Bathroom Cleaning',
      description: 'Thorough bathroom cleaning and sanitization',
      category: 'cleaning',
      subcategory: 'bathroomCleaning',
      defaultPrice: 28.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'living_room_cleaning',
      title: 'Living Room Cleaning',
      description: 'Living room cleaning and organization',
      category: 'cleaning',
      subcategory: 'livingRoomCleaning',
      defaultPrice: 27.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'entrance_cleaning',
      title: 'Entrance Cleaning',
      description: 'Entrance area cleaning and maintenance',
      category: 'cleaning',
      subcategory: 'entranceCleaning',
      defaultPrice: 20.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'stair_cleaning',
      title: 'Stair Cleaning',
      description: 'Stair cleaning and maintenance',
      category: 'cleaning',
      subcategory: 'stairCleaning',
      defaultPrice: 22.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'garage_cleaning',
      title: 'Garage Cleaning',
      description: 'Comprehensive garage cleaning and organization',
      category: 'cleaning',
      subcategory: 'garageCleaning',
      defaultPrice: 35.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'post_event_cleaning',
      title: 'Post-Event Cleaning',
      description: 'Post-event cleanup and restoration',
      category: 'cleaning',
      subcategory: 'postEventCleaning',
      defaultPrice: 40.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),

    // Childcare Services
    PredefinedService(
      id: 'home_babysitting',
      title: 'Home Babysitting',
      description: 'Professional in-home childcare service',
      category: 'childcare',
      subcategory: 'homeBabysitting',
      defaultPrice: 35.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'homework_help',
      title: 'Homework Help',
      description: 'Educational support and homework assistance',
      category: 'childcare',
      subcategory: 'homeworkHelp',
      defaultPrice: 30.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'school_accompaniment',
      title: 'School Accompaniment',
      description: 'Safe school transportation and accompaniment',
      category: 'childcare',
      subcategory: 'schoolAccompaniment',
      defaultPrice: 25.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'children_meal_prep',
      title: 'Children Meal Preparation',
      description: 'Healthy meal preparation for children',
      category: 'childcare',
      subcategory: 'childrenMealPrep',
      defaultPrice: 32.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),

    // Elderly Care Services
    PredefinedService(
      id: 'home_elderly_care',
      title: 'Home Elderly Care',
      description: 'Professional elderly care and support',
      category: 'elderly',
      subcategory: 'homeElderlyCare',
      defaultPrice: 45.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'health_monitoring',
      title: 'Health Monitoring',
      description: 'Regular health monitoring and check-ins',
      category: 'elderly',
      subcategory: 'healthMonitoring',
      defaultPrice: 40.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),

    // Maintenance Services
    PredefinedService(
      id: 'electrical_work',
      title: 'Electrical Work',
      description: 'Professional electrical work and repairs',
      category: 'maintenance',
      subcategory: 'electricalWork',
      defaultPrice: 50.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'plumbing_work',
      title: 'Plumbing Work',
      description: 'Expert plumbing services and repairs',
      category: 'maintenance',
      subcategory: 'plumbingWork',
      defaultPrice: 45.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'carpentry_work',
      title: 'Carpentry Work',
      description: 'Quality carpentry and woodwork',
      category: 'maintenance',
      subcategory: 'carpentryWork',
      defaultPrice: 55.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'painting',
      title: 'Painting',
      description: 'Professional painting services',
      category: 'maintenance',
      subcategory: 'painting',
      defaultPrice: 40.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'appliance_maintenance',
      title: 'Appliance Maintenance',
      description: 'Appliance maintenance and repair',
      category: 'maintenance',
      subcategory: 'applianceMaintenance',
      defaultPrice: 48.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'aluminum_work',
      title: 'Aluminum Work',
      description: 'Professional aluminum work and installation',
      category: 'maintenance',
      subcategory: 'aluminumWork',
      defaultPrice: 42.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),

    // Cooking Services
    PredefinedService(
      id: 'main_dishes',
      title: 'Main Dishes',
      description: 'Home-cooked main dishes preparation',
      category: 'cooking',
      subcategory: 'mainDishes',
      defaultPrice: 35.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'desserts',
      title: 'Desserts',
      description: 'Delicious dessert preparation',
      category: 'cooking',
      subcategory: 'desserts',
      defaultPrice: 30.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'special_requests',
      title: 'Special Cooking Requests',
      description: 'Custom cooking requests and special meals',
      category: 'cooking',
      subcategory: 'specialRequests',
      defaultPrice: 40.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),

    // Organizing Services
    PredefinedService(
      id: 'bedroom_organizing',
      title: 'Bedroom Organizing',
      description: 'Bedroom organization and decluttering',
      category: 'organizing',
      subcategory: 'bedroomOrganizing',
      defaultPrice: 35.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'kitchen_organizing',
      title: 'Kitchen Organizing',
      description: 'Kitchen organization and storage optimization',
      category: 'organizing',
      subcategory: 'kitchenOrganizing',
      defaultPrice: 38.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'living_room_organizing',
      title: 'Living Room Organizing',
      description: 'Living room organization and arrangement',
      category: 'organizing',
      subcategory: 'livingRoomOrganizing',
      defaultPrice: 32.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),

    // New Home Services
    PredefinedService(
      id: 'furniture_moving',
      title: 'Furniture Moving',
      description: 'Safe and professional furniture moving',
      category: 'newhome',
      subcategory: 'furnitureMoving',
      defaultPrice: 45.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'packing_unpacking',
      title: 'Packing & Unpacking',
      description: 'Efficient packing and unpacking services',
      category: 'newhome',
      subcategory: 'packingUnpacking',
      defaultPrice: 40.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'kitchen_setup',
      title: 'Kitchen Setup',
      description: 'Complete kitchen setup and organization',
      category: 'newhome',
      subcategory: 'kitchenSetup',
      defaultPrice: 50.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'pre_occupancy_repairs',
      title: 'Pre-Occupancy Repairs',
      description: 'Pre-occupancy repairs and maintenance',
      category: 'newhome',
      subcategory: 'preOccupancyRepairs',
      defaultPrice: 55.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),

    // Miscellaneous Services
    PredefinedService(
      id: 'shopping_delivery',
      title: 'Shopping Delivery',
      description: 'Reliable shopping and delivery service',
      category: 'miscellaneous',
      subcategory: 'shoppingDelivery',
      defaultPrice: 25.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
    PredefinedService(
      id: 'bill_payment',
      title: 'Bill Payment',
      description: 'Convenient bill payment service',
      category: 'miscellaneous',
      subcategory: 'billPayment',
      defaultPrice: 20.0,
      priceType: 'hourly',
      currency: 'ILS',
    ),
  ];

  // Get services by category
  static List<PredefinedService> getServicesByCategory(String categoryId) {
    return predefinedServices.where((service) => service.category == categoryId).toList();
  }

  // Get all categories
  static List<ServiceCategory> getAllCategories() {
    return categories;
  }

  // Get category by ID
  static ServiceCategory? getCategoryById(String categoryId) {
    try {
      return categories.firstWhere((category) => category.id == categoryId);
    } catch (e) {
      return null;
    }
  }

  // Get service by ID
  static PredefinedService? getServiceById(String serviceId) {
    try {
      return predefinedServices.firstWhere((service) => service.id == serviceId);
    } catch (e) {
      return null;
    }
  }

  // Search services
  static List<PredefinedService> searchServices(String query) {
    final lowercaseQuery = query.toLowerCase();
    return predefinedServices.where((service) {
      return service.title.toLowerCase().contains(lowercaseQuery) ||
             service.description.toLowerCase().contains(lowercaseQuery) ||
             service.category.toLowerCase().contains(lowercaseQuery);
    }).toList();
  }

  // Get subcategories by category
  static List<String> getSubcategoriesByCategory(String categoryId) {
    final services = getServicesByCategory(categoryId);
    final subcategories = services.map((service) => service.subcategory).toSet().toList();
    subcategories.sort();
    return subcategories;
  }

  // Get subcategory display name
  static String getSubcategoryDisplayName(String subcategory) {
    final subcategoryNames = {
      // Cleaning
      'bedroomCleaning': 'Bedroom Cleaning',
      'kitchenCleaning': 'Kitchen Cleaning',
      'bathroomCleaning': 'Bathroom Cleaning',
      'livingRoomCleaning': 'Living Room Cleaning',
      'entranceCleaning': 'Entrance Cleaning',
      'stairCleaning': 'Stair Cleaning',
      'garageCleaning': 'Garage Cleaning',
      'postEventCleaning': 'Post-Event Cleaning',
      
      // Childcare
      'homeBabysitting': 'Home Babysitting',
      'homeworkHelp': 'Homework Help',
      'schoolAccompaniment': 'School Accompaniment',
      'childrenMealPrep': 'Children Meal Preparation',
      
      // Elderly
      'homeElderlyCare': 'Home Elderly Care',
      'healthMonitoring': 'Health Monitoring',
      
      // Maintenance
      'electricalWork': 'Electrical Work',
      'plumbingWork': 'Plumbing Work',
      'carpentryWork': 'Carpentry Work',
      'painting': 'Painting',
      'applianceMaintenance': 'Appliance Maintenance',
      'aluminumWork': 'Aluminum Work',
      
      // Cooking
      'mainDishes': 'Main Dishes',
      'desserts': 'Desserts',
      'specialRequests': 'Special Cooking Requests',
      
      // Organizing
      'bedroomOrganizing': 'Bedroom Organizing',
      'kitchenOrganizing': 'Kitchen Organizing',
      'livingRoomOrganizing': 'Living Room Organizing',
      
      // New Home
      'furnitureMoving': 'Furniture Moving',
      'packingUnpacking': 'Packing & Unpacking',
      'kitchenSetup': 'Kitchen Setup',
      'preOccupancyRepairs': 'Pre-Occupancy Repairs',
      
      // Miscellaneous
      'shoppingDelivery': 'Shopping Delivery',
      'billPayment': 'Bill Payment',
    };
    
    return subcategoryNames[subcategory] ?? subcategory;
  }

  // Get services by subcategory
  static List<PredefinedService> getServicesBySubcategory(String categoryId, String subcategory) {
    return predefinedServices.where((service) => 
        service.category == categoryId && service.subcategory == subcategory).toList();
  }
}

class PredefinedService {
  final String id;
  final String title;
  final String description;
  final String category;
  final String subcategory;
  final double defaultPrice;
  final String priceType;
  final String currency;

  const PredefinedService({
    required this.id,
    required this.title,
    required this.description,
    required this.category,
    required this.subcategory,
    required this.defaultPrice,
    required this.priceType,
    required this.currency,
  });

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'description': description,
      'category': category,
      'subcategory': subcategory,
      'defaultPrice': defaultPrice,
      'priceType': priceType,
      'currency': currency,
    };
  }

  factory PredefinedService.fromJson(Map<String, dynamic> json) {
    return PredefinedService(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      category: json['category'] ?? '',
      subcategory: json['subcategory'] ?? '',
      defaultPrice: (json['defaultPrice'] ?? 0).toDouble(),
      priceType: json['priceType'] ?? 'hourly',
      currency: json['currency'] ?? 'ILS',
    );
  }
}
