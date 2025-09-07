import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'dart:io';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/services/language_service.dart';
import '../../data/contact_data.dart';
import 'form_field_widget.dart';

class ContactForm extends StatefulWidget {
  final ContactPurpose purpose;
  final bool consentChecked;
  final Function(bool?) onConsentChanged;
  final Function(Map<String, dynamic>) onSubmit;

  const ContactForm({
    super.key,
    required this.purpose,
    required this.consentChecked,
    required this.onConsentChanged,
    required this.onSubmit,
  });

  @override
  State<ContactForm> createState() => _ContactFormState();
}

class _ContactFormState extends State<ContactForm> {
  final _formKey = GlobalKey<FormState>();
  final Map<String, TextEditingController> _controllers = {};
  final Map<String, File?> _selectedFiles = {};
  String? _selectedDropdownValue;

  @override
  void initState() {
    super.initState();
    _initializeControllers();
  }

  void _initializeControllers() {
    final purposeData = ContactData.getContactPurposeData(widget.purpose);
    if (purposeData != null) {
      for (final field in purposeData.formFields) {
        if (field.type != FieldType.checkbox && field.type != FieldType.dropdown) {
          _controllers[field.labelKey] = TextEditingController();
        }
      }
    }
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  void _onFileSelected(String fieldKey, File? file) {
    setState(() {
      _selectedFiles[fieldKey] = file;
    });
  }

  void _submitForm() {
    if (_formKey.currentState!.validate() && widget.consentChecked) {
      final formData = <String, dynamic>{
        'purpose': widget.purpose.toString(),
      };

      // Add form field values
      for (final entry in _controllers.entries) {
        formData[entry.key] = entry.value.text;
      }

      // Add dropdown value (if any dropdown fields exist)
      if (_selectedDropdownValue != null) {
        // Handle any remaining dropdown fields if needed
      }

      // Add selected files
      for (final entry in _selectedFiles.entries) {
        if (entry.value != null) {
          formData[entry.key] = entry.value!.path;
        }
      }

      // Add consent
      formData['consent'] = widget.consentChecked;

      widget.onSubmit(formData);
    } else if (!widget.consentChecked) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            AppStrings.getString('consentCheckbox', context.read<LanguageService>().currentLanguage),
            style: GoogleFonts.cairo(),
          ),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<LanguageService>(
      builder: (context, languageService, child) {
        final purposeData = ContactData.getContactPurposeData(widget.purpose);
        
        if (purposeData == null) {
          return const SizedBox.shrink();
        }

        return Container(
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Form(
            key: _formKey,
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Form title
                  Text(
                    AppStrings.getString(purposeData.titleKey, languageService.currentLanguage),
                    style: GoogleFonts.cairo(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.primary,
                    ),
                  ),
                  const SizedBox(height: 24),
                  
                  // Form fields
                  ...purposeData.formFields.map((field) {
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 20),
                      child: FormFieldWidget(
                        field: field,
                        controller: _controllers[field.labelKey],
                        selectedValue: _selectedDropdownValue,
                        onDropdownChanged: (value) {
                          setState(() {
                            _selectedDropdownValue = value;
                          });
                        },
                        onFileSelected: field.type == FieldType.file 
                          ? (file) => _onFileSelected(field.labelKey, file)
                          : null,
                      ),
                    );
                  }),
                  
                  // Consent checkbox
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: widget.consentChecked,
                        onChanged: widget.onConsentChanged,
                        activeColor: AppColors.primary,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          AppStrings.getString('consentCheckbox', languageService.currentLanguage),
                          style: GoogleFonts.cairo(
                            fontSize: 14,
                            color: Colors.black87,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                  
                  // Submit button
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _submitForm,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        elevation: 2,
                      ),
                      child: Text(
                        AppStrings.getString('submitForm', languageService.currentLanguage),
                        style: GoogleFonts.cairo(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
} 