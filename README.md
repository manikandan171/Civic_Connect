# Civic Connect 🏛️

Civic Connect is a comprehensive Flutter application designed to bridge the gap between citizens and local governance. It empowers users to report civic issues, track their resolution status in real-time, and actively engage with their local community.

## 🚀 Key Features

* **User Authentication:** Secure login and registration using Firebase Auth and Google Sign-In.
* **Issue Reporting:** Capture photos of civic issues using the device camera or gallery, and upload them securely.
* **Location Intelligence:** Automatically tag issues with precise geolocation data and view them on interactive maps (powered by `flutter_map` and `geolocator`).
* **Real-time Tracking:** Monitor the progress of reported issues via Cloud Firestore real-time updates.
* **Secure Media:** End-to-end encryption for images and media files to ensure user privacy.
* **Push Notifications:** Stay updated with Firebase Cloud Messaging and local notifications.
* **Offline Support:** Local caching and data storage using `sqflite` for seamless offline experiences.
* **Multi-Language Support:** Fully localized interface to cater to diverse communities.

## 🛠️ Technology Stack

* **Framework:** Flutter (Dart)
* **State Management:** Provider
* **Navigation:** GoRouter
* **Backend Integration:** Firebase (Auth, Firestore, Storage, Messaging)
* **Mapping:** Flutter Map & LatLong2
* **Storage:** Sqflite & Shared Preferences
* **Security:** Crypto & Encrypt packages

## 📦 Getting Started

### Prerequisites

* Flutter SDK (^3.9.0)
* Dart SDK
* Firebase Project Setup

### Installation

1. **Clone the repository:**
   ```bash
   git clone https://github.com/your-username/Civic_Connect.git
   ```

2. **Install dependencies:**
   ```bash
   flutter pub get
   ```

3. **Configure Firebase:**
   * Create a Firebase project.
   * Add your Android (`google-services.json`) and iOS (`GoogleService-Info.plist`) configuration files to their respective directories.
   * Update `lib/firebase_options.dart` with your Firebase project credentials.

4. **Run the app:**
   ```bash
   flutter run
   ```

## 🔒 Security & Privacy

This project strictly adheres to security best practices. Sensitive credentials such as API keys, `google-services.json`, and `.env` files are ignored from version control to prevent unauthorized access. Media uploaded by users is encrypted before transit and at rest.

## 🤝 Contributing

Contributions are welcome! Please feel free to submit a Pull Request.
