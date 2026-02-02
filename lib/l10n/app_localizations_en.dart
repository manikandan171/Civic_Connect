// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'Civic Connect';

  @override
  String get appTagline => 'Report, Track, Resolve';

  @override
  String get welcomeBack => 'Welcome back!';

  @override
  String get welcome => 'Welcome!';

  @override
  String get readyToMakeDifference => 'Ready to make a difference?';

  @override
  String hello(String name) {
    return 'Hello $name!';
  }

  @override
  String get home => 'Home';

  @override
  String get myIssues => 'My Issues';

  @override
  String get map => 'Map';

  @override
  String get updates => 'Updates';

  @override
  String get profile => 'Profile';

  @override
  String get notifications => 'Notifications';

  @override
  String get yourImpact => 'Your Impact';

  @override
  String get issuesReported => 'Issues Reported';

  @override
  String get resolved => 'Resolved';

  @override
  String get points => 'Points';

  @override
  String get quickActions => 'Quick Actions';

  @override
  String get reportIssue => 'Report Issue';

  @override
  String get takePhotoAndReport => 'Take a photo and report';

  @override
  String get viewMap => 'View Map';

  @override
  String get seeAllReportedIssues => 'See all reported issues';

  @override
  String get myReports => 'My Reports';

  @override
  String get trackYourComplaints => 'Track your complaints';

  @override
  String get checkUpdates => 'Check updates';

  @override
  String get recentIssues => 'Recent Issues';

  @override
  String get viewAll => 'View All';

  @override
  String get noIssuesReported => 'No issues reported yet';

  @override
  String get reportFirstIssue => 'Report your first issue to get started!';

  @override
  String get campaignsAndUpdates => 'Campaigns & Updates';

  @override
  String get cleanlinessDrive => 'Cleanliness Drive';

  @override
  String get joinCommunityCleanup =>
      'Join us this Sunday for a community cleanup drive';

  @override
  String get submitted => 'Submitted';

  @override
  String get acknowledged => 'Acknowledged';

  @override
  String get inProgress => 'In Progress';

  @override
  String get rejected => 'Rejected';

  @override
  String get justNow => 'Just now';

  @override
  String minuteAgo(int count) {
    return '$count minute ago';
  }

  @override
  String minutesAgo(int count) {
    return '$count minutes ago';
  }

  @override
  String hourAgo(int count) {
    return '$count hour ago';
  }

  @override
  String hoursAgo(int count) {
    return '$count hours ago';
  }

  @override
  String dayAgo(int count) {
    return '$count day ago';
  }

  @override
  String daysAgo(int count) {
    return '$count days ago';
  }

  @override
  String weekAgo(int count) {
    return '$count week ago';
  }

  @override
  String weeksAgo(int count) {
    return '$count weeks ago';
  }

  @override
  String get settings => 'Settings';

  @override
  String get general => 'General';

  @override
  String get language => 'Language';

  @override
  String get darkMode => 'Dark Mode';

  @override
  String get useDarkTheme => 'Use dark theme throughout the app';

  @override
  String get receiveUpdates => 'Receive updates about your reported issues';

  @override
  String get privacySecurity => 'Privacy & Security';

  @override
  String get locationTracking => 'Location Tracking';

  @override
  String get allowLocationAccess => 'Allow location access for issue reporting';

  @override
  String get dataUsage => 'Data Usage';

  @override
  String get manageDataSync => 'Manage data synchronization preferences';

  @override
  String get accessibility => 'Accessibility';

  @override
  String get voiceInput => 'Voice Input';

  @override
  String get enableVoiceCommands => 'Enable voice commands for reporting';

  @override
  String get signIn => 'Sign In';

  @override
  String get signUp => 'Sign Up';

  @override
  String get email => 'Email';

  @override
  String get password => 'Password';

  @override
  String get name => 'Name';

  @override
  String get phone => 'Phone';

  @override
  String get signInWithGoogle => 'Sign in with Google';

  @override
  String get continueAsGuest => 'Continue as Guest';

  @override
  String get forgotPassword => 'Forgot Password?';

  @override
  String get dontHaveAccount => 'Don\'t have an account?';

  @override
  String get alreadyHaveAccount => 'Already have an account?';

  @override
  String get loading => 'Loading...';

  @override
  String get error => 'Error';

  @override
  String get success => 'Success';

  @override
  String get cancel => 'Cancel';

  @override
  String get ok => 'OK';

  @override
  String get save => 'Save';

  @override
  String get delete => 'Delete';

  @override
  String get edit => 'Edit';

  @override
  String get share => 'Share';

  @override
  String get retry => 'Retry';

  @override
  String get issueTitle => 'Issue Title';

  @override
  String get issueDescription => 'Issue Description';

  @override
  String get category => 'Category';

  @override
  String get priority => 'Priority';

  @override
  String get location => 'Location';

  @override
  String get attachPhotos => 'Attach Photos';

  @override
  String get submitIssue => 'Submit Issue';

  @override
  String get low => 'Low';

  @override
  String get medium => 'Medium';

  @override
  String get high => 'High';

  @override
  String get urgent => 'Urgent';

  @override
  String get all => 'All';

  @override
  String get filter => 'Filter';

  @override
  String get search => 'Search';

  @override
  String get sort => 'Sort';

  @override
  String get guestUser => 'Guest User';

  @override
  String get onboarding => 'Onboarding';

  @override
  String get reportIssuesTitle => 'Report Issues';

  @override
  String get reportIssuesDesc =>
      'Easily report civic issues like potholes, broken street lights, and garbage problems with just a few taps.';

  @override
  String get trackProgressTitle => 'Track Progress';

  @override
  String get trackProgressDesc =>
      'Monitor the status of your reported issues in real-time and get updates on resolution progress.';

  @override
  String get makeDifferenceTitle => 'Make a Difference';

  @override
  String get makeDifferenceDesc =>
      'Join thousands of citizens working together to improve our community and make our city better.';

  @override
  String get getStarted => 'Get Started';

  @override
  String get skip => 'Skip';

  @override
  String get next => 'Next';

  @override
  String get previous => 'Previous';

  @override
  String get enterOTP => 'Enter OTP';

  @override
  String enterOTPSent(String phone) {
    return 'Enter the OTP sent to $phone';
  }

  @override
  String get verify => 'Verify';

  @override
  String get resendOTP => 'Resend OTP';

  @override
  String get otpVerification => 'OTP Verification';

  @override
  String authenticationFailed(String error) {
    return 'Authentication failed: $error';
  }

  @override
  String googleSignInFailed(String error) {
    return 'Google sign in failed: $error';
  }

  @override
  String guestModeFailed(String error) {
    return 'Guest mode failed: $error';
  }

  @override
  String get profileSettings => 'Profile Settings';

  @override
  String get personalInfo => 'Personal Information';

  @override
  String get accountSettings => 'Account Settings';

  @override
  String get helpSupport => 'Help & Support';

  @override
  String get aboutApp => 'About App';

  @override
  String get logout => 'Logout';

  @override
  String get editProfile => 'Edit Profile';

  @override
  String get changePassword => 'Change Password';

  @override
  String get deleteAccount => 'Delete Account';

  @override
  String get version => 'Version';

  @override
  String get termsConditions => 'Terms & Conditions';

  @override
  String get privacyPolicy => 'Privacy Policy';

  @override
  String get contactUs => 'Contact Us';

  @override
  String get rateApp => 'Rate App';

  @override
  String get shareApp => 'Share App';

  @override
  String get issueCategories => 'Issue Categories';

  @override
  String get roadInfrastructure => 'Road & Infrastructure';

  @override
  String get waterSupply => 'Water Supply';

  @override
  String get electricity => 'Electricity';

  @override
  String get wasteManagement => 'Waste Management';

  @override
  String get publicSafety => 'Public Safety';

  @override
  String get healthcare => 'Healthcare';

  @override
  String get education => 'Education';

  @override
  String get transport => 'Transport';

  @override
  String get environment => 'Environment';

  @override
  String get other => 'Other';

  @override
  String get selectCategory => 'Select Category';

  @override
  String get selectPriority => 'Select Priority';

  @override
  String get selectLocation => 'Select Location';

  @override
  String get useCurrentLocation => 'Use Current Location';

  @override
  String get selectFromMap => 'Select from Map';

  @override
  String get addDescription => 'Add Description';

  @override
  String get addPhotos => 'Add Photos';

  @override
  String get addVideo => 'Add Video';

  @override
  String get submitReport => 'Submit Report';

  @override
  String get reportSubmitted => 'Report Submitted Successfully';

  @override
  String get reportSubmittedDesc =>
      'Your issue has been reported. You will receive updates on its progress.';

  @override
  String get myReportsEmpty => 'No reports found';

  @override
  String get myReportsEmptyDesc =>
      'You haven\'t reported any issues yet. Start by reporting your first issue!';

  @override
  String get filterByStatus => 'Filter by Status';

  @override
  String get filterByCategory => 'Filter by Category';

  @override
  String get sortBy => 'Sort By';

  @override
  String get sortByDate => 'Sort by Date';

  @override
  String get sortByPriority => 'Sort by Priority';

  @override
  String get sortByStatus => 'Sort by Status';

  @override
  String get mapView => 'Map View';

  @override
  String get listView => 'List View';

  @override
  String get nearbyIssues => 'Nearby Issues';

  @override
  String get allIssues => 'All Issues';

  @override
  String get myLocation => 'My Location';

  @override
  String get issueDetails => 'Issue Details';

  @override
  String get reportedBy => 'Reported by';

  @override
  String get reportedOn => 'Reported on';

  @override
  String get lastUpdated => 'Last Updated';

  @override
  String get issueId => 'Issue ID';

  @override
  String get upvote => 'Upvote';

  @override
  String get downvote => 'Downvote';

  @override
  String get addComment => 'Add Comment';

  @override
  String get comments => 'Comments';

  @override
  String get noComments => 'No comments yet';

  @override
  String get markAllRead => 'Mark All Read';

  @override
  String get noNotifications => 'No notifications';

  @override
  String get noNotificationsDesc =>
      'You\'re all caught up! No new notifications.';

  @override
  String get issueUpdate => 'Issue Update';

  @override
  String get systemNotification => 'System Notification';

  @override
  String get newComment => 'New Comment';

  @override
  String get connectionError => 'Connection Error';

  @override
  String get noInternetConnection => 'No internet connection';

  @override
  String get tryAgain => 'Try Again';

  @override
  String get somethingWentWrong => 'Something went wrong';

  @override
  String get pleaseCheckConnection =>
      'Please check your internet connection and try again';

  @override
  String get permissionRequired => 'Permission Required';

  @override
  String get cameraPermission => 'Camera Permission';

  @override
  String get locationPermission => 'Location Permission';

  @override
  String get storagePermission => 'Storage Permission';

  @override
  String get cameraPermissionDesc =>
      'This app needs camera access to take photos of issues';

  @override
  String get locationPermissionDesc =>
      'This app needs location access to report issues accurately';

  @override
  String get storagePermissionDesc =>
      'This app needs storage access to save photos';

  @override
  String get grantPermission => 'Grant Permission';

  @override
  String get openSettings => 'Open Settings';

  @override
  String get confirmDelete => 'Confirm Delete';

  @override
  String get deleteIssueConfirm =>
      'Are you sure you want to delete this issue?';

  @override
  String get deleteAccountConfirm =>
      'Are you sure you want to delete your account? This action cannot be undone.';

  @override
  String get confirmLogout => 'Confirm Logout';

  @override
  String get logoutConfirm => 'Are you sure you want to logout?';

  @override
  String get updateAvailable => 'Update Available';

  @override
  String get updateAvailableDesc =>
      'A new version of the app is available. Please update to get the latest features.';

  @override
  String get updateNow => 'Update Now';

  @override
  String get updateLater => 'Update Later';

  @override
  String get maintenance => 'Under Maintenance';

  @override
  String get maintenanceDesc =>
      'The app is currently under maintenance. Please try again later.';

  @override
  String get dataSync => 'Data Sync';

  @override
  String get syncInProgress => 'Syncing data...';

  @override
  String get syncComplete => 'Sync complete';

  @override
  String get syncFailed => 'Sync failed';

  @override
  String lastSynced(String time) {
    return 'Last synced: $time';
  }

  @override
  String get voiceRecording => 'Voice Recording';

  @override
  String get startRecording => 'Start Recording';

  @override
  String get stopRecording => 'Stop Recording';

  @override
  String get playRecording => 'Play Recording';

  @override
  String get deleteRecording => 'Delete Recording';

  @override
  String get recordingTooShort => 'Recording too short';

  @override
  String get recordingTooLong => 'Recording too long';

  @override
  String get imageProcessing => 'Processing image...';

  @override
  String get uploadingImages => 'Uploading images...';

  @override
  String get uploadComplete => 'Upload complete';

  @override
  String get uploadFailed => 'Upload failed';

  @override
  String get validationErrors => 'Validation Errors';

  @override
  String get fieldRequired => 'This field is required';

  @override
  String get invalidEmail => 'Invalid email address';

  @override
  String get invalidPhone => 'Invalid phone number';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get passwordsDoNotMatch => 'Passwords do not match';

  @override
  String get titleTooShort => 'Title must be at least 5 characters';

  @override
  String get descriptionTooShort =>
      'Description must be at least 10 characters';
}
