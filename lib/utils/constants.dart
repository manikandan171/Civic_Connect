// API Constants
class ApiConstants {
  static const String baseUrl = 'https://api.sihcivic.com';
  static const String version = 'v1';
  
  // Endpoints
  static const String auth = '/auth';
  static const String issues = '/issues';
  static const String users = '/users';
  static const String notifications = '/notifications';
  static const String upload = '/upload';
  static const String statistics = '/statistics';
  
  // Timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}

// Storage Keys
class StorageKeys {
  static const String userToken = 'user_token';
  static const String userData = 'user_data';
  static const String isFirstTime = 'is_first_time';
  static const String language = 'selected_language';
  static const String notifications = 'notifications_enabled';
  static const String darkMode = 'dark_mode';
  static const String autoSync = 'auto_sync';
  static const String locationTracking = 'location_tracking';
  static const String voiceInput = 'voice_input_enabled';
  static const String fcmToken = 'fcm_token';
  static const String lastSyncTime = 'last_sync_time';
  static const String pendingIssues = 'pending_issues';
  static const String cachedIssues = 'cached_issues';
  static const String cachedNotifications = 'cached_notifications';
}

// Database Constants
class DatabaseConstants {
  static const String databaseName = 'sih_civic.db';
  static const int databaseVersion = 1;
  
  // Table Names
  static const String issuesTable = 'issues';
  static const String usersTable = 'users';
  static const String notificationsTable = 'notifications';
  static const String pendingSyncTable = 'pending_sync';
  static const String settingsTable = 'settings';
}

// File Constants
class FileConstants {
  // Max file sizes (in bytes)
  static const int maxImageSize = 5 * 1024 * 1024; // 5MB
  static const int maxVideoSize = 50 * 1024 * 1024; // 50MB
  static const int maxDocumentSize = 10 * 1024 * 1024; // 10MB
  
  // Allowed file extensions
  static const List<String> allowedImageExtensions = [
    '.jpg', '.jpeg', '.png', '.gif', '.webp', '.bmp'
  ];
  
  static const List<String> allowedVideoExtensions = [
    '.mp4', '.mov', '.avi', '.mkv', '.webm', '.3gp'
  ];
  
  static const List<String> allowedDocumentExtensions = [
    '.pdf', '.doc', '.docx', '.txt', '.rtf'
  ];
  
  // File paths
  static const String imagesPath = 'images';
  static const String videosPath = 'videos';
  static const String documentsPath = 'documents';
  static const String cachePath = 'cache';
  static const String tempPath = 'temp';
}

// UI Constants
class UIConstants {
  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 300);
  static const Duration longAnimation = Duration(milliseconds: 500);
  
  // Page transitions
  static const Duration pageTransition = Duration(milliseconds: 300);
  static const Duration splashDuration = Duration(seconds: 3);
  
  // Sizes
  static const double borderRadius = 12.0;
  static const double smallBorderRadius = 8.0;
  static const double largeBorderRadius = 16.0;
  static const double extraLargeBorderRadius = 20.0;
  
  // Spacing
  static const double smallSpacing = 8.0;
  static const double mediumSpacing = 16.0;
  static const double largeSpacing = 24.0;
  static const double extraLargeSpacing = 32.0;
  
  // Icon sizes
  static const double smallIconSize = 16.0;
  static const double mediumIconSize = 24.0;
  static const double largeIconSize = 32.0;
  static const double extraLargeIconSize = 48.0;
  
  // Button heights
  static const double smallButtonHeight = 36.0;
  static const double mediumButtonHeight = 48.0;
  static const double largeButtonHeight = 56.0;
  
  // Input field heights
  static const double smallInputHeight = 40.0;
  static const double mediumInputHeight = 48.0;
  static const double largeInputHeight = 56.0;
  
  // Card elevations
  static const double smallElevation = 2.0;
  static const double mediumElevation = 4.0;
  static const double largeElevation = 8.0;
  
  // Border widths
  static const double thinBorder = 1.0;
  static const double mediumBorder = 2.0;
  static const double thickBorder = 3.0;
}

// Validation Constants
class ValidationConstants {
  // Length limits
  static const int minNameLength = 2;
  static const int maxNameLength = 50;
  static const int minPasswordLength = 6;
  static const int maxPasswordLength = 50;
  static const int minIssueTitleLength = 5;
  static const int maxIssueTitleLength = 100;
  static const int minIssueDescriptionLength = 10;
  static const int maxIssueDescriptionLength = 1000;
  static const int minAddressLength = 10;
  static const int maxAddressLength = 200;
  static const int otpLength = 6;
  
  // Phone number limits
  static const int minPhoneLength = 10;
  static const int maxPhoneLength = 15;
  
  // Email validation
  static const String emailRegex = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  
  // Name validation
  static const String nameRegex = r"^[a-zA-Z\s\-']+$";
  
  // URL validation
  static const String urlRegex = r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';
}

// Location Constants
class LocationConstants {
  // Default location (Jharkhand center)
  static const double defaultLatitude = 23.6102;
  static const double defaultLongitude = 85.2799;
  static const double defaultZoom = 12.0;
  
  // Location accuracy
  static const double locationAccuracy = 10.0; // meters
  
  // Search radius
  static const double defaultSearchRadius = 5000.0; // 5km in meters
  static const double maxSearchRadius = 50000.0; // 50km in meters
  
