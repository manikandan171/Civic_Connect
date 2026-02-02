# SIH Civic App - Setup Instructions

## 🚀 Quick Start Guide

### 1. Mapillary API Key Setup (CRITICAL)

The app uses Mapillary for street-level imagery and mapping functionality. The API key is already configured:

#### Current Configuration
The Mapillary API key is already set up in the following file:

**File:** `android/app/src/main/res/values/google_maps_api.xml`
```xml
<string name="mapillary_api_key">MLY|24197444293272639|aa5294f3922fa84e8dd0f0002e59fdea</string>
```

#### Features Available
- **Street View Integration**: Access to Mapillary's street-level imagery
- **Interactive Maps**: Web-based map interface using Mapillary viewer
- **Location Services**: GPS-based location detection and mapping
- **Issue Mapping**: Visual representation of reported issues on the map

#### API Key Management
- The current API key provides access to Mapillary's public imagery
- For production use, consider getting your own API key from [Mapillary Developer Dashboard](https://www.mapillary.com/dashboard/developers)
- The key is configured in the Android manifest for secure access

### 2. Dependencies Installation

Run the following command to install all dependencies:

```bash
flutter pub get
```

### 3. Build and Run

```bash
# Clean previous builds
flutter clean

# Get dependencies
flutter pub get

# Run the app
flutter run
```

## 📱 Features Overview

### ✅ Implemented Features
- **Authentication System**: Login/Signup with multiple methods
- **Issue Reporting**: Multi-step form with image/video capture
- **Interactive Map**: Mapillary integration with street view and issue markers
- **Issue Tracking**: View and track reported issues
- **Notifications**: Local and push notifications
- **Settings**: Language selection, voice input, dark mode
- **Gamification**: Leaderboard and points system
- **Profile Management**: User profile with achievements

### 🎨 UI Components
- Modern Material Design 3
- Smooth animations with flutter_staggered_animations
- Responsive design
- Dark/Light theme support
- Multi-language support (English, Hindi, Bengali, Odia)

## 🔧 Configuration Files

### Android Configuration
- **Manifest**: `android/app/src/main/AndroidManifest.xml`
- **API Key**: `android/app/src/main/res/values/google_maps_api.xml` (Mapillary API key)
- **Permissions**: All necessary permissions are already configured

### Flutter Configuration
- **Dependencies**: `pubspec.yaml`
- **App Constants**: `lib/constants/app_constants.dart`
- **Theme**: `lib/constants/app_theme.dart`

## 🚨 Troubleshooting

### Common Issues

#### 1. Mapillary API Error
```
Failed to load map: API key not found or invalid
```

**Solution**: 
- The Mapillary API key is already configured
- If you encounter issues, check your internet connection
- The app uses web-based Mapillary viewer, so ensure web access is available

#### 2. Build Errors
```bash
# Clean and rebuild
flutter clean
flutter pub get
flutter run
```

#### 3. Permission Issues
All necessary permissions are configured in the AndroidManifest.xml:
- Internet access
- Location access (fine and coarse)
- Camera access
- Storage access
- Audio recording

#### 4. Missing Dependencies
```bash
flutter pub get
```

## 📂 Project Structure

```
lib/
├── constants/          # App constants and theme
├── models/            # Data models
├── screens/           # UI screens
│   ├── auth/         # Authentication screens
│   ├── home/         # Home and dashboard
│   ├── issue_report/ # Issue reporting
│   ├── issue_tracking/ # Issue tracking
│   ├── map/          # Interactive map
│   ├── notifications/ # Notifications
│   ├── profile/      # User profile
│   └── settings/     # App settings
├── services/         # Business logic services
├── utils/           # Helper functions and extensions
└── widgets/         # Reusable UI components
```

## 🔐 Security Notes

1. **API Key Security**: The Mapillary API key is configured for public access
2. **Permissions**: The app requests only necessary permissions
3. **Data Privacy**: User data is handled securely
4. **Mapillary Integration**: Uses web-based viewer for street-level imagery

## 🎯 Next Steps

1. **Test the app** on a physical device or emulator
2. **Customize the branding** in `app_constants.dart`
3. **Configure backend APIs** when ready for production
4. **Add Firebase** for push notifications (optional)
5. **Explore Mapillary features** - street view and interactive mapping

## 📞 Support

If you encounter any issues:
1. Check the troubleshooting section above
2. Ensure all dependencies are properly installed
3. Verify your internet connection for Mapillary access
4. Check the Flutter and Dart versions compatibility

## 🏆 SIH 2025

This app is built for Smart India Hackathon 2025 with the theme of civic engagement and digital governance.

---

**Note**: The app now uses Mapillary for mapping functionality, providing street-level imagery and interactive maps. The API key is already configured and ready to use.
