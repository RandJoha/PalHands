class FAQItem {
  final String questionKey;
  final String answerKey;
  final String categoryKey;
  final String icon;

  const FAQItem({
    required this.questionKey,
    required this.answerKey,
    required this.categoryKey,
    required this.icon,
  });
}

class FAQCategory {
  final String titleKey;
  final String icon;
  final List<FAQItem> items;

  const FAQCategory({
    required this.titleKey,
    required this.icon,
    required this.items,
  });
}

class FAQData {
  static const List<FAQCategory> categories = [
    FAQCategory(
      titleKey: 'faqGeneralQuestions',
      icon: '🧩',
      items: [
        FAQItem(
          questionKey: 'faqWhatIsPalHands',
          answerKey: 'faqWhatIsPalHandsAnswer',
          categoryKey: 'faqGeneralQuestions',
          icon: '🏠',
        ),
        FAQItem(
          questionKey: 'faqWhoAreProviders',
          answerKey: 'faqWhoAreProvidersAnswer',
          categoryKey: 'faqGeneralQuestions',
          icon: '👥',
        ),
        FAQItem(
          questionKey: 'faqHowDifferent',
          answerKey: 'faqHowDifferentAnswer',
          categoryKey: 'faqGeneralQuestions',
          icon: '⭐',
        ),
      ],
    ),
    FAQCategory(
      titleKey: 'faqBookingApp',
      icon: '🧾',
      items: [
        FAQItem(
          questionKey: 'faqHowToBook',
          answerKey: 'faqHowToBookAnswer',
          categoryKey: 'faqBookingApp',
          icon: '📱',
        ),
        FAQItem(
          questionKey: 'faqScheduleAdvance',
          answerKey: 'faqScheduleAdvanceAnswer',
          categoryKey: 'faqBookingApp',
          icon: '📅',
        ),
        FAQItem(
          questionKey: 'faqCancelReschedule',
          answerKey: 'faqCancelRescheduleAnswer',
          categoryKey: 'faqBookingApp',
          icon: '🔄',
        ),
      ],
    ),
    FAQCategory(
      titleKey: 'faqPayments',
      icon: '💳',
      items: [
        FAQItem(
          questionKey: 'faqHowToPay',
          answerKey: 'faqHowToPayAnswer',
          categoryKey: 'faqPayments',
          icon: '💰',
        ),
        FAQItem(
          questionKey: 'faqOnlinePayment',
          answerKey: 'faqOnlinePaymentAnswer',
          categoryKey: 'faqPayments',
          icon: '💻',
        ),
        FAQItem(
          questionKey: 'faqHiddenFees',
          answerKey: 'faqHiddenFeesAnswer',
          categoryKey: 'faqPayments',
          icon: '🔍',
        ),
      ],
    ),
    FAQCategory(
      titleKey: 'faqTrustSafety',
      icon: '✅',
      items: [
        FAQItem(
          questionKey: 'faqProvidersVerified',
          answerKey: 'faqProvidersVerifiedAnswer',
          categoryKey: 'faqTrustSafety',
          icon: '🛡️',
        ),
        FAQItem(
          questionKey: 'faqNotSatisfied',
          answerKey: 'faqNotSatisfiedAnswer',
          categoryKey: 'faqTrustSafety',
          icon: '😊',
        ),
        FAQItem(
          questionKey: 'faqPrivacy',
          answerKey: 'faqPrivacyAnswer',
          categoryKey: 'faqTrustSafety',
          icon: '🔒',
        ),
      ],
    ),
    FAQCategory(
      titleKey: 'faqServiceProviders',
      icon: '🛠️',
      items: [
        FAQItem(
          questionKey: 'faqSignUpProvider',
          answerKey: 'faqSignUpProviderAnswer',
          categoryKey: 'faqServiceProviders',
          icon: '📝',
        ),
        FAQItem(
          questionKey: 'faqMultipleServices',
          answerKey: 'faqMultipleServicesAnswer',
          categoryKey: 'faqServiceProviders',
          icon: '📋',
        ),
      ],
    ),
    FAQCategory(
      titleKey: 'faqLocalization',
      icon: '🌍',
      items: [
        FAQItem(
          questionKey: 'faqLanguagesAvailable',
          answerKey: 'faqLanguagesAvailableAnswer',
          categoryKey: 'faqLocalization',
          icon: '🌐',
        ),
        FAQItem(
          questionKey: 'faqCitiesServed',
          answerKey: 'faqCitiesServedAnswer',
          categoryKey: 'faqLocalization',
          icon: '🏙️',
        ),
      ],
    ),
  ];

  static List<FAQItem> getAllFAQItems() {
    List<FAQItem> allItems = [];
    for (var category in categories) {
      allItems.addAll(category.items);
    }
    return allItems;
  }

  static List<FAQItem> searchFAQItems(String query, String language) {
    if (query.isEmpty) return getAllFAQItems();
    
    return getAllFAQItems().where((item) {
      // This will be implemented with actual string lookup
      // For now, we'll return all items and filter in the UI
      return true;
    }).toList();
  }
} 