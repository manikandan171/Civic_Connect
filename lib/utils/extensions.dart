import 'package:flutter/material.dart';

// String extensions
extension StringExtensions on String {
  /// Capitalizes the first letter of the string
  String capitalize() {
    if (isEmpty) return this;
    return '${this[0].toUpperCase()}${substring(1).toLowerCase()}';
  }

  /// Capitalizes the first letter of each word
  String capitalizeWords() {
    if (isEmpty) return this;
    return split(' ').map((word) => word.capitalize()).join(' ');
  }

  /// Checks if the string is a valid email
  bool isValidEmail() {
    return RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(this);
  }

  /// Checks if the string is a valid phone number
  bool isValidPhone() {
    return RegExp(r'^\+?[1-9]\d{1,14}$').hasMatch(this);
  }

  /// Truncates the string to a specified length and adds ellipsis
  String truncate(int maxLength) {
    if (length <= maxLength) return this;
    return '${substring(0, maxLength)}...';
  }

  /// Removes all whitespace from the string
  String removeWhitespace() {
    return replaceAll(RegExp(r'\s+'), '');
  }

  /// Converts the string to a slug format
  String toSlug() {
    return toLowerCase()
        .replaceAll(RegExp(r'[^a-z0-9\s-]'), '')
        .replaceAll(RegExp(r'\s+'), '-')
        .replaceAll(RegExp(r'-+'), '-')
        .trim();
  }
}

// DateTime extensions
extension DateTimeExtensions on DateTime {
  /// Returns a formatted date string
  String toFormattedDate() {
    return '${day.toString().padLeft(2, '0')}/${month.toString().padLeft(2, '0')}/$year';
  }

  /// Returns a formatted time string
  String toFormattedTime() {
    return '${hour.toString().padLeft(2, '0')}:${minute.toString().padLeft(2, '0')}';
  }

  /// Returns a formatted date and time string
  String toFormattedDateTime() {
    return '${toFormattedDate()} at ${toFormattedTime()}';
  }

  /// Returns a relative time string (e.g., "2 hours ago")
  String toRelativeTime() {
    final now = DateTime.now();
    final difference = now.difference(this);

    if (difference.inDays > 0) {
      return '${difference.inDays} day${difference.inDays > 1 ? 's' : ''} ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours} hour${difference.inHours > 1 ? 's' : ''} ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes} minute${difference.inMinutes > 1 ? 's' : ''} ago';
    } else {
      return 'Just now';
    }
  }

  /// Checks if the date is today
  bool isToday() {
    final now = DateTime.now();
    return year == now.year && month == now.month && day == now.day;
  }

  /// Checks if the date is yesterday
  bool isYesterday() {
    final yesterday = DateTime.now().subtract(const Duration(days: 1));
    return year == yesterday.year &&
        month == yesterday.month &&
        day == yesterday.day;
  }

  /// Returns the start of the day
  DateTime startOfDay() {
    return DateTime(year, month, day);
  }

  /// Returns the end of the day
  DateTime endOfDay() {
    return DateTime(year, month, day, 23, 59, 59, 999);
  }
}

// List extensions
extension ListExtensions<T> on List<T> {
  /// Safely gets an element at the specified index
  T? safeGet(int index) {
    if (index >= 0 && index < length) {
      return this[index];
    }
    return null;
  }

  /// Removes duplicates from the list
  List<T> removeDuplicates() {
    return toSet().toList();
  }

  /// Chunks the list into smaller lists of specified size
  List<List<T>> chunk(int size) {
    final chunks = <List<T>>[];
    for (int i = 0; i < length; i += size) {
      chunks.add(sublist(i, i + size > length ? length : i + size));
    }
    return chunks;
  }

  /// Checks if the list is not empty
  bool get isNotEmpty => length > 0;

  /// Gets the first element or null if empty
  T? get firstOrNull => isEmpty ? null : first;

