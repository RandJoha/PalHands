import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../core/constants/app_colors.dart';
import '../services/booking_service.dart';
import '../services/auth_service.dart';

class ProviderRatingDialog extends StatefulWidget {
  final String bookingId;
  final String providerName;
  final String serviceName;
  final Function() onRatingSubmitted;

  const ProviderRatingDialog({
    Key? key,
    required this.bookingId,
    required this.providerName,
    required this.serviceName,
    required this.onRatingSubmitted,
  }) : super(key: key);

  @override
  State<ProviderRatingDialog> createState() => _ProviderRatingDialogState();
}

class _ProviderRatingDialogState extends State<ProviderRatingDialog> {
  double _rating = 0.0;
  final TextEditingController _commentController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _commentController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.45, // 50% smaller width
        padding: const EdgeInsets.all(12.0), // 50% smaller padding
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Icon(
                  Icons.star,
                  color: Colors.amber,
                  size: 28.0,
                ),
                const SizedBox(width: 12.0),
                Expanded(
                  child: Text(
                    'Rate Provider',
                    style: GoogleFonts.cairo(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 10.0),
            
            // Service and Provider Info
            Container(
              padding: const EdgeInsets.all(8.0),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(12.0),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Service: ${widget.serviceName}',
                    style: GoogleFonts.cairo(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8.0),
                  Text(
                    'Provider: ${widget.providerName}',
                    style: GoogleFonts.cairo(
                      fontSize: 16.0,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12.0),
            
            // Rating Section
            Text(
              'How would you rate this provider?',
              style: GoogleFonts.cairo(
                fontSize: 18.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8.0),
            
            // Star Rating
            Center(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: List.generate(5, (index) {
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _rating = (index + 1).toDouble();
                      });
                    },
                    child: Icon(
                      index < _rating ? Icons.star : Icons.star_border,
                      color: Colors.amber,
                      size: 30.0,
                    ),
                  );
                }),
              ),
            ),
            const SizedBox(height: 4.0),
            
            // Rating Text
            Center(
              child: Text(
                _rating > 0 ? '${_rating.toStringAsFixed(1)} stars' : 'Tap to rate',
                style: GoogleFonts.cairo(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w500,
                  color: _rating > 0 ? Colors.amber.shade700 : AppColors.textSecondary,
                ),
              ),
            ),
            const SizedBox(height: 12.0),
            
            // Comment Section
            Text(
              'Add a comment (optional)',
              style: GoogleFonts.cairo(
                fontSize: 16.0,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6.0),
            
            TextField(
              controller: _commentController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Share your experience with this provider...',
                hintStyle: GoogleFonts.cairo(
                  color: AppColors.textSecondary,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: AppColors.border),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12.0),
                  borderSide: BorderSide(color: AppColors.primary, width: 2.0),
                ),
                contentPadding: const EdgeInsets.all(16.0),
              ),
              style: GoogleFonts.cairo(
                fontSize: 14.0,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 12.0),
            
            // Action Buttons
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: _isSubmitting ? null : () => Navigator.of(context).pop(),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      side: BorderSide(color: AppColors.border),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.cairo(
                        fontSize: 16.0,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16.0),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _rating > 0 && !_isSubmitting ? _submitRating : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12.0),
                      ),
                    ),
                    child: _isSubmitting
                        ? const SizedBox(
                            height: 20.0,
                            width: 20.0,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.0,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Text(
                            'Submit Rating',
                            style: GoogleFonts.cairo(
                              fontSize: 16.0,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRating() async {
    if (_rating <= 0) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      // Get the services from provider context
      final bookingService = BookingService();
      final authService = Provider.of<AuthService>(context, listen: false);
      
      print('🔍 Rating submission debug:');
      print('  - Booking ID: ${widget.bookingId}');
      print('  - Rating: $_rating');
      print('  - Comment: ${_commentController.text.trim()}');
      print('  - Auth token exists: ${authService.token != null}');
      
      await bookingService.rateProvider(
        widget.bookingId,
        rating: _rating,
        comment: _commentController.text.trim().isEmpty ? null : _commentController.text.trim(),
        authService: authService,
      );

      if (mounted) {
        Navigator.of(context).pop();
        widget.onRatingSubmitted();
        
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Rating submitted successfully!',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppColors.success,
          ),
        );
      }
    } catch (e) {
      print('❌ Rating submission error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Failed to submit rating: ${e.toString()}',
              style: GoogleFonts.cairo(),
            ),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSubmitting = false;
        });
      }
    }
  }
}
