# Google Authentication & Firebase Integration Setup

## Overview
This document outlines the complete implementation of Google authentication with Firebase and user-specific issue tracking in the SIH Civic Connect app.

## Features Implemented

### 1. Authentication System
- **Google Sign-In**: Users can sign in with their Google accounts
- **Email/Password Authentication**: Traditional email-based authentication
- **Phone Authentication**: OTP-based phone number authentication
- **Guest Mode**: Limited functionality for users who don't want to sign up
- **Persistent Authentication**: Users stay logged in between app sessions

### 2. User Data Management
- **Firebase Firestore Integration**: User data stored securely in Firestore
- **User Profiles**: Complete user profile management with statistics
- **User Statistics**: Track issues reported, resolved, and points earned

### 3. Issue Tracking System
- **User-Specific Issues**: Each user can only see their own reported issues
- **Real-time Updates**: Issues update in real-time using Firestore streams
- **Issue Statistics**: Dashboard showing issue counts by status
- **Authentication Guards**: Prevents unauthenticated users from accessing sensitive features

## Architecture

### Services Layer
1. **AuthService** (`lib/services/auth_service.dart`)
   - Handles all authentication methods
   - Integrates with Firebase Auth
   - Manages user sessions

2. **UserService** (`lib/services/user_service.dart`)
   - Manages user data in Firestore
   - Handles user statistics and profile updates
   - Provides user lookup functionality

3. **FirestoreService** (`lib/services/firestore_service.dart`)
   - Enhanced with user-specific queries
   - Provides real-time issue streaming
   - Handles user statistics aggregation

### State Management
- **AuthProvider** (`lib/providers/auth_provider.dart`)
  - Centralized authentication state management
  - Provides authentication methods to UI
  - Handles loading states and error management

### UI Components

#### Authentication Screens
1. **LoginScreen** (`lib/screens/auth/login_screen.dart`)
   - Multi-method authentication (Google, Email, Phone)
   - Form validation and error handling
   - Smooth animations and transitions

2. **AuthWrapper** (`lib/screens/auth_wrapper.dart`)
   - Determines which screen to show based on auth state
   - Handles loading states during authentication checks

#### Issue Management
1. **MyIssuesScreen** (`lib/screens/issue_tracking/my_issues_screen.dart`)
   - Displays user-specific issues
   - Real-time filtering by status
   - Authentication guards for guest users

2. **IssueReportScreen** (`lib/screens/issue_report/issue_report_screen.dart`)
   - Associates issues with authenticated users
   - Prevents unauthenticated issue reporting
   - Updates user statistics on successful submission

## Firebase Configuration Required

### 1. Firebase Project Setup
```bash
# Install Firebase CLI
npm install -g firebase-tools

# Login to Firebase
firebase login

# Initialize Firebase in your project
firebase init
```

### 2. Enable Authentication Methods
In Firebase Console:
1. Go to Authentication > Sign-in method
2. Enable Google Sign-in
3. Enable Email/Password
4. Enable Phone authentication
5. Configure authorized domains

### 3. Firestore Database Setup
```javascript
// Firestore Security Rules
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Users can read/write their own user document
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Users can read/write their own issues
    match /issues/{issueId} {
      allow read, write: if request.auth != null && 
        (request.auth.uid == resource.data.userId || 
         request.auth.uid == request.resource.data.userId);
    }
    
    // Allow reading all issues for public viewing
    match /issues/{issueId} {
      allow read: if resource.data.isPublic == true;
    }
  }
}
```

### 4. Required Dependencies
Ensure these dependencies are in your `pubspec.yaml`:
```yaml
dependencies:
  firebase_core: ^2.31.0
  firebase_auth: ^4.19.5
  google_sign_in: ^6.2.1
  cloud_firestore: ^4.17.3
  firebase_storage: ^11.7.5
  provider: ^6.1.2
```

## Usage Flow

### 1. App Startup
1. Splash screen loads
2. AuthWrapper checks authentication state
3. Routes to appropriate screen (Login or Home)

### 2. Authentication Flow
1. User selects authentication method
2. AuthProvider handles the authentication
3. User data is stored/updated in Firestore
4. App navigates to main interface

### 3. Issue Reporting
1. User attempts to report an issue
2. System checks authentication status
3. If authenticated: Issue is associated with user
4. If not authenticated: Login prompt is shown
5. User statistics are updated on successful submission

### 4. Issue Tracking
1. MyIssuesScreen loads user-specific issues
2. Real-time updates via Firestore streams
3. Filtering and statistics are calculated
4. Guest users see appropriate messaging

## Security Considerations

### 1. Data Privacy
- Users can only access their own issues
- User data is protected by Firestore security rules
- Authentication tokens are handled securely by Firebase

### 2. Guest Mode Limitations
- Guest users cannot report issues
- Guest users cannot access issue tracking
- Guest data is stored locally only

### 3. Error Handling
- Comprehensive error handling for all authentication methods
- User-friendly error messages
- Graceful fallbacks for network issues

## Testing the Implementation

### 1. Authentication Testing
- Test Google Sign-in with valid Google account
- Test email/password registration and login
- Test phone authentication with valid phone number
- Test guest mode functionality

### 2. Issue Management Testing
- Report issues while authenticated
- Verify issues appear in MyIssuesScreen
- Test filtering by status
- Verify statistics are updated correctly

### 3. Security Testing
- Attempt to access issues while not authenticated
- Verify Firestore security rules prevent unauthorized access
- Test data persistence across app restarts

## Troubleshooting

### Common Issues
1. **Google Sign-in fails**: Check SHA-1 fingerprint configuration
2. **Firestore permission denied**: Verify security rules
3. **Issues not appearing**: Check user ID association
4. **Statistics not updating**: Verify UserService integration

### Debug Steps
1. Check Firebase Console for authentication logs
2. Verify Firestore data structure
3. Check device logs for error messages
4. Test with Firebase Emulator for local development

## Future Enhancements

### Planned Features
1. **Social Authentication**: Facebook, Twitter integration
2. **Biometric Authentication**: Fingerprint/Face ID
3. **Multi-factor Authentication**: Enhanced security
4. **Offline Support**: Sync when connection restored
5. **Push Notifications**: Issue status updates
6. **Admin Dashboard**: Issue management interface

### Performance Optimizations
1. **Pagination**: For large issue lists
2. **Caching**: Reduce Firestore reads
3. **Image Optimization**: Compress uploaded images
4. **Background Sync**: Update data in background

## Conclusion

The authentication and issue tracking system provides a secure, user-friendly experience with real-time data synchronization. The modular architecture allows for easy maintenance and future enhancements while ensuring data privacy and security best practices.
