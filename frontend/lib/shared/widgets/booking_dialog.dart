import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// Core imports
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';

// Shared imports
import '../models/provider.dart';
import '../models/booking.dart';
import '../services/booking_service.dart';
import '../services/language_service.dart';
import 'app_toast.dart';
import '../services/auth_service.dart';

class BookingDialog extends StatefulWidget {
  final ProviderModel provider;
  final String? selectedService;

  const BookingDialog({
    super.key,
    required this.provider,
    this.selectedService,
  });

  @override
  State<BookingDialog> createState() => _BookingDialogState();
}

class _BookingDialogState extends State<BookingDialog> {
  final _formKey = GlobalKey<FormState>();
  final BookingService _bookingService = BookingService();

  // Form controllers
  final _addressController = TextEditingController();
  final _instructionsController = TextEditingController();
  final _notesController = TextEditingController();
  String? _selectedAddressId; // index as string for saved addresses

  // Form state
  DateTime? _selectedDate;
  TimeOfDay? _startTime;
  TimeOfDay? _endTime;
  String? _selectedService;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _selectedService = widget.selectedService ?? widget.provider.services.first;
    // Set default date to tomorrow
    _selectedDate = DateTime.now().add(const Duration(days: 1));
    // Set default times
    _startTime = const TimeOfDay(hour: 9, minute: 0);
    _endTime = const TimeOfDay(hour: 12, minute: 0);
  }

  @override
  void dispose() {
    _addressController.dispose();
    _instructionsController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _selectDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? DateTime.now().add(const Duration(days: 1)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 90)),
    );
    
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _selectTime(bool isStartTime) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: isStartTime 
          ? (_startTime ?? const TimeOfDay(hour: 9, minute: 0))
          : (_endTime ?? const TimeOfDay(hour: 12, minute: 0)),
    );
    
    if (picked != null) {
      setState(() {
        if (isStartTime) {
          _startTime = picked;
          // Auto-adjust end time to be at least 1 hour after start time
          if (_endTime != null) {
            final startMinutes = picked.hour * 60 + picked.minute;
            final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
            if (endMinutes <= startMinutes) {
              _endTime = TimeOfDay(
                hour: (startMinutes + 60) ~/ 60,
                minute: (startMinutes + 60) % 60,
              );
            }
          }
        } else {
          _endTime = picked;
        }
      });
    }
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }

  String _formatTime(TimeOfDay time) {
    return '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
  }

  double _calculateEstimatedCost() {
    if (_startTime == null || _endTime == null) return 0.0;
    
    final startMinutes = _startTime!.hour * 60 + _startTime!.minute;
    final endMinutes = _endTime!.hour * 60 + _endTime!.minute;
    final hours = (endMinutes - startMinutes) / 60.0;
    
    return hours * widget.provider.hourlyRate;
  }

  Future<void> _submitBooking() async {
    if (!_formKey.currentState!.validate()) return;
    if (_selectedDate == null || _startTime == null || _endTime == null) {
      AppToast.show(context, message: 'Please select date and time');
      return;
    }

    setState(() {
      _loading = true;
    });

    try {
      // For now, we'll use a dummy service ID. In a real implementation,
      // you'd need to fetch the actual service ID from the backend
      const serviceId = 'dummy_service_id';

      final schedule = Schedule(
        date: _selectedDate!.toIso8601String().split('T')[0],
        startTime: _formatTime(_startTime!),
        endTime: _formatTime(_endTime!),
        timezone: 'Asia/Jerusalem',
      );

      final location = Location(
        address: _addressController.text,
        instructions: _instructionsController.text.isNotEmpty 
            ? _instructionsController.text 
            : null,
      );

      final request = CreateBookingRequest(
        serviceId: serviceId,
        schedule: schedule,
        location: location,
        notes: _notesController.text.isNotEmpty ? _notesController.text : null,
      );

      await _bookingService.createBooking(request);
      
      if (mounted) {
        Navigator.of(context).pop();
        AppToast.show(context, message: 'Booking created successfully!');
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Failed to create booking: $e');
      }
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final languageService = Provider.of<LanguageService>(context);
    final lang = languageService.currentLanguage;
    final isRtl = languageService.textDirection == TextDirection.rtl;
  final media = MediaQuery.of(context);
  final screenW = media.size.width;
  final screenH = media.size.height;
  final isCompact = screenW < 480; // very small/mobile
  final isNarrow = screenW < 640;  // small tablets/narrow windows
  final dialogMaxWidth = isCompact ? screenW - 24 : (isNarrow ? 560.0 : 640.0);
    final auth = Provider.of<AuthService>(context, listen: true);
    final savedAddresses = (auth.currentUser?['addresses'] as List<dynamic>?)
            ?.map((e) => Map<String, dynamic>.from(e as Map))
            .toList() ??
        const <Map<String, dynamic>>[];
    // Prefill default address text on first build
    if (_addressController.text.isEmpty && savedAddresses.isNotEmpty) {
      final def = savedAddresses.firstWhere(
        (a) => a['isDefault'] == true,
        orElse: () => savedAddresses.first,
      );
      _addressController.text = _formatAddress(def, lang);
      _selectedAddressId = savedAddresses.indexOf(def).toString();
    }
    
    return Directionality(
      textDirection: isRtl ? TextDirection.rtl : TextDirection.ltr,
      child: Dialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16.0),
        ),
        child: Container(
        width: dialogMaxWidth,
        constraints: BoxConstraints(
          // On small screens allow taller dialogs while still staying within view
          maxHeight: screenH * (isCompact ? 0.95 : 0.85),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: const BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      '${AppStrings.getString('bookNow', lang)} • ${widget.provider.name}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            
            // Content
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Provider info
                      _buildProviderInfo(),
                      const SizedBox(height: 16),
                      
                      // Service selection
                      _buildServiceSelection(lang),
                      const SizedBox(height: 16),
                      
                      // Date and time
                      _buildDateTimeSelection(lang),
                      const SizedBox(height: 16),
                      
                      // Address
                      _buildAddressField(savedAddresses, lang),
                      const SizedBox(height: 16),
                      
                      // Instructions
                      _buildInstructionsField(lang),
                      const SizedBox(height: 16),
                      
                      // Notes
                      _buildNotesField(lang),
                      const SizedBox(height: 16),
                      
                      // Cost estimate
                      _buildCostEstimate(lang),
                    ],
                  ),
                ),
              ),
            ),
            
            // Footer
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border(
                  top: BorderSide(color: Colors.grey.shade300),
                ),
              ),
              child: LayoutBuilder(
                builder: (context, constraints) {
                  final narrow = constraints.maxWidth < 420;
                  final buttons = [
                    OutlinedButton(
                      onPressed: _loading ? null : () => Navigator.of(context).pop(),
                      child: Text(AppStrings.getString('cancel', lang)),
                    ),
                    const SizedBox(width: 12, height: 12),
                    ElevatedButton(
                      onPressed: _loading ? null : _submitBooking,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(44),
                      ),
                      child: _loading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                              ),
                            )
                          : Text(AppStrings.getString('bookNow', lang)),
                    ),
                  ];
                  if (narrow) {
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        buttons[0],
                        const SizedBox(height: 12),
                        buttons[2],
                      ],
                    );
                  }
                  return Row(
                    children: [
                      Expanded(child: buttons[0]),
                      const SizedBox(width: 12),
                      Expanded(child: buttons[2]),
                    ],
                  );
                },
              ),
            ),
          ],
        ),
        ),
      ),
    );
  }

  String _formatAddress(Map<String, dynamic> a, String lang) {
    final parts = <String>[];
    final city = (a['city'] ?? '').toString();
    final street = (a['street'] ?? '').toString();
    final area = (a['area'] ?? '').toString();
    if (street.isNotEmpty) parts.add(AppStrings.getString(street, lang));
    if (area.isNotEmpty) parts.add(area);
    if (city.isNotEmpty) parts.add(AppStrings.getString(city, lang));
    return parts.join(', ');
  }

  Widget _buildProviderInfo() {
    return Container(
    padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Row(
        children: [
          CircleAvatar(
      radius: 24,
            backgroundColor: AppColors.primary,
            child: Text(
              widget.provider.name.substring(0, 1).toUpperCase(),
              style: TextStyle(
        fontSize: 16,
                fontWeight: FontWeight.bold,
                color: Colors.white,
              ),
            ),
          ),
      const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  widget.provider.name,
                  style: TextStyle(
          fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
        const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    final languageCode = Provider.of<LanguageService>(context, listen: false).currentLanguage;
                    final cityKey = widget.provider.city.toLowerCase();
                    final city = AppStrings.getString(cityKey, languageCode);
                    final years = widget.provider.experienceYears;
                    final yearsLabel = years == 1
                        ? AppStrings.getString('year', languageCode)
                        : AppStrings.getString('years', languageCode);
                    final expLabel = AppStrings.getString('experience', languageCode);
                    return Text(
                      '$city • $years $yearsLabel $expLabel',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey[600],
                      ),
                    );
                  },
                ),
        const SizedBox(height: 4),
                Builder(
                  builder: (context) {
                    final languageCode = Provider.of<LanguageService>(context, listen: false).currentLanguage;
                    final rate = widget.provider.hourlyRate.toStringAsFixed(0);
                    final per = AppStrings.getString('hourly', languageCode);
                    // For RTL, show label then amount; for LTR, amount then label
                    final isRtl = Directionality.of(context) == TextDirection.rtl;
                    final text = isRtl ? '$per /₪$rate' : '₪$rate/$per';
                    return Text(
                      text,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildServiceSelection(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('service', lang),
          style: TextStyle(
      fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
    const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: _selectedService,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          items: widget.provider.services
              .map((service) => DropdownMenuItem(
                    value: service,
          child: Text(AppStrings.getString(service, lang)),
                  ))
              .toList(),
          onChanged: (value) {
            setState(() {
              _selectedService = value;
            });
          },
          validator: (value) {
            if (value == null || value.isEmpty) {
        return AppStrings.getString('pleaseSelectService', lang);
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildDateTimeSelection(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
    AppStrings.getString('dateAndTime', lang),
          style: TextStyle(
      fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
    const SizedBox(height: 8),
    _DateTimeRow(
      dateLabel: _selectedDate != null
        ? _formatDate(_selectedDate!)
        : AppStrings.getString('selectDate', lang),
      onPickDate: _selectDate,
      startLabel: _startTime != null
        ? _formatTime(_startTime!)
        : AppStrings.getString('startTime', lang),
      endLabel: _endTime != null
        ? _formatTime(_endTime!)
        : AppStrings.getString('endTime', lang),
      onPickStart: () => _selectTime(true),
      onPickEnd: () => _selectTime(false),
    ),
      ],
    );
  }

  Widget _buildAddressField(List<Map<String, dynamic>> savedAddresses, String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('serviceAddress', lang),
          style: TextStyle(
      fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
    const SizedBox(height: 8),
        if (savedAddresses.isNotEmpty)
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ...savedAddresses.asMap().entries.map((entry) {
                final idx = entry.key;
                final a = entry.value;
                final id = idx.toString();
                final isDefault = a['isDefault'] == true;
                final labelKey = (a['type'] ?? 'home').toString();
                final label = AppStrings.getString(labelKey, lang);
                final subtitle = _formatAddress(a, lang);
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(8.0),
                    color: Colors.white,
                  ),
                  child: RadioListTile<String>(
                    value: id,
                    groupValue: _selectedAddressId,
                    onChanged: (v) {
                      setState(() {
                        _selectedAddressId = v;
                        _addressController.text = subtitle;
                      });
                    },
                    title: Row(
                      children: [
                        Text(label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
                        if (isDefault) ...[
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppColors.primary.withOpacity(0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(AppStrings.getString('defaultText', lang), style: const TextStyle(fontSize: 10, color: AppColors.primary)),
                          ),
                        ],
                      ],
                    ),
                    subtitle: Text(subtitle, style: TextStyle(fontSize: 12, color: Colors.grey[700])),
                  ),
                );
              }).toList(),
              const SizedBox(height: 8),
            ],
          ),
        TextFormField(
          controller: _addressController,
          decoration: InputDecoration(
            hintText: AppStrings.getString('enterYourAddress', lang),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          maxLines: 2,
          validator: (value) {
            if (value == null || value.isEmpty) {
              return AppStrings.getString('pleaseEnterAddress', lang);
            }
            return null;
          },
        ),
      ],
    );
  }

  Widget _buildInstructionsField(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('specialInstructions', lang),
          style: TextStyle(
      fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
    const SizedBox(height: 8),
        TextFormField(
          controller: _instructionsController,
          decoration: InputDecoration(
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          maxLines: 2,
        ),
        const SizedBox(height: 6),
        Text(
          AppStrings.getString('specialInstructionsHelp', lang),
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
        ),
      ],
    );
  }

  Widget _buildNotesField(String lang) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString('additionalNotesOptional', lang),
          style: TextStyle(
      fontSize: 15,
            fontWeight: FontWeight.w600,
          ),
        ),
    const SizedBox(height: 8),
        TextFormField(
          controller: _notesController,
          decoration: InputDecoration(
            hintText: AppStrings.getString('additionalNotesHint', lang),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8.0),
            ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
          ),
          maxLines: 3,
        ),
      ],
    );
  }

  Widget _buildCostEstimate(String lang) {
    final estimatedCost = _calculateEstimatedCost();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.primary.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: AppColors.primary.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            AppStrings.getString('estimatedCost', lang),
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
          Text(
            '₪${estimatedCost.toStringAsFixed(0)}',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: AppColors.primary,
            ),
          ),
        ],
      ),
    );
  }
}

