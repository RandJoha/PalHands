import 'dart:io';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import '../services/image_upload_service.dart';
import '../../core/constants/app_colors.dart';

class ImageUploadWidget extends StatefulWidget {
  final String serviceId;
  final Function(List<String>) onImagesUploaded;
  final int maxImages;
  final double maxFileSize;

  const ImageUploadWidget({
    Key? key,
    required this.serviceId,
    required this.onImagesUploaded,
    this.maxImages = 10,
    this.maxFileSize = 5 * 1024 * 1024, // 5MB
  }) : super(key: key);

  @override
  State<ImageUploadWidget> createState() => _ImageUploadWidgetState();
}

class _ImageUploadWidgetState extends State<ImageUploadWidget> {
  final ImageUploadService _uploadService = ImageUploadService();
  final ImagePicker _picker = ImagePicker();
  
  List<File> _selectedImages = [];
  List<ImageUploadResult> _uploadResults = [];
  bool _isUploading = false;
  double _uploadProgress = 0.0;
  String? _errorMessage;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          children: [
            Icon(Icons.image, color: AppColors.primary, size: 20),
            const SizedBox(width: 8),
            Text(
              'Service Images',
              style: GoogleFonts.cairo(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.greyDark,
              ),
            ),
            const Spacer(),
            if (_selectedImages.isNotEmpty && !_isUploading)
              TextButton(
                onPressed: _uploadImages,
                child: Text(
                  'Upload ${_selectedImages.length} images',
                  style: GoogleFonts.cairo(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),

        // Image selection area
        if (!_isUploading) _buildImageSelectionArea(),

        // Upload progress
        if (_isUploading) _buildUploadProgress(),

        // Upload results
        if (_uploadResults.isNotEmpty) _buildUploadResults(),

        // Error message
        if (_errorMessage != null) _buildErrorMessage(),
      ],
    );
  }

