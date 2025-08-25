# Time Translation System

This directory contains utilities for efficient time and date translations in the PalHands application.

## Overview

The time translation system provides a more efficient way to handle time-related translations compared to having individual strings for each time period. Instead of creating separate translations for "1 second ago", "2 seconds ago", "1 minute ago", etc., this system uses a dynamic approach.

## Files

- `time_translation_utils.dart` - Utility class with helper methods
- `time_translation_example_widget.dart` - Example widget demonstrating usage

## Usage

### 1. Basic Time Translation

```dart
// Instead of individual strings like "oneSecondAgo", "twoSecondsAgo", etc.
// Use the dynamic system:

String timeAgo = AppStrings.getTimeAgo(1, "second", languageCode);
// Returns: "1 second ago" (English) or "قبل ثانية" (Arabic)

String timeAgo = AppStrings.getTimeAgo(2, "minute", languageCode);
// Returns: "2 minutes ago" (English) or "قبل دقيقتين" (Arabic)
```

### 2. Month Translations

```dart
String monthName = AppStrings.getMonthName(3, languageCode);
// Returns: "March" (English) or "اذار" (Arabic)
```

### 3. Date Formatting

```dart
String formattedDate = TimeTranslationUtils.formatDate(15, 3, 1998, languageCode);
// Returns: "March 15, 1998" (English) or "15 اذار 1998" (Arabic)
```

### 4. Relative Time from DateTime

```dart
DateTime pastTime = DateTime.now().subtract(Duration(hours: 2));
String relativeTime = TimeTranslationUtils.getRelativeTime(pastTime, languageCode);
// Returns: "2 hours ago" (English) or "قبل ساعتين" (Arabic)
```

## Benefits

1. **Efficiency**: No need for individual strings for each time period
2. **Scalability**: Handles any number dynamically
3. **Consistency**: Proper pluralization for both languages
4. **Maintainability**: Easy to maintain and extend
5. **Flexibility**: Supports both English and Arabic formats
6. **Performance**: Reduces the number of translation strings needed

## Supported Time Units

- `second` / `seconds`
- `minute` / `minutes`
- `hour` / `hours`
- `day` / `days`
- `week` / `weeks`
- `month` / `months`
- `year` / `years`

## Language Support

- **English**: "1 hour ago", "2 hours ago"
- **Arabic**: "قبل ساعة", "قبل ساعتين"

## Migration from Static Strings

If you currently have static strings like:
```dart
case 'oneSecondAgo':
  return isArabic ? 'قبل ثانية' : '1 second ago';
case 'twoSecondsAgo':
  return isArabic ? 'قبل ثانيتين' : '2 seconds ago';
```

Replace them with:
```dart
// Use the dynamic system instead
String timeAgo = AppStrings.getTimeAgo(value, "second", languageCode);
```

## Example Implementation

See `time_translation_example_widget.dart` for a complete example of how to use the system in a Flutter widget. 