  /// Gets the last element or null if empty
  T? get lastOrNull => isEmpty ? null : last;
}

// BuildContext extensions
extension BuildContextExtensions on BuildContext {
  /// Gets the screen size
  Size get screenSize => MediaQuery.of(this).size;

  /// Gets the screen width
  double get screenWidth => MediaQuery.of(this).size.width;

  /// Gets the screen height
  double get screenHeight => MediaQuery.of(this).size.height;

  /// Gets the safe area padding
  EdgeInsets get safeAreaPadding => MediaQuery.of(this).padding;

  /// Gets the theme
  ThemeData get theme => Theme.of(this);

  /// Gets the text theme
  TextTheme get textTheme => Theme.of(this).textTheme;

  /// Gets the color scheme
  ColorScheme get colorScheme => Theme.of(this).colorScheme;

  /// Shows a snackbar
  void showSnackBar(
    String message, {
    Color? backgroundColor,
    Duration? duration,
  }) {
    ScaffoldMessenger.of(this).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: backgroundColor,
        duration: duration ?? const Duration(seconds: 3),
      ),
    );
  }

  /// Shows an error snackbar
  void showErrorSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.red);
  }

  /// Shows a success snackbar
  void showSuccessSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.green);
  }

  /// Shows an info snackbar
  void showInfoSnackBar(String message) {
    showSnackBar(message, backgroundColor: Colors.blue);
  }

  /// Navigates to a new screen
  Future<T?> navigateTo<T>(Widget screen) {
    return Navigator.of(
      this,
    ).push<T>(MaterialPageRoute(builder: (context) => screen));
  }

  /// Replaces the current screen
  Future<T?> replaceWith<T>(Widget screen) {
    return Navigator.of(this).pushReplacement<T, dynamic>(
      MaterialPageRoute(builder: (context) => screen),
    );
  }

  /// Pops the current screen
  void pop<T>([T? result]) {
    Navigator.of(this).pop(result);
  }

  /// Checks if the current screen can be popped
  bool canPop() {
    return Navigator.of(this).canPop();
  }
}

// Color extensions
extension ColorExtensions on Color {
  /// Converts the color to a hex string
  String toHex() {
    return '#${toARGB32().toRadixString(16).substring(2).toUpperCase()}';
  }

  /// Creates a color from a hex string
  static Color fromHex(String hex) {
    final hexColor = hex.replaceAll('#', '');
    return Color(int.parse('FF$hexColor', radix: 16));
  }

  /// Returns a lighter version of the color
  Color lighten([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslLight = hsl.withLightness(
      (hsl.lightness + amount).clamp(0.0, 1.0),
    );
    return hslLight.toColor();
  }

  /// Returns a darker version of the color
  Color darken([double amount = 0.1]) {
    assert(amount >= 0 && amount <= 1);
    final hsl = HSLColor.fromColor(this);
    final hslDark = hsl.withLightness((hsl.lightness - amount).clamp(0.0, 1.0));
    return hslDark.toColor();
  }
}

// Widget extensions
extension WidgetExtensions on Widget {
  /// Adds padding to the widget
  Widget padding(EdgeInsets padding) {
    return Padding(padding: padding, child: this);
  }

  /// Adds margin to the widget
  Widget margin(EdgeInsets margin) {
    return Container(margin: margin, child: this);
  }

  /// Centers the widget
  Widget center() {
    return Center(child: this);
  }

  /// Wraps the widget in a container with decoration
  Widget container({
    Color? color,
    Decoration? decoration,
    double? width,
    double? height,
  }) {
    return Container(
      width: width,
      height: height,
      color: color,
      decoration: decoration,
      child: this,
    );
  }

  /// Makes the widget expandable
  Widget expand([int flex = 1]) {
    return Expanded(flex: flex, child: this);
  }

  /// Makes the widget flexible
  Widget flexible([int flex = 1]) {
    return Flexible(flex: flex, child: this);
  }
}