  Widget _buildImageSelectionArea() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.grey.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          // Selected images grid
          if (_selectedImages.isNotEmpty) ...[
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 3,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
                childAspectRatio: 1,
              ),
              itemCount: _selectedImages.length,
              itemBuilder: (context, index) {
                return _buildImageThumbnail(_selectedImages[index], index);
              },
            ),
            const SizedBox(height: 16),
          ],

          // Add images button
          if (_selectedImages.length < widget.maxImages)
            InkWell(
              onTap: _selectImages,
              child: Container(
                height: 100,
                decoration: BoxDecoration(
                  border: Border.all(
                    color: AppColors.grey.withValues(alpha: 0.3),
                    style: BorderStyle.solid,
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.add_photo_alternate,
                      color: AppColors.grey,
                      size: 32,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Add Images',
                      style: GoogleFonts.cairo(
                        fontSize: 12,
                        color: AppColors.grey,
                      ),
                    ),
                    Text(
                      '${_selectedImages.length}/${widget.maxImages}',
                      style: GoogleFonts.cairo(
                        fontSize: 10,
                        color: AppColors.grey.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildImageThumbnail(File imageFile, int index) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.grey.withValues(alpha: 0.3)),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.file(
              imageFile,
              fit: BoxFit.cover,
              width: double.infinity,
              height: double.infinity,
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: () => _removeImage(index),
            child: Container(
              padding: const EdgeInsets.all(4),
              decoration: BoxDecoration(
                color: AppColors.error,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.close,
                color: Colors.white,
                size: 12,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUploadProgress() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.primary.withValues(alpha: 0.05),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Uploading images...',
                  style: GoogleFonts.cairo(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: AppColors.primary,
                  ),
                ),
              ),
              TextButton(
                onPressed: _cancelUpload,
                child: Text(
                  'Cancel',
                  style: GoogleFonts.cairo(
                    color: AppColors.error,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: _uploadProgress,
            backgroundColor: AppColors.grey.withValues(alpha: 0.3),
            valueColor: AlwaysStoppedAnimation<Color>(AppColors.primary),
          ),
          const SizedBox(height: 4),
          Text(
            '${(_uploadProgress * 100).toInt()}%',
            style: GoogleFonts.cairo(
              fontSize: 12,
              color: AppColors.grey,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUploadResults() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16),
        Text(
          'Upload Results',
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: AppColors.greyDark,
          ),
        ),
        const SizedBox(height: 8),
        ..._uploadResults.asMap().entries.map((entry) {
          final index = entry.key;
          final result = entry.value;
          return _buildUploadResultItem(result, index);
        }).toList(),
      ],
    );
  }

  Widget _buildUploadResultItem(ImageUploadResult result, int index) {
    final isSuccess = result.success;
    final icon = isSuccess ? Icons.check_circle : Icons.error;
    final color = isSuccess ? AppColors.success : AppColors.error;
    final text = isSuccess ? 'Uploaded successfully' : result.error ?? 'Upload failed';

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: color.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: color.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: color,
              ),
            ),
          ),
          if (!isSuccess)
            TextButton(
              onPressed: () => _retryUpload(index),
              child: Text(
                'Retry',
                style: GoogleFonts.cairo(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildErrorMessage() {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: AppColors.error.withValues(alpha: 0.3)),
        borderRadius: BorderRadius.circular(8),
        color: AppColors.error.withValues(alpha: 0.05),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline, color: AppColors.error, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              _errorMessage!,
              style: GoogleFonts.cairo(
                fontSize: 14,
                color: AppColors.error,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _selectImages() async {
    try {
      final List<XFile> images = await _picker.pickMultiImage(
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );

      if (images.isNotEmpty) {
        final remainingSlots = widget.maxImages - _selectedImages.length;
        final imagesToAdd = images.take(remainingSlots).map((xfile) => File(xfile.path)).toList();

        setState(() {
          _selectedImages.addAll(imagesToAdd);
          _errorMessage = null;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Failed to select images: $e';
      });
    }
  }

  void _removeImage(int index) {
    setState(() {
      _selectedImages.removeAt(index);
    });
  }

  Future<void> _uploadImages() async {
    if (_selectedImages.isEmpty) return;

    setState(() {
      _isUploading = true;
      _uploadProgress = 0.0;
      _errorMessage = null;
    });

    try {
      final results = await _uploadService.uploadImages(
        serviceId: widget.serviceId,
        imageFiles: _selectedImages,
        onProgress: (progress) {
          setState(() {
            _uploadProgress = progress / 100;
          });
        },
      );

      setState(() {
        _uploadResults = results;
        _isUploading = false;
      });

      // Call callback with successful uploads
      final successfulUrls = results
          .where((result) => result.success && result.url != null)
          .map((result) => result.url!)
          .toList();

      if (successfulUrls.isNotEmpty) {
        widget.onImagesUploaded(successfulUrls);
      }

      // Clear selected images after upload
      setState(() {
        _selectedImages.clear();
      });
    } catch (e) {
      setState(() {
        _isUploading = false;
        _errorMessage = 'Upload failed: $e';
      });
    }
  }

  void _cancelUpload() {
    // Note: This is a simplified cancel. In a real implementation,
    // you'd want to cancel the actual HTTP requests
    setState(() {
      _isUploading = false;
      _uploadProgress = 0.0;
    });
  }

  Future<void> _retryUpload(int index) async {
    if (index >= _selectedImages.length) return;

    setState(() {
      _uploadResults[index] = ImageUploadResult(
        success: false,
        error: 'Retrying...',
      );
    });

    try {
      final result = await _uploadService.uploadImage(
        serviceId: widget.serviceId,
        imageFile: _selectedImages[index],
        onProgress: (progress) {
          // Progress for single file retry
        },
      );

      setState(() {
        _uploadResults[index] = result;
      });

      if (result.success && result.url != null) {
        widget.onImagesUploaded([result.url!]);
      }
    } catch (e) {
      setState(() {
        _uploadResults[index] = ImageUploadResult(
          success: false,
          error: 'Retry failed: $e',
        );
      });
    }
  }
}
