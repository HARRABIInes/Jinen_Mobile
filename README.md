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
- **Manage Enrolled Children** - View all parents and their children enrolled in the nursery

### Nursery Management Features

#### 1. Manage Enrolled Children Dashboard

**Location**: Nursery Dashboard → Actions rapides → "Gérer les inscrits"

This feature allows nursery staff to view and manage all enrolled children and their parent information in one centralized dashboard.

**Features**:
- View all parents enrolled in the nursery with their contact information
- See all children associated with each parent
- Display enrollment status (Active, Pending, Completed, Cancelled)
- View child details: name, age, birth date
- See enrollment dates for tracking
- Real-time count of total parents and children
- Pull-to-refresh functionality

**Backend Endpoint**:
```
GET /api/nurseries/:nurseryId/enrolled-children
```

**Response**:
```json
{
  "success": true,
  "nurseryId": "uuid",
  "totalParents": 5,
  "totalChildren": 8,
  "parents": [
    {
      "parentId": "uuid",
      "parentName": "Parent Name",
      "parentEmail": "parent@example.com",
      "parentPhone": "+216XX000000",
      "children": [
        {
          "childId": "uuid",
          "childName": "Child Name",
          "age": 3,
          "birthDate": "2021-05-15",
          "enrollmentId": "uuid",
          "enrollmentStatus": "active",
          "startDate": "2024-01-01",
          "enrollmentDate": "2024-01-01T10:30:00Z"
        }
      ]
    }
  ]
}
```

**Files Involved**:
- **Backend**: `backend/server.js` - `/api/nurseries/:nurseryId/enrolled-children` endpoint
- **Frontend Service**: `lib/services/enrolled_children_service_web.dart` - Service for API communication
- **Frontend UI**: `lib/screens/manage_enrolled_screen.dart` - Display component
- **Integration**: `lib/screens/nursery_dashboard.dart` - Quick action button

**UI Components**:
- Summary cards showing total parents and children count
- Parent cards with contact information
- Child items with enrollment status badges
- Color-coded status indicators
- Responsive design for mobile and web

---

### 2. Parent Review & Rating System

**Location**: Parent Profile → Enrollments → "Rate this Nursery" button (for active enrollments)

This feature allows parents to rate and review nurseries where their children are enrolled.

**Features**:
- Submit 5-star ratings for nurseries
- Write optional text comments/reviews
- Update or delete existing reviews
- Real-time nursery rating updates
- View all reviews for a nursery
- User-friendly dialog interface

**Backend Endpoints**:
```
POST /api/reviews
GET /api/nurseries/:nurseryId/reviews
GET /api/reviews/parent/:parentId/nursery/:nurseryId
DELETE /api/reviews/:reviewId
```

**Request Example**:
```json
{
  "nurseryId": "uuid",
  "parentId": "uuid",
  "rating": 4.5,
  "comment": "Great nursery with caring staff!"
}
```

**Response**:
```json
{
  "success": true,
  "review": {
    "id": "uuid",
    "nurseryId": "uuid",
    "parentId": "uuid",
    "rating": 4.5,
    "comment": "Great nursery with caring staff!",
    "createdAt": "2024-01-01T10:30:00Z",
    "updatedAt": "2024-01-01T10:30:00Z"
  },
  "nurseryRating": {
    "averageRating": 4.7,
    "reviewCount": 5
  }
}
```

**Files Involved**:
- **Backend**: `backend/server.js` - `/api/reviews` endpoints
- **Frontend Service**: `lib/services/review_service_web.dart` - API communication service
- **Frontend Widget**: `lib/widgets/rate_nursery_dialog.dart` - Rating dialog component
- **Integration**: `lib/screens/parent_enrollments_screen.dart` - "Rate this Nursery" button

**Features Details**:
- **Star Rating Interface**: 5-star interactive rating system
- **Comment Section**: Optional text field for detailed feedback
- **Update/Delete**: Ability to modify or remove existing reviews
- **Real-time Updates**: Nursery average rating updates immediately after submission
- **Validation**: Ensures ratings are submitted before saving

## State Management

This app uses the `provider` package for state management. The main app state is managed in `AppState` class.

## Original Design

The original design is available at: https://www.figma.com/design/nyqz406RYiODaxJS88uq99/Smart-Farm-Irrigation-App (Note: This was the original design reference from another project)

## License

Private project
