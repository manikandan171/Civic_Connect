class AppConstants {
  // App Information
  static const String appName = 'Civic Connect';
  static const String appVersion = '1.0.0';
  static const String appTagline = 'Your Voice, Our Action';
  
  // Colors - Jharkhand inspired theme
  static const int primaryColorValue = 0xFF2E7D32; // Forest Green
  static const int secondaryColorValue = 0xFFFF6F00; // Orange
  static const int accentColorValue = 0xFF1976D2; // Blue
  static const int backgroundColorValue = 0xFFF5F5F5; // Light Gray
  static const int surfaceColorValue = 0xFFFFFFFF; // White
  static const int errorColorValue = 0xFFD32F2F; // Red
  
  // Issue Categories
  static const List<Map<String, dynamic>> issueCategories = [
    {
      'id': 'pothole',
      'name': 'Pothole',
      'icon': '🕳️',
      'description': 'Road potholes and surface damage',
      'priority': 'high',
      'department': 'Public Works Department'
    },
    {
      'id': 'streetlight',
      'name': 'Street Light',
      'icon': '💡',
      'description': 'Non-working or damaged street lights',
      'priority': 'medium',
      'department': 'Electricity Department'
    },
    {
      'id': 'garbage',
      'name': 'Garbage',
      'icon': '🗑️',
      'description': 'Garbage collection and disposal issues',
      'priority': 'high',
      'department': 'Municipal Corporation'
    },
    {
      'id': 'water',
      'name': 'Water Supply',
      'icon': '💧',
      'description': 'Water supply and quality issues',
      'priority': 'high',
      'department': 'Water Department'
    },
    {
      'id': 'drainage',
      'name': 'Drainage',
      'icon': '🌊',
      'description': 'Drainage and sewage problems',
      'priority': 'medium',
      'department': 'Public Works Department'
    },
    {
      'id': 'traffic',
      'name': 'Traffic',
      'icon': '🚦',
      'description': 'Traffic signals and road safety',
      'priority': 'high',
      'department': 'Traffic Police'
    },
    {
      'id': 'parks',
      'name': 'Parks & Recreation',
      'icon': '🌳',
      'description': 'Public parks and recreational facilities',
      'priority': 'low',
      'department': 'Municipal Corporation'
    },
    {
      'id': 'other',
      'name': 'Other',
      'icon': '📋',
      'description': 'Other civic issues',
      'priority': 'medium',
      'department': 'General'
    }
  ];
  
  // Issue Status
  static const List<Map<String, dynamic>> issueStatuses = [
    {
      'id': 'submitted',
      'name': 'Submitted',
      'icon': '⏳',
      'color': 0xFF9E9E9E,
      'description': 'Your complaint has been received'
    },
    {
      'id': 'acknowledged',
      'name': 'Acknowledged',
      'icon': '✅',
      'color': 0xFF2196F3,
      'description': 'Your complaint is being reviewed'
    },
    {
      'id': 'in_progress',
      'name': 'In Progress',
      'icon': '🚧',
      'color': 0xFFFF9800,
      'description': 'Work is being done on your complaint'
    },
    {
      'id': 'resolved',
      'name': 'Resolved',
      'icon': '🟢',
      'color': 0xFF4CAF50,
      'description': 'Your complaint has been resolved'
    },
    {
      'id': 'rejected',
      'name': 'Rejected',
      'icon': '❌',
      'color': 0xFFF44336,
      'description': 'Your complaint could not be processed'
    }
  ];
  
  // API Endpoints (Mock for now)
  static const String baseUrl = 'https://api.civicconnect.com';
  static const String reportIssueEndpoint = '/api/issues/report';
  static const String getIssuesEndpoint = '/api/issues';
  static const String updateIssueEndpoint = '/api/issues/update';
  static const String authEndpoint = '/api/auth';
  
  // Local Storage Keys
  static const String userTokenKey = 'user_token';
  static const String userDataKey = 'user_data';
  static const String isFirstTimeKey = 'is_first_time';
  static const String languageKey = 'selected_language';
  static const String notificationKey = 'notifications_enabled';
  
  // Animation Durations
  static const Duration splashDuration = Duration(seconds: 3);
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration buttonAnimationDuration = Duration(milliseconds: 200);
  
  // Map Configuration
  static const double defaultLatitude = 23.6102; // Jharkhand center
  static const double defaultLongitude = 85.2799;
  static const double defaultZoom = 12.0;
  
  // File Upload Limits
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50MB
  static const int maxImagesPerIssue = 5;
  
  // Gamification
  static const int pointsPerIssue = 10;
  static const int pointsPerResolution = 5;
  static const int pointsPerShare = 2;
  
  // Languages
  static const List<Map<String, String>> supportedLanguages = [
    {'code': 'en', 'name': 'English', 'nativeName': 'English'},
    {'code': 'hi', 'name': 'Hindi', 'nativeName': 'हिन्दी'},
    {'code': 'bn', 'name': 'Bengali', 'nativeName': 'বাংলা'},
    {'code': 'or', 'name': 'Odia', 'nativeName': 'ଓଡ଼ିଆ'},
    {'code': 'ta', 'name': 'Tamil', 'nativeName': 'தமிழ்'},
  ];
}