// Internal compact-friendly row for date/time selectors
class _DateTimeRow extends StatelessWidget {
  final String dateLabel;
  final VoidCallback onPickDate;
  final String startLabel;
  final String endLabel;
  final VoidCallback onPickStart;
  final VoidCallback onPickEnd;

  const _DateTimeRow({
    required this.dateLabel,
    required this.onPickDate,
    required this.startLabel,
    required this.endLabel,
    required this.onPickStart,
    required this.onPickEnd,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final narrow = constraints.maxWidth < 420;
        final dateField = _ChipField(
          icon: Icons.calendar_today,
          label: dateLabel,
          onTap: onPickDate,
        );
        final startField = _ChipField(
          icon: Icons.access_time,
          label: startLabel,
          onTap: onPickStart,
        );
        final endField = _ChipField(
          icon: Icons.access_time,
          label: endLabel,
          onTap: onPickEnd,
        );

        if (narrow) {
          // Stack vertically for readability
          return Column(
            children: [
              dateField,
              const SizedBox(height: 8),
              startField,
              const SizedBox(height: 8),
              endField,
            ],
          );
        }

        return Column(
          children: [
            Row(children: [Expanded(child: dateField)]),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(child: startField),
                const SizedBox(width: 8),
                const Text(' - '),
                const SizedBox(width: 8),
                Expanded(child: endField),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _ChipField extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  const _ChipField({required this.icon, required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade400),
          borderRadius: BorderRadius.circular(8.0),
          color: Colors.white,
        ),
        child: Row(
          children: [
            Icon(icon, size: 22, color: Colors.grey.shade800),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 14),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
