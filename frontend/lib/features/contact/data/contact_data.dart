import 'package:flutter/material.dart';

enum ContactPurpose {
  reportServiceProvider,
  suggestFeature,
  requestServiceCategory,
  technicalProblem,
  businessInquiry,
  other,
}

class ContactPurposeData {
  final ContactPurpose purpose;
  final String titleKey;
  final String descriptionKey;
  final IconData icon;
  final List<ContactFormField> formFields;

  const ContactPurposeData({
    required this.purpose,
    required this.titleKey,
    required this.descriptionKey,
    required this.icon,
    required this.formFields,
  });
}

class ContactFormField {
  final String labelKey;
  final String hintKey;
  final FieldType type;
  final bool required;
  final List<String>? options; // For dropdown fields

  const ContactFormField({
    required this.labelKey,
    required this.hintKey,
    required this.type,
    this.required = false,
    this.options,
  });
}

enum FieldType {
  text,
  email,
  textarea,
  dropdown,
  checkbox,
  file,
}

class ContactData {
  static List<ContactPurposeData> getAllContactPurposes() {
    return [
      ContactPurposeData(
        purpose: ContactPurpose.reportServiceProvider,
        titleKey: 'reportServiceProvider',
        descriptionKey: 'reportServiceProvider',
        icon: Icons.report_problem,
        formFields: [
          const ContactFormField(
            labelKey: 'serviceName',
            hintKey: 'serviceName',
            type: FieldType.text,
            required: true,
          ),
          const ContactFormField(
            labelKey: 'whatWentWrong',
            hintKey: 'whatWentWrong',
            type: FieldType.textarea,
            required: true,
          ),
          const ContactFormField(
            labelKey: 'issueType',
            hintKey: 'issueType',
            type: FieldType.dropdown,
            required: true,
            options: ['unsafe', 'misleading', 'otherIssue'],
          ),
          const ContactFormField(
            labelKey: 'attachScreenshot',
            hintKey: 'attachScreenshot',
            type: FieldType.file,
            required: false,
          ),
          const ContactFormField(
            labelKey: 'yourName',
            hintKey: 'yourName',
            type: FieldType.text,
            required: true,
          ),
          const ContactFormField(
            labelKey: 'contactEmail',
            hintKey: 'contactEmail',
            type: FieldType.email,
            required: true,
          ),
        ],
      ),
      ContactPurposeData(
        purpose: ContactPurpose.suggestFeature,
        titleKey: 'suggestFeature',
        descriptionKey: 'suggestFeature',
        icon: Icons.lightbulb,
        formFields: [
          const ContactFormField(
            labelKey: 'ideaTitle',
            hintKey: 'ideaTitle',
            type: FieldType.text,
            required: true,
          ),
          const ContactFormField(
            labelKey: 'ideaDescription',
            hintKey: 'ideaDescription',
            type: FieldType.textarea,
            required: true,
          ),
          const ContactFormField(
            labelKey: 'howItHelpsCommunity',
            hintKey: 'howItHelpsCommunity',
            type: FieldType.textarea,
            required: true,
          ),
          const ContactFormField(
            labelKey: 'yourName',
            hintKey: 'yourName',
            type: FieldType.text,
            required: true,
          ),
          const ContactFormField(
            labelKey: 'contactEmail',
            hintKey: 'contactEmail',
            type: FieldType.email,
            required: true,
          ),
        ],
      ),
      ContactPurposeData(
        purpose: ContactPurpose.requestServiceCategory,
        titleKey: 'requestServiceCategory',
        descriptionKey: 'requestServiceCategory',
        icon: Icons.add_business,
        formFields: [
          const ContactFormField(
            labelKey: 'newServiceName',
            hintKey: 'newServiceName',
            type: FieldType.text,
            required: true,
          ),
          const ContactFormField(
            labelKey: 'whichCategory',
            hintKey: 'whichCategory',
            type: FieldType.text,
            required: true,
          ),
          const ContactFormField(
            labelKey: 'whyImportant',
            hintKey: 'whyImportant',
            type: FieldType.textarea,
            required: true,
          ),
          const ContactFormField(
            labelKey: 'yourName',
            hintKey: 'yourName',
            type: FieldType.text,
            required: true,
          ),
          const ContactFormField(
            labelKey: 'contactEmail',
            hintKey: 'contactEmail',
            type: FieldType.email,
            required: true,
          ),
        ],
      ),
      ContactPurposeData(
        purpose: ContactPurpose.technicalProblem,
        titleKey: 'technicalProblem',
        descriptionKey: 'technicalProblem',
        icon: Icons.bug_report,
        formFields: [
          const ContactFormField(
            labelKey: 'problemDescription',
            hintKey: 'problemDescription',
            type: FieldType.textarea,
            required: true,
          ),
          const ContactFormField(
            labelKey: 'attachScreenshot',
            hintKey: 'attachScreenshot',
            type: FieldType.file,
            required: false,
          ),
          const ContactFormField(
            labelKey: 'yourName',
            hintKey: 'yourName',
            type: FieldType.text,
            required: true,
          ),
          const ContactFormField(
            labelKey: 'contactEmail',
            hintKey: 'contactEmail',
            type: FieldType.email,
            required: true,
          ),
        ],
      ),
      ContactPurposeData(
        purpose: ContactPurpose.businessInquiry,
        titleKey: 'businessInquiry',
        descriptionKey: 'businessInquiry',
        icon: Icons.business,
        formFields: [
          const ContactFormField(
            labelKey: 'businessInquiryDetails',
            hintKey: 'businessInquiryDetails',
            type: FieldType.textarea,
            required: true,
          ),
          const ContactFormField(
            labelKey: 'yourName',
            hintKey: 'yourName',
            type: FieldType.text,
            required: true,
          ),
          const ContactFormField(
            labelKey: 'contactEmail',
            hintKey: 'contactEmail',
            type: FieldType.email,
            required: true,
          ),
        ],
      ),
      ContactPurposeData(
        purpose: ContactPurpose.other,
        titleKey: 'otherInquiry',
        descriptionKey: 'otherInquiry',
        icon: Icons.help,
        formFields: [
          const ContactFormField(
            labelKey: 'otherDetails',
            hintKey: 'otherDetails',
            type: FieldType.textarea,
            required: true,
          ),
          const ContactFormField(
            labelKey: 'yourName',
            hintKey: 'yourName',
            type: FieldType.text,
            required: true,
          ),
          const ContactFormField(
            labelKey: 'contactEmail',
            hintKey: 'contactEmail',
            type: FieldType.email,
            required: true,
          ),
        ],
      ),
    ];
  }

  static ContactPurposeData? getContactPurposeData(ContactPurpose purpose) {
    return getAllContactPurposes().firstWhere(
      (data) => data.purpose == purpose,
      orElse: () => throw Exception('Contact purpose not found'),
    );
  }
} 