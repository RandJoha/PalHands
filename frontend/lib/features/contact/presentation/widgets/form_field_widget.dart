import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';
import '../../data/contact_data.dart';

class FormFieldWidget extends StatefulWidget {
  final ContactFormField field;
  final TextEditingController? controller;
  final String? selectedValue;
  final Function(String?)? onDropdownChanged;
  final Function(File?)? onFileSelected;

  const FormFieldWidget({
    super.key,
    required this.field,
    this.controller,
    this.selectedValue,
    this.onDropdownChanged,
    this.onFileSelected,
  });

  @override
  State<FormFieldWidget> createState() => _FormFieldWidgetState();
}

class _FormFieldWidgetState extends State<FormFieldWidget> {
  File? _selectedFile;
  final ImagePicker _picker = ImagePicker();

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        switch (widget.field.type) {
          case FieldType.text:
            return _buildTextField(languageService, TextInputType.text);
          case FieldType.email:
            return _buildTextField(languageService, TextInputType.emailAddress);
          case FieldType.textarea:
            return _buildTextArea(languageService);
          case FieldType.dropdown:
            return _buildDropdown(languageService);
          case FieldType.file:
            return _buildFileField(languageService);
          case FieldType.checkbox:
            return const SizedBox.shrink(); // Handled separately in form
        }
      },
    );
  }

  Future<void> _pickFile() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1920,
        maxHeight: 1080,
        imageQuality: 85,
      );
      
      if (image != null) {
        setState(() {
          _selectedFile = File(image.path);
        });
        
        if (widget.onFileSelected != null) {
          widget.onFileSelected!(_selectedFile);
        }
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Error picking file: $e',
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildTextField(LanguageService languageService, TextInputType inputType) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString(widget.field.labelKey, languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (widget.field.required)
          Text(
            ' *',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          keyboardType: inputType,
          decoration: InputDecoration(
            hintText: AppStrings.getString(widget.field.hintKey, languageService.currentLanguage),
            hintStyle: GoogleFonts.cairo(
              color: Colors.grey[500],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: GoogleFonts.cairo(),
          validator: widget.field.required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  if (widget.field.type == FieldType.email) {
                    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value)) {
                      return 'Please enter a valid email address';
                    }
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildTextArea(LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString(widget.field.labelKey, languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (widget.field.required)
          Text(
            ' *',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          maxLines: 4,
          decoration: InputDecoration(
            hintText: AppStrings.getString(widget.field.hintKey, languageService.currentLanguage),
            hintStyle: GoogleFonts.cairo(
              color: Colors.grey[500],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          style: GoogleFonts.cairo(),
          validator: widget.field.required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildDropdown(LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString(widget.field.labelKey, languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        if (widget.field.required)
          Text(
            ' *',
            style: GoogleFonts.cairo(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.red,
            ),
          ),
        const SizedBox(height: 8),
        DropdownButtonFormField<String>(
          value: widget.selectedValue,
          decoration: InputDecoration(
            hintText: AppStrings.getString(widget.field.hintKey, languageService.currentLanguage),
            hintStyle: GoogleFonts.cairo(
              color: Colors.grey[500],
            ),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: AppColors.primary.withValues(alpha: 0.3)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: AppColors.primary, width: 2),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          ),
          items: widget.field.options?.map((option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                AppStrings.getString(option, languageService.currentLanguage),
                style: GoogleFonts.cairo(),
              ),
            );
          }).toList() ?? [],
          onChanged: widget.onDropdownChanged,
          validator: widget.field.required
              ? (value) {
                  if (value == null || value.isEmpty) {
                    return 'This field is required';
                  }
                  return null;
                }
              : null,
        ),
      ],
    );
  }

  Widget _buildFileField(LanguageService languageService) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppStrings.getString(widget.field.labelKey, languageService.currentLanguage),
          style: GoogleFonts.cairo(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            border: Border.all(
              color: _selectedFile != null 
                ? AppColors.primary 
                : Colors.red.withValues(alpha: 0.3),
              width: 1,
            ),
            borderRadius: BorderRadius.circular(8),
            color: Colors.white,
          ),
          child: Row(
            children: [
              const Icon(
                Icons.attach_file,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _selectedFile != null
                    ? Text(
                        _selectedFile!.path.split('/').last,
                        style: GoogleFonts.cairo(
                          color: Colors.black87,
                          fontSize: 14,
                        ),
                        overflow: TextOverflow.ellipsis,
                      )
                    : Text(
                        AppStrings.getString(widget.field.hintKey, languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          color: Colors.grey[500],
                          fontSize: 14,
                        ),
                      ),
              ),
              TextButton(
                onPressed: _pickFile,
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Choose File',
                  style: GoogleFonts.cairo(
                    color: AppColors.primary,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (_selectedFile != null) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              const Icon(
                Icons.check_circle,
                color: Colors.green,
                size: 16,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'File selected: ${_selectedFile!.path.split('/').last}',
                  style: GoogleFonts.cairo(
                    color: Colors.green,
                    fontSize: 12,
                  ),
                ),
              ),
              TextButton(
                onPressed: () {
                  setState(() {
                    _selectedFile = null;
                  });
                  if (widget.onFileSelected != null) {
                    widget.onFileSelected!(null);
                  }
                },
                style: TextButton.styleFrom(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  minimumSize: Size.zero,
                  tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                ),
                child: Text(
                  'Remove',
                  style: GoogleFonts.cairo(
                    color: Colors.red,
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
} 