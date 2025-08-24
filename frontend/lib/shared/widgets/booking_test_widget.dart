import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../services/services_api_service.dart';
import '../services/language_service.dart';
import '../../core/constants/app_colors.dart';

class BookingTestWidget extends StatefulWidget {
  const BookingTestWidget({Key? key}) : super(key: key);

  @override
  State<BookingTestWidget> createState() => _BookingTestWidgetState();
}

class _BookingTestWidgetState extends State<BookingTestWidget> {
  final ServicesApiService _servicesApi = ServicesApiService();
  List<Service> _services = [];
  List<Booking> _bookings = [];
  bool _isLoading = false;
  String _statusMessage = '';

  @override
  void initState() {
    super.initState();
    _loadTestData();
  }

  Future<void> _loadTestData() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Loading test data...';
    });

    try {
      // Load services
      final servicesResponse = await _servicesApi.listServices(page: 1, limit: 5);
      if (servicesResponse['services'] != null) {
        final servicesData = servicesResponse['services'] as List;
        _services = servicesData.map((data) => Service.fromJson(data)).toList();
      }

      // Load bookings
      _bookings = await _servicesApi.getMyBookings();

      setState(() {
        _statusMessage = 'Loaded ${_services.length} services and ${_bookings.length} bookings';
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _statusMessage = 'Error loading data: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testCreateBooking() async {
    if (_services.isEmpty) {
      setState(() {
        _statusMessage = 'No services available for testing';
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = 'Creating test booking...';
    });

    try {
      final service = _services.first;
      final tomorrow = DateTime.now().add(const Duration(days: 1));
      final date = '${tomorrow.year}-${tomorrow.month.toString().padLeft(2, '0')}-${tomorrow.day.toString().padLeft(2, '0')}';

      final booking = await _servicesApi.createBooking(
        serviceId: service.id,
        date: date,
        startTime: '10:00',
        endTime: '12:00',
        address: 'Test Address, Ramallah',
        notes: 'Test booking created from widget',
      );

      setState(() {
        _statusMessage = 'Booking created successfully! ID: ${booking.bookingId}';
        _isLoading = false;
      });

      // Reload bookings
      _bookings = await _servicesApi.getMyBookings();
    } catch (e) {
      setState(() {
        _statusMessage = 'Error creating booking: $e';
        _isLoading = false;
      });
    }
  }

  Future<void> _testSearchServices() async {
    setState(() {
      _isLoading = true;
      _statusMessage = 'Searching for "cleaning"...';
    });

    try {
      final response = await _servicesApi.listServices(
        query: 'cleaning',
        page: 1,
        limit: 10,
      );

      if (response['services'] != null) {
        final servicesData = response['services'] as List;
        final searchResults = servicesData.map((data) => Service.fromJson(data)).toList();
        
        setState(() {
          _statusMessage = 'Search found ${searchResults.length} services for "cleaning"';
          _isLoading = false;
        });
      } else {
        setState(() {
          _statusMessage = 'No search results found';
          _isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        _statusMessage = 'Search error: $e';
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        return Scaffold(
          appBar: AppBar(
            title: Text(
              'Booking & Services Test',
              style: GoogleFonts.cairo(fontWeight: FontWeight.bold),
            ),
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
          ),
          body: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Status message
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: _statusMessage.contains('Error') 
                        ? AppColors.error.withValues(alpha: 0.1)
                        : AppColors.primary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: _statusMessage.contains('Error') 
                          ? AppColors.error.withValues(alpha: 0.3)
                          : AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    _statusMessage,
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: _statusMessage.contains('Error') 
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Test buttons
                Row(
                  children: [
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _loadTestData,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Load Data',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _testSearchServices,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.success,
                          foregroundColor: Colors.white,
                        ),
                        child: Text(
                          'Test Search',
                          style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading || _services.isEmpty ? null : _testCreateBooking,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.warning,
                      foregroundColor: Colors.white,
                    ),
                    child: Text(
                      'Test Create Booking',
                      style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                    ),
                  ),
                ),
                const SizedBox(height: 20),

                // Services list
                Text(
                  'Available Services (${_services.length})',
                  style: GoogleFonts.cairo(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: AppColors.greyDark,
                  ),
                ),
                const SizedBox(height: 8),
                if (_services.isEmpty)
                  Text(
                    'No services available',
                    style: GoogleFonts.cairo(
                      fontSize: 14,
                      color: AppColors.grey,
                    ),
                  )
                else
                  Expanded(
                    child: ListView.builder(
                      itemCount: _services.length,
                      itemBuilder: (context, index) {
                        final service = _services[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              service.title,
                              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              '${service.price['amount']} ${service.price['currency']} / ${service.price['type']}',
                              style: GoogleFonts.cairo(fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: service.isActive ? AppColors.success : AppColors.grey,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                service.isActive ? 'Active' : 'Inactive',
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                // Bookings list
                if (_bookings.isNotEmpty) ...[
                  const SizedBox(height: 20),
                  Text(
                    'My Bookings (${_bookings.length})',
                    style: GoogleFonts.cairo(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.greyDark,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 100,
                    child: ListView.builder(
                      itemCount: _bookings.length,
                      itemBuilder: (context, index) {
                        final booking = _bookings[index];
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(
                              booking.bookingId,
                              style: GoogleFonts.cairo(fontWeight: FontWeight.w600),
                            ),
                            subtitle: Text(
                              'Status: ${booking.status}',
                              style: GoogleFonts.cairo(fontSize: 12),
                            ),
                            trailing: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                              decoration: BoxDecoration(
                                color: _getStatusColor(booking.status),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                booking.status,
                                style: GoogleFonts.cairo(
                                  fontSize: 10,
                                  color: Colors.white,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ],

                // Loading indicator
                if (_isLoading)
                  const Center(
                    child: Padding(
                      padding: EdgeInsets.all(16.0),
                      child: CircularProgressIndicator(),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'pending':
        return AppColors.warning;
      case 'confirmed':
        return AppColors.success;
      case 'in_progress':
        return AppColors.primary;
      case 'completed':
        return AppColors.success;
      case 'cancelled':
        return AppColors.error;
      default:
        return AppColors.grey;
    }
  }
}