  // Map constraints
  static const double minZoom = 5.0;
  static const double maxZoom = 20.0;
  
  // Location update intervals
  static const Duration locationUpdateInterval = Duration(seconds: 30);
  static const Duration fastLocationUpdateInterval = Duration(seconds: 5);
}

// Notification Constants
class NotificationConstants {
  // Channel IDs
  static const String defaultChannelId = 'sih_civic_default';
  static const String issueUpdatesChannelId = 'sih_civic_issue_updates';
  static const String campaignsChannelId = 'sih_civic_campaigns';
  static const String gamificationChannelId = 'sih_civic_gamification';
  
  // Channel Names
  static const String defaultChannelName = 'Default Notifications';
  static const String issueUpdatesChannelName = 'Issue Updates';
  static const String campaignsChannelName = 'Campaigns';
  static const String gamificationChannelName = 'Gamification';
  
  // Channel Descriptions
  static const String defaultChannelDescription = 'General notifications from SIH Civic app';
  static const String issueUpdatesChannelDescription = 'Notifications about your reported issues';
  static const String campaignsChannelDescription = 'Notifications about community campaigns';
  static const String gamificationChannelDescription = 'Notifications about achievements and leaderboard';
  
  // Notification IDs
  static const int issueUpdateNotificationId = 1000;
  static const int campaignNotificationId = 2000;
  static const int gamificationNotificationId = 3000;
  static const int reminderNotificationId = 4000;
  
  // Timeouts
  static const Duration notificationTimeout = Duration(seconds: 5);
  static const Duration reminderInterval = Duration(hours: 24);
}

// Gamification Constants
class GamificationConstants {
  // Points
  static const int pointsPerIssueReport = 10;
  static const int pointsPerIssueResolution = 5;
  static const int pointsPerShare = 2;
  static const int pointsPerFirstReport = 20;
  static const int pointsPerStreak = 5;
  
  // Badges
  static const String firstReportBadge = 'First Reporter';
  static const String civicChampionBadge = 'Civic Champion';
  static const String problemSolverBadge = 'Problem Solver';
  static const String communityHelperBadge = 'Community Helper';
  static const String earlyBirdBadge = 'Early Bird';
  static const String newcomerBadge = 'Newcomer';
  
  // Badge requirements
  static const int firstReportThreshold = 1;
  static const int civicChampionThreshold = 10;
  static const int problemSolverThreshold = 5;
  static const int communityHelperThreshold = 3;
  static const int earlyBirdThreshold = 1;
  static const int newcomerThreshold = 1;
  
  // Leaderboard
  static const int leaderboardPageSize = 20;
  static const int topContributorsCount = 10;
  
  // Streaks
  static const int maxStreakDays = 30;
  static const int streakBonusMultiplier = 2;
}

// Error Messages
class ErrorMessages {
  static const String networkError = 'Network connection error. Please check your internet connection.';
  static const String serverError = 'Server error. Please try again later.';
  static const String unknownError = 'An unknown error occurred. Please try again.';
  static const String locationError = 'Unable to get your location. Please check location permissions.';
  static const String cameraError = 'Unable to access camera. Please check camera permissions.';
  static const String storageError = 'Unable to access storage. Please check storage permissions.';
  static const String microphoneError = 'Unable to access microphone. Please check microphone permissions.';
  static const String notificationError = 'Unable to send notification. Please check notification permissions.';
  static const String fileUploadError = 'Failed to upload file. Please try again.';
  static const String authenticationError = 'Authentication failed. Please check your credentials.';
  static const String validationError = 'Please check your input and try again.';
  static const String permissionError = 'Permission denied. Please grant required permissions.';
  static const String timeoutError = 'Request timed out. Please try again.';
  static const String offlineError = 'You are offline. Some features may not be available.';
}

// Success Messages
class SuccessMessages {
  static const String issueReported = 'Issue reported successfully!';
  static const String issueUpdated = 'Issue updated successfully!';
  static const String profileUpdated = 'Profile updated successfully!';
  static const String settingsSaved = 'Settings saved successfully!';
  static const String dataSynced = 'Data synced successfully!';
  static const String notificationSent = 'Notification sent successfully!';
  static const String fileUploaded = 'File uploaded successfully!';
  static const String accountCreated = 'Account created successfully!';
  static const String loginSuccessful = 'Login successful!';
  static const String logoutSuccessful = 'Logout successful!';
  static const String passwordChanged = 'Password changed successfully!';
  static const String emailVerified = 'Email verified successfully!';
  static const String phoneVerified = 'Phone number verified successfully!';
}

// Regular Expressions
class RegexPatterns {
  static const String email = r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$';
  static const String phone = r'^\+?[1-9]\d{1,14}$';
  static const String name = r"^[a-zA-Z\s\-']+$";
  static const String url = r'^https?:\/\/(www\.)?[-a-zA-Z0-9@:%._\+~#=]{1,256}\.[a-zA-Z0-9()]{1,6}\b([-a-zA-Z0-9()@:%_\+.~#?&//=]*)$';
  static const String alphanumeric = r'^[a-zA-Z0-9]+$';
  static const String numeric = r'^[0-9]+$';
  static const String alphabetic = r'^[a-zA-Z]+$';
  static const String password = r'^(?=.*[a-z])(?=.*[A-Z])(?=.*\d)[a-zA-Z\d@$!%*?&]{8,}$';
  static const String complaintId = r'^SIH\d{8}\d{6}$';
}
