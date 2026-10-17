library;

/// Extension for String to check if it's empty or whitespace
extension StringExtensions on String {
  /// Checks if the string is null, empty, or contains only whitespace
  bool get isBlank => trim().isEmpty;

  /// Checks if the string is not null, not empty, and contains non-whitespace characters
  bool get isNotBlank => !isBlank;
}

/// Extension for List to check if it's empty
extension ListExtensions<T> on List<T> {
  /// Checks if the list is empty
  bool get isNullOrEmpty => isEmpty;

  /// Checks if the list is not null and not empty
  bool get isNotNullOrEmpty => !isNullOrEmpty;
}

/// Extension for DateTime to format dates
extension DateTimeExtensions on DateTime {
  /// Formats the date as YYYY-MM-DD
  String toDateString() => '${year.toString().padLeft(4, '0')}-${month.toString().padLeft(2, '0')}-${day.toString().padLeft(2, '0')}';

  /// Formats the time as HH:MM
  String toTimeString() => '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
}

/// Extension for num to format numbers
extension NumExtensions on num {
  /// Formats the number with specified decimal places
  String toDecimal(int decimalPlaces) => toStringAsFixed(decimalPlaces);

  /// Formats the number as currency
  String toCurrency({String symbol = 'Rs.', int decimalPlaces = 2}) {
    return '$symbol ${toStringAsFixed(decimalPlaces)}';
  }
}
