import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';

class ClientReviewsDialog extends StatefulWidget {
  final String clientId;
  final String clientName;
  final Future<List<Map<String, dynamic>>> reviewsFuture;

  const ClientReviewsDialog({
    Key? key,
    required this.clientId,
    required this.clientName,
    required this.reviewsFuture,
  }) : super(key: key);

  @override
  State<ClientReviewsDialog> createState() => _ClientReviewsDialogState();
}

class _ClientReviewsDialogState extends State<ClientReviewsDialog> {
  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16.0),
      ),
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        padding: const EdgeInsets.all(24.0),
        child: Column(
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
                    '${widget.clientName}\'s Reviews',
                    style: GoogleFonts.cairo(
                      fontSize: 24.0,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close),
                  color: AppColors.textSecondary,
                ),
              ],
            ),
            const SizedBox(height: 20.0),
            
            // Reviews List
            Expanded(
              child: FutureBuilder<List<Map<String, dynamic>>>(
                future: widget.reviewsFuture,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(
                      child: CircularProgressIndicator(),
                    );
                  }
                  
                  if (snapshot.hasError) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline,
                            size: 64.0,
                            color: AppColors.error,
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            'Failed to load reviews',
                            style: GoogleFonts.cairo(
                              fontSize: 18.0,
                              color: AppColors.error,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            snapshot.error.toString(),
                            style: GoogleFonts.cairo(
                              fontSize: 14.0,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  final reviews = snapshot.data ?? [];
                  
                  if (reviews.isEmpty) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.reviews_outlined,
                            size: 64.0,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(height: 16.0),
                          Text(
                            'No reviews yet',
                            style: GoogleFonts.cairo(
                              fontSize: 18.0,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 8.0),
                          Text(
                            'This client hasn\'t received any reviews yet.',
                            style: GoogleFonts.cairo(
                              fontSize: 14.0,
                              color: AppColors.textSecondary,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ],
                      ),
                    );
                  }
                  
                  return ListView.builder(
                    itemCount: reviews.length,
                    itemBuilder: (context, index) {
                      final review = reviews[index];
                      return _buildReviewCard(review);
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReviewCard(Map<String, dynamic> review) {
    final rating = (review['rating'] ?? 0.0).toDouble();
    final comment = review['comment']?.toString() ?? '';
    final providerName = review['providerName']?.toString() ?? 'Unknown Provider';
    final createdAt = review['createdAt']?.toString() ?? '';
    final bookingId = review['bookingId']?.toString() ?? '';
    
    // Parse date
    DateTime? date;
    try {
      date = DateTime.parse(createdAt);
    } catch (e) {
      date = null;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with rating and provider
          Row(
            children: [
              // Star rating
              Row(
                children: List.generate(5, (index) {
                  return Icon(
                    index < rating.floor() 
                        ? Icons.star 
                        : (index < rating ? Icons.star_half : Icons.star_border),
                    color: Colors.amber,
                    size: 20.0,
                  );
                }),
              ),
              const SizedBox(width: 8.0),
              Text(
                rating.toStringAsFixed(1),
                style: GoogleFonts.cairo(
                  fontSize: 16.0,
                  fontWeight: FontWeight.w600,
                  color: Colors.amber.shade700,
                ),
              ),
              const Spacer(),
              Text(
                providerName,
                style: GoogleFonts.cairo(
                  fontSize: 14.0,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          
          // Comment
          if (comment.isNotEmpty) ...[
            const SizedBox(height: 12.0),
            Text(
              comment,
              style: GoogleFonts.cairo(
                fontSize: 14.0,
                color: AppColors.textPrimary,
                height: 1.4,
              ),
            ),
          ],
          
          // Footer with date and booking ID
          const SizedBox(height: 12.0),
          Row(
            children: [
              if (date != null) ...[
                Icon(
                  Icons.access_time,
                  size: 14.0,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4.0),
                Text(
                  '${date.day}/${date.month}/${date.year}',
                  style: GoogleFonts.cairo(
                    fontSize: 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
              if (bookingId.isNotEmpty) ...[
                const SizedBox(width: 16.0),
                Icon(
                  Icons.receipt,
                  size: 14.0,
                  color: AppColors.textSecondary,
                ),
                const SizedBox(width: 4.0),
                Text(
                  'Booking: ${bookingId.substring(0, 8)}...',
                  style: GoogleFonts.cairo(
                    fontSize: 12.0,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
