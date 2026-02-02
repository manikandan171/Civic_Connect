class Validators {
  // Email validation
  static String? validateEmail(String? value) {
    if (value == null || value.isEmpty) {
      return 'Email is required';
    }
    
    final emailRegex = RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$');
    if (!emailRegex.hasMatch(value)) {
      return 'Please enter a valid email address';
    }
    
    return null;
  }

  // Phone number validation
  static String? validatePhone(String? value) {
    if (value == null || value.isEmpty) {
      return 'Phone number is required';
    }
    
    // Remove all non-digit characters
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length < 10) {
      return 'Phone number must be at least 10 digits';
    }
    
    if (digitsOnly.length > 15) {
      return 'Phone number must not exceed 15 digits';
    }
    
    return null;
  }

  // Password validation
  static String? validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Password is required';
    }
    
    if (value.length < 6) {
      return 'Password must be at least 6 characters';
    }
    
    if (value.length > 50) {
      return 'Password must not exceed 50 characters';
    }
    
    return null;
  }

  // Confirm password validation
  static String? validateConfirmPassword(String? value, String? password) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    
    if (value != password) {
      return 'Passwords do not match';
    }
    
    return null;
  }

  // Name validation
  static String? validateName(String? value) {
    if (value == null || value.isEmpty) {
      return 'Name is required';
    }
    
    if (value.length < 2) {
      return 'Name must be at least 2 characters';
    }
    
    if (value.length > 50) {
      return 'Name must not exceed 50 characters';
    }
    
    // Check for valid characters (letters, spaces, hyphens, apostrophes)
    final nameRegex = RegExp(r"^[a-zA-Z\s\-']+$");
    if (!nameRegex.hasMatch(value)) {
      return 'Name can only contain letters, spaces, hyphens, and apostrophes';
    }
    
    return null;
  }

  // Issue title validation
  static String? validateIssueTitle(String? value) {
    if (value == null || value.isEmpty) {
      return 'Issue title is required';
    }
    
    if (value.length < 5) {
      return 'Title must be at least 5 characters';
    }
    
    if (value.length > 100) {
      return 'Title must not exceed 100 characters';
    }
    
    return null;
  }

  // Issue description validation
  static String? validateIssueDescription(String? value) {
    if (value == null || value.isEmpty) {
      return 'Issue description is required';
    }
    
    if (value.length < 10) {
      return 'Description must be at least 10 characters';
    }
    
    if (value.length > 1000) {
      return 'Description must not exceed 1000 characters';
    }
    
    return null;
  }

  // Address validation
  static String? validateAddress(String? value) {
    if (value == null || value.isEmpty) {
      return 'Address is required';
    }
    
    if (value.length < 10) {
      return 'Please provide a more detailed address';
    }
    
    if (value.length > 200) {
      return 'Address must not exceed 200 characters';
    }
    
    return null;
  }

  // OTP validation
  static String? validateOTP(String? value) {
    if (value == null || value.isEmpty) {
      return 'OTP is required';
    }
    
    final digitsOnly = value.replaceAll(RegExp(r'\D'), '');
    
    if (digitsOnly.length != 6) {
      return 'OTP must be 6 digits';
    }
    
    return null;
  }

  // Required field validation
  static String? validateRequired(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    return null;
  }

  // Minimum length validation
  static String? validateMinLength(String? value, int minLength, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (value.length < minLength) {
      return '$fieldName must be at least $minLength characters';
    }
    
    return null;
  }

  // Maximum length validation
  static String? validateMaxLength(String? value, int maxLength, String fieldName) {
    if (value != null && value.length > maxLength) {
      return '$fieldName must not exceed $maxLength characters';
    }
    
    return null;
  }

  // URL validation
  static String? validateUrl(String? value) {
    if (value == null || value.isEmpty) {
      return null; // URL is optional
    }
    
    final urlRegex = RegExp(
      r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$'
    );
    
    if (!urlRegex.hasMatch(value)) {
      return 'Please enter a valid URL';
    }
    
    return null;
  }

  // Numeric validation
  static String? validateNumeric(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    if (double.tryParse(value) == null) {
      return '$fieldName must be a valid number';
    }
    
    return null;
  }

  // Positive number validation
  static String? validatePositiveNumber(String? value, String fieldName) {
    final numericError = validateNumeric(value, fieldName);
    if (numericError != null) return numericError;
    
    final number = double.parse(value!);
    if (number <= 0) {
      return '$fieldName must be greater than 0';
    }
    
    return null;
  }

  // Date validation
  static String? validateDate(String? value, String fieldName) {
    if (value == null || value.isEmpty) {
      return '$fieldName is required';
    }
    
    try {
      DateTime.parse(value);
      return null;
    } catch (e) {
      return 'Please enter a valid date';
    }
  }

  // Future date validation
  static String? validateFutureDate(String? value, String fieldName) {
    final dateError = validateDate(value, fieldName);
    if (dateError != null) return dateError;
    
    final date = DateTime.parse(value!);
    if (date.isBefore(DateTime.now())) {
      return '$fieldName must be in the future';
    }
    
    return null;
  }

  // Past date validation
  static String? validatePastDate(String? value, String fieldName) {
    final dateError = validateDate(value, fieldName);
    if (dateError != null) return dateError;
    
    final date = DateTime.parse(value!);
    if (date.isAfter(DateTime.now())) {
      return '$fieldName must be in the past';
    }
    
    return null;
  }

  // File size validation (in bytes)
  static String? validateFileSize(int fileSize, int maxSizeInMB) {
    final maxSizeInBytes = maxSizeInMB * 1024 * 1024;
    
    if (fileSize > maxSizeInBytes) {
      return 'File size must not exceed ${maxSizeInMB}MB';
    }
    
    return null;
  }

  // Image file validation
  static String? validateImageFile(String? filePath) {
    if (filePath == null || filePath.isEmpty) {
      return 'Image is required';
    }
    
    final allowedExtensions = ['.jpg', '.jpeg', '.png', '.gif', '.webp'];
    final extension = filePath.toLowerCase().split('.').last;
    
    if (!allowedExtensions.contains('.$extension')) {
      return 'Please select a valid image file (JPG, PNG, GIF, WebP)';
    }
    
    return null;
  }

  // Video file validation
  static String? validateVideoFile(String? filePath) {
    if (filePath == null || filePath.isEmpty) {
      return null; // Video is optional
    }
    
    final allowedExtensions = ['.mp4', '.mov', '.avi', '.mkv', '.webm'];
    final extension = filePath.toLowerCase().split('.').last;
    
    if (!allowedExtensions.contains('.$extension')) {
      return 'Please select a valid video file (MP4, MOV, AVI, MKV, WebM)';
    }
    
    return null;
  }

  // Combined validation for multiple fields
  static Map<String, String?> validateMultiple(Map<String, String?> values, Map<String, String? Function(String?)> validators) {
    final errors = <String, String?>{};
    
    for (final entry in validators.entries) {
      final fieldName = entry.key;
      final validator = entry.value;
      final value = values[fieldName];
      
      final error = validator(value);
      if (error != null) {
        errors[fieldName] = error;
      }
    }
    
    return errors;
  }
}
