/// Currency formatting utility for Candela App
/// Supports both English ("D.L") and Arabic ("د.ل") symbols
class CurrencyFormatter {
  static const String symbolEn = 'D.L';
  static const String symbolAr = 'د.ل';

  /// Format double or num amount to "X.XX D.L" or "X.XX د.ل"
  static String format(double amount, {bool isArabic = false, int decimals = 2}) {
    final formattedAmount = amount.toStringAsFixed(decimals);
    return isArabic
        ? '$formattedAmount $symbolAr'
        : '$formattedAmount $symbolEn';
  }

  /// Format original price vs discounted price string
  static String formatDiscount(double original, double discounted, {bool isArabic = false}) {
    final origFormatted = format(original, isArabic: isArabic);
    final discFormatted = format(discounted, isArabic: isArabic);
    return '$discFormatted ($origFormatted)';
  }
}
