# Business Ops App

A Flutter application for business operations management integrated with Firebase.

## Setup Instructions

Before running this project, you need to set up your Firebase configuration:

1. Create a Firebase project at [Firebase Console](https://console.firebase.google.com/)
2. Add your app to the Firebase project
3. Download the `google-services.json` file for Android or `GoogleService-Info.plist` for iOS
4. Create a `firebase_options.dart` file in the `lib` directory with your Firebase configuration
   - This file should contain your Firebase API keys and project settings
   - Keep it simple and clean with just the necessary configuration

## Firebase Integration

This app uses Firebase for:
- Authentication
- Cloud Firestore
- Firebase Storage

## Running the App

After setting up Firebase, run the app with:

```bash
flutter pub get
flutter run
```