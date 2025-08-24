import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';

// Services
import '../../../../shared/services/services_api_service.dart';
import '../../../../shared/services/language_service.dart';

// Widgets
import '../widgets/service_card.dart';
import '../widgets/search_filters.dart';

class ServiceSearchScreen extends StatefulWidget {
  const ServiceSearchScreen({super.key});

  @override
  State<ServiceSearchScreen> createState() => _ServiceSearchScreenState();
}

class _ServiceSearchScreenState extends State<ServiceSearchScreen> {
  final _searchController = TextEditingController();
  final _servicesApi = ServicesApiService();
  
  List<Service> _services = [];
  List<Service> _filteredServices = [];
  bool _isLoading = false;
  String _errorMessage = '';
  String _searchQuery = '';
  String _selectedCategory = '';
  String _selectedLocation = '';
  
  int _currentPage = 1;
  int _totalPages = 0;
  int _totalRecords = 0;
  bool _hasMorePages = false;

  @override
  void initState() {
    super.initState();
    _loadServices();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadServices({bool isSearch = false}) async {
    if (_isLoading) return;

    setState(() {
      _isLoading = true;
      _errorMessage = '';
    });

    try {
      final response = await _servicesApi.listServices(
        query: _searchQuery.isNotEmpty ? _searchQuery : null,
        category: _selectedCategory.isNotEmpty ? _selectedCategory : null,
        area: _selectedLocation.isNotEmpty ? _selectedLocation : null,
        page: _currentPage,
        limit: 20,
      );

      if (response['error'] != null) {
        setState(() {
          _errorMessage = response['error'];
          _isLoading = false;
        });
        return;
      }

      final servicesData = response['services'] as List;
      final pagination = response['pagination'] as Map<String, dynamic>;
      
      final newServices = servicesData.map((data) => Service.fromJson(data)).toList();
      
      setState(() {
        if (isSearch || _currentPage == 1) {
          _services = newServices;
        } else {
          _services.addAll(newServices);
        }
        
        _filteredServices = _services;
        _totalPages = pagination['total'] ?? 0;
        _totalRecords = pagination['totalRecords'] ?? 0;
        _hasMorePages = _currentPage < _totalPages;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to load services. Please try again.';
        _isLoading = false;
      });
    }
  }

  Future<void> _searchServices() async {
    _searchQuery = _searchController.text.trim();
    _currentPage = 1;
    await _loadServices(isSearch: true);
  }

  Future<void> _loadMoreServices() async {
    if (_hasMorePages && !_isLoading) {
      _currentPage++;
      await _loadServices();
    }
  }

  void _onCategoryChanged(String category) {
    setState(() {
      _selectedCategory = category;
    });
    _currentPage = 1;
    _loadServices(isSearch: true);
  }

  void _onLocationChanged(String location) {
    setState(() {
      _selectedLocation = location;
    });
    _currentPage = 1;
    _loadServices(isSearch: true);
  }

  void _clearFilters() {
    setState(() {
      _selectedCategory = '';
      _selectedLocation = '';
      _searchQuery = '';
    });
    _searchController.clear();
    _currentPage = 1;
    _loadServices(isSearch: true);
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          backgroundColor: AppColors.background,
          appBar: AppBar(
            title: Text(
              AppStrings.getString('searchServices', languageService.currentLanguage),
              style: GoogleFonts.cairo(
                fontWeight: FontWeight.bold,
                color: AppColors.white,
              ),
            ),
            backgroundColor: AppColors.primary,
            elevation: 0,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back, color: AppColors.white),
              onPressed: () => Navigator.of(context).pop(),
            ),
          ),
          body: Column(
            children: [
              // Search and Filters Section
              _buildSearchSection(languageService),
              
              // Results Section
              Expanded(
                child: _buildResultsSection(languageService),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSearchSection(LanguageService languageService) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        children: [
          // Search Bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: AppStrings.getString('searchServices', languageService.currentLanguage),
              prefixIcon: const Icon(Icons.search, color: AppColors.primary),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear, color: AppColors.primary),
                      onPressed: () {
                        _searchController.clear();
                        _searchServices();
                      },
                    )
                  : null,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.border),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.primary, width: 2),
              ),
            ),
            onSubmitted: (_) => _searchServices(),
          ),
          
          const SizedBox(height: 16),
          
          // Filters
          SearchFilters(
            selectedCategory: _selectedCategory,
            selectedLocation: _selectedLocation,
            onCategoryChanged: _onCategoryChanged,
            onLocationChanged: _onLocationChanged,
            onClearFilters: _clearFilters,
          ),
        ],
      ),
    );
  }

  Widget _buildResultsSection(LanguageService languageService) {
    if (_isLoading && _services.isEmpty) {
      return const Center(
        child: CircularProgressIndicator(color: AppColors.primary),
      );
    }

    if (_errorMessage.isNotEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 64,
              color: AppColors.error,
            ),
            const SizedBox(height: 16),
            Text(
              _errorMessage,
              style: GoogleFonts.cairo(
                fontSize: 16,
                color: AppColors.error,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: _loadServices,
              child: Text('Retry'),
            ),
          ],
        ),
      );
    }

    if (_services.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.search_off,
              size: 64,
              color: AppColors.textLight,
            ),
            const SizedBox(height: 16),
            Text(
              'No services found',
              style: GoogleFonts.cairo(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: AppColors.textDark,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Try adjusting your search criteria',
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.textLight,
              ),
            ),
          ],
        ),
      );
    }

    return Column(
      children: [
        // Results Header
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          color: AppColors.white,
          child: Row(
            children: [
              Text(
                '${_totalRecords} services found',
                style: GoogleFonts.cairo(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textDark,
                ),
              ),
              const Spacer(),
              if (_searchQuery.isNotEmpty || _selectedCategory.isNotEmpty || _selectedLocation.isNotEmpty)
                TextButton(
                  onPressed: _clearFilters,
                  child: Text(
                    'Clear filters',
                    style: GoogleFonts.cairo(
                      color: AppColors.primary,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
            ],
          ),
        ),
        
        // Services List
        Expanded(
          child: RefreshIndicator(
            onRefresh: () async {
              _currentPage = 1;
              await _loadServices(isSearch: true);
            },
            child: ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _services.length + (_hasMorePages ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _services.length) {
                  // Load more indicator
                  return _buildLoadMoreIndicator();
                }
                
                final service = _services[index];
                return Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: ServiceCard(
                    service: service,
                    onTap: () => _onServiceTap(service),
                  ),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadMoreIndicator() {
    if (_isLoading) {
      return const Padding(
        padding: EdgeInsets.all(16),
        child: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    }
    
    if (_hasMorePages) {
      return Padding(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ElevatedButton(
            onPressed: _loadMoreServices,
            child: Text('Load More Services'),
          ),
        ),
      );
    }
    
    return const SizedBox.shrink();
  }

  void _onServiceTap(Service service) {
    // TODO: Navigate to service details page
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Service: ${service.title}'),
        backgroundColor: AppColors.primary,
      ),
    );
  }
}
