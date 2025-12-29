# JINEN - Application de Gestion de Garderie (Flutter)

A Flutter application for finding and managing daycare/nursery services (Garderie).

This project was migrated from a React/Vite application to Flutter for cross-platform support (Android, iOS, Web, Windows, macOS, Linux).

## Prerequisites

- Flutter SDK (>=3.0.0)
- Dart SDK
- Android Studio (for Android development)
- Xcode (for iOS development, macOS only)
- VS Code or Android Studio with Flutter plugin

## Getting Started

### 1. Install Flutter

Follow the official Flutter installation guide for your platform:
https://docs.flutter.dev/get-started/install

### 2. Install Dependencies

```bash
flutter pub get
```

### 3. Run the App

For Android:

```bash
flutter run -d android
```

For iOS (macOS only):

```bash
flutter run -d ios
```

For Web:

```bash
flutter run -d chrome
```

For Windows:

```bash
flutter run -d windows
```

### 4. Build Release Version

For Android:

```bash
flutter build apk --release
```

For iOS:

```bash
flutter build ios --release
```

For Web:

```bash
flutter build web --release
```

## Project Structure

```
lib/
  ├── main.dart              # App entry point
  ├── app.dart               # Main app widget
  ├── models/                # Data models
  │   ├── user.dart
  │   ├── child.dart
  │   ├── nursery.dart
  │   └── review.dart
  ├── providers/             # State management
  │   └── app_state.dart
  └── screens/               # UI screens
      ├── welcome_screen.dart
      ├── auth_screen.dart
      ├── parent_dashboard.dart
      ├── nursery_dashboard.dart
      ├── nursery_search.dart
      └── nursery_details.dart
```

## Features

- Welcome screen with app introduction
- Authentication (Sign In / Sign Up)
- Parent dashboard with child management
- Nursery search and filtering
- Nursery details with ratings and reviews
- Nursery dashboard for managing enrollment

## State Management

This app uses the `provider` package for state management. The main app state is managed in `AppState` class.

## Original Design

The original design is available at: https://www.figma.com/design/nyqz406RYiODaxJS88uq99/Smart-Farm-Irrigation-App (Note: This was the original design reference from another project)

## License

Private project
