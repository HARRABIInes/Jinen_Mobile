# JINEN - Application de Gestion de Garderie (Flutter)

A comprehensive Flutter application for finding, rating, and managing daycare/nursery services with integrated messaging system between parents and nursery owners.

This project was migrated from a React/Vite application to Flutter for cross-platform support (Android, iOS, Web, Windows, macOS, Linux).

## 🎯 Features

- **Parent Features**:
  - Search and browse nurseries
  - Rate and review nurseries
  - Manage child enrollments
  - Contact nurseries via messaging
  - View nursery details and ratings

- **Nursery Owner Features**:
  - Manage nursery profile
  - View enrolled children and parent information
  - Contact parents via messaging
  - Accept/manage enrollment requests
  - View performance metrics and ratings

- **Messaging System**:
  - Real-time conversations between parents and nursery owners
  - Create conversations automatically when needed
  - Message history and unread counts
  - Integrated chat interface

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

---

# 🔌 API INTEGRATION & MESSAGING SYSTEM

## Architecture Overview

The application uses a **3-tier architecture**:

```
┌─────────────────────────┐
│   Frontend (Flutter)    │  - User Interface
│   (Web/Android/iOS)     │  - Business Logic
└────────────┬────────────┘
             │ HTTP REST APIs
┌────────────▼────────────┐
│   Backend (Node.js)     │  - API Endpoints
│   Express Server        │  - Business Logic
│   Port: 3000            │
└────────────┬────────────┘
             │ Database Queries
┌────────────▼────────────┐
│  Database (PostgreSQL)  │  - Data Storage
│  Port: 5432             │  - Conversations
└─────────────────────────┘  - Messages
                              - Users & Nurseries
```

## 📨 Messaging System (Conversations API)

### Overview

The messaging system allows **Parents** and **Nursery Owners** to communicate directly through conversations.

### How It Works

1. **Conversation Creation**:
   - When a parent clicks "Contacter" on a nursery → App calls backend to create/get conversation
   - When a nursery owner clicks "Contacter ce parent" → App calls backend to create/get conversation
   - Backend checks if conversation exists, creates if not

2. **Message Flow**:
   - User sends message via ChatScreen
   - Message sent to backend API
   - Backend stores in database
   - Other user receives message in real-time (via polling in current implementation)

3. **Conversation List**:
   - Each user (parent or owner) sees their conversations
   - Shows last message, timestamp, and unread count
   - Sorted by most recent

### Database Schema

#### `conversations` Table
```sql
CREATE TABLE conversations (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  parent_id UUID NOT NULL REFERENCES users(id),
  nursery_id UUID NOT NULL REFERENCES nurseries(id),
  last_message_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
  created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

#### `messages` Table
```sql
CREATE TABLE messages (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  conversation_id UUID NOT NULL REFERENCES conversations(id),
  sender_id UUID NOT NULL REFERENCES users(id),
  recipient_id UUID NOT NULL REFERENCES users(id),
  content TEXT NOT NULL,
  is_read BOOLEAN DEFAULT FALSE,
  sent_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
);
```

---

## 🔌 API Endpoints Reference

### **Conversation Endpoints** (Base URL: `http://localhost:3000/api`)

#### 1. **Create or Get Conversation**
```
POST /conversations/get-or-create
```

**Purpose**: Creates a new conversation between parent and nursery or retrieves existing one

**Request Body**:
```json
{
  "parentId": "uuid",
  "nurseryId": "uuid"
}
```

**Response** (201 Created or 200 OK):
```json
{
  "success": true,
  "conversation": {
    "id": "conv-uuid",
    "parentId": "parent-uuid",
    "nurseryId": "nursery-uuid",
    "parentName": "John Doe",
    "nurseryName": "Happy Kids Nursery"
  }
}
```

**Flow**:
1. Frontend (parent or owner) clicks "Contacter"
2. Sends POST request with parentId and nurseryId
3. Backend checks if conversation exists
4. If exists → returns existing conversation
5. If not → creates new conversation and returns it
6. Frontend navigates to ChatScreen with conversation ID

**Code Location**:
- Backend: `backend/server.js` (lines 2265-2330)
- Frontend: `lib/services/conversation_service_web.dart` (lines 8-30)
- UI Trigger: `lib/screens/chat_list_screen.dart` (line 47)

---

#### 2. **Get All Conversations for User**
```
GET /conversations/user/:userId
```

**Purpose**: Fetches all conversations for a user (parent or nursery owner)

**Parameters**:
- `userId`: UUID of the user (parent_id or owner_id)

**Response** (200 OK):
```json
{
  "success": true,
  "conversations": [
    {
      "id": "conv-uuid",
      "parentId": "parent-uuid",
      "parentName": "John Doe",
      "nurseryId": "nursery-uuid",
      "nurseryName": "Happy Kids Nursery",
      "ownerId": "owner-uuid",
      "ownerName": "Sarah Smith",
      "lastMessage": "Thanks for your message!",
      "lastMessageAt": "2024-01-03T10:30:00Z",
      "unreadCount": 2
    }
  ]
}
```

**Key Fields**:
- `lastMessage`: Last message content (for display in list)
- `unreadCount`: Number of unread messages for this user
- `lastMessageAt`: Timestamp for sorting conversations

**Code Location**:
- Backend: `backend/server.js` (lines 2332-2390)
- Frontend: `lib/services/conversation_service_web.dart` (lines 32-45)
- UI Usage: `lib/screens/chat_list_screen.dart` (line 90)

---

#### 3. **Get Messages in Conversation**
```
GET /conversations/:conversationId/messages
```

**Purpose**: Fetches all messages in a specific conversation

**Parameters**:
- `conversationId`: UUID of the conversation

**Response** (200 OK):
```json
{
  "success": true,
  "messages": [
    {
      "id": "msg-uuid",
      "conversationId": "conv-uuid",
      "senderId": "user-uuid",
      "recipientId": "user-uuid",
      "content": "Hello, I have a question...",
      "isRead": true,
      "sentAt": "2024-01-03T10:30:00Z"
    }
  ]
}
```

**Flow**:
1. ChatScreen loads → calls this endpoint
2. Fetches all messages for the conversation
3. Displays them in chronological order
4. Automatically marks messages as read

**Code Location**:
- Backend: `backend/server.js` (lines 2392-2415)
- Frontend: `lib/services/conversation_service_web.dart` (lines 47-62)

---

#### 4. **Send Message**
```
POST /conversations/:conversationId/messages
```

**Purpose**: Sends a new message in a conversation

**Parameters**:
- `conversationId`: UUID of the conversation

**Request Body**:
```json
{
  "senderId": "uuid",
  "recipientId": "uuid",
  "content": "This is my message text"
}
```

**Response** (201 Created):
```json
{
  "success": true,
  "message": {
    "id": "msg-uuid",
    "conversationId": "conv-uuid",
    "senderId": "user-uuid",
    "recipientId": "user-uuid",
    "content": "This is my message text",
    "isRead": false,
    "sentAt": "2024-01-03T10:30:00Z"
  }
}
```

**Flow**:
1. User types message in ChatScreen
2. Clicks send button
3. Frontend sends POST request
4. Backend stores message in database
5. Updates `last_message_at` in conversations table
6. Returns message object
7. Frontend adds message to UI

**Code Location**:
- Backend: `backend/server.js` (lines 2417-2450)
- Frontend: `lib/services/conversation_service_web.dart` (lines 64-83)

---

#### 5. **Mark Messages as Read**
```
POST /conversations/:conversationId/mark-read
```

**Purpose**: Marks all messages received by a user as read

**Parameters**:
- `conversationId`: UUID of the conversation

**Request Body**:
```json
{
  "userId": "uuid"
}
```

**Response** (200 OK):
```json
{
  "success": true,
  "updatedCount": 3
}
```

**Flow**:
1. ChatScreen loads messages
2. Automatically calls this endpoint
3. Marks all messages from other user as read
4. Updates unread count in conversation list

**Code Location**:
- Backend: `backend/server.js` (lines 2452-2480)
- Frontend: `lib/services/conversation_service_web.dart` (lines 85-102)

---

## 🎨 Frontend Services

### **ConversationServiceWeb** (`lib/services/conversation_service_web.dart`)

This service abstracts all API calls for conversations. It's a static class with methods that handle HTTP requests.

**Methods**:
```dart
// Create or get conversation
static Future<Map<String, dynamic>?> getOrCreateConversation({
  required String parentId,
  required String nurseryId,
})

// Get all conversations for a user
static Future<List<Map<String, dynamic>>> getConversations(String userId)

// Get all messages in a conversation
static Future<List<Map<String, dynamic>>> getMessages(String conversationId)

// Send a message
static Future<Map<String, dynamic>?> sendMessage({
  required String conversationId,
  required String senderId,
  required String recipientId,
  required String content,
})

// Mark messages as read
static Future<bool> markMessagesAsRead({
  required String conversationId,
  required String userId,
})
```

**Base URL**: `http://localhost:3000/api`

**Error Handling**: All methods include try-catch blocks and print debug logs starting with 💬, ✅, or ❌

---

## 🖥️ Frontend UI Integration

### **Chat List Screen** (`lib/screens/chat_list_screen.dart`)

**Purpose**: Displays list of all conversations for current user

**Features**:
- Shows all conversations sorted by most recent
- Displays last message preview
- Shows unread message count
- Auto-creates conversation when visiting from "Contacter" button

**Constructor**:
```dart
ChatListScreen({
  required String userId,           // Current user's ID
  required String userType,         // 'parent' or 'directeur'
  String? targetNurseryId,         // For creating new conversation
  String? targetParentId,          // For nursery owner contacting parent
})
```

**Flow When "Contacter" Button Clicked**:
1. Parent clicks "Contacter" on nursery card
2. Parent enrollments page calls:
```dart
Navigator.push(
  context,
  MaterialPageRoute(
    builder: (context) => ChatListScreen(
      userId: parentId,
      userType: 'parent',
      targetNurseryId: nurseryId,  // ← This triggers conversation creation
    ),
  ),
);
```
3. ChatListScreen's `_startNewConversation()` method:
   - Calls `ConversationServiceWeb.getOrCreateConversation()`
   - Backend creates/fetches conversation
   - Automatically navigates to ChatScreen

---

### **Chat Screen** (`lib/screens/chat_screen.dart`)

**Purpose**: Displays messages in a conversation and allows sending new messages

**Parameters**:
- `conversationId`: ID of the conversation
- `userId`: Current user's ID
- `autreUtilisateurNom`: Name of the other person in conversation

**Features**:
- Displays all messages in chronological order
- Distinguishes sent vs received messages with different styling
- Auto-loads messages when screen opens
- Sends message with backend API call
- Auto-refreshes to get new messages

---

## 🎯 User Flows

### **Flow 1: Parent Contacting Nursery from Home**

```
Parent Dashboard
    ↓
Click "Contacter" button on nursery card
    ↓
parent_dashboard.dart: _contactNursery()
    ↓
Navigate to ChatListScreen(
  userId: parentId,
  userType: 'parent',
  targetNurseryId: nurseryId
)
    ↓
ChatListScreen._startNewConversation()
    ↓
ConversationServiceWeb.getOrCreateConversation(parentId, nurseryId)
    ↓
POST /api/conversations/get-or-create
    ↓
Backend: Check if conversation exists
  - If exists: Return it
  - If not: Create new one
    ↓
Backend returns conversation with nurseryName
    ↓
ChatListScreen navigates to ChatScreen
    ↓
ChatScreen displays messages and allows sending
```

### **Flow 2: Parent Contacting Nursery from Enrollments**

```
Mes Inscriptions (Parent Enrollments)
    ↓
Click "Contacter" button on enrollment card
    ↓
parent_enrollments_screen.dart: onPressed()
    ↓
Navigate to ChatListScreen(
  userId: parentId,
  userType: 'parent',
  targetNurseryId: nurseryId
)
    ↓
[Same as Flow 1 from here...]
```

### **Flow 3: Nursery Owner Contacting Parent**

```
Gérer mes inscriptions (Manage Enrolled)
    ↓
Click "Contacter ce parent" button
    ↓
manage_enrolled_screen.dart: onPressed()
    ↓
Navigate to ChatListScreen(
  userId: ownerId,
  userType: 'directeur',
  targetNurseryId: nurseryId,
  targetParentId: parentId  // ← Different!
)
    ↓
ChatListScreen._startNewConversation()
    ↓
ConversationServiceWeb.getOrCreateConversation(parentId, nurseryId)
    ↓
POST /api/conversations/get-or-create
    ↓
Backend: Check if conversation exists
    ↓
Backend returns conversation with parentName
    ↓
ChatListScreen navigates to ChatScreen
    ↓
ChatScreen displays messages and allows sending
```

---

## 🔍 Debug Logging

All services include detailed logging for debugging:

**Backend Logs** (Docker):
```bash
docker logs nursery_backend --tail 50
```

**Frontend Logs** (Browser Console):
- 💬 = Conversation action initiated
- ✅ = Success
- ❌ = Error

Example console output:
```
💬 Creating/fetching conversation with nursery: 5705ad05-4d9d-487e-8ab9-48c318e37f2a
✅ Conversation created/fetched: conv-uuid-12345
📋 Loading all conversations for user: parent-uuid
```

---

## 🚀 Running the Full System

### **1. Start Backend**
```bash
docker restart nursery_backend
```

Verify it's running:
```bash
docker ps | findstr nursery_backend
docker logs nursery_backend --tail 10
```

### **2. Start Frontend**
```bash
flutter run -d chrome
```

### **3. Test the Messaging System**

**As Parent**:
1. Log in with parent credentials
2. Go to "Mes Inscriptions"
3. Click "Contacter" on any enrollment
4. Type a message and send

**As Nursery Owner**:
1. Log in with nursery credentials
2. Go to "Gérer mes inscriptions"
3. Click "Contacter ce parent"
4. Type a message and send

---

## 📊 Database Relationships

```
users
  ├── id (UUID)
  ├── name
  ├── email
  ├── role (parent/owner)
  └── ...

nurseries
  ├── id (UUID)
  ├── name
  ├── owner_id (→ users.id)
  └── ...

conversations
  ├── id (UUID)
  ├── parent_id (→ users.id)
  ├── nursery_id (→ nurseries.id)
  ├── last_message_at
  └── created_at

messages
  ├── id (UUID)
  ├── conversation_id (→ conversations.id)
  ├── sender_id (→ users.id)
  ├── recipient_id (→ users.id)
  ├── content
  ├── is_read
  └── sent_at
```

---

## ⚠️ Common Issues & Solutions

### **Issue**: "Impossible de créer une conversation"
**Cause**: Backend conversation endpoint is down or returning errors
**Solution**:
```bash
docker logs nursery_backend --tail 50
docker restart nursery_backend
```

### **Issue**: Messages not appearing
**Cause**: Browser cache or API not returning data
**Solution**:
1. Hard refresh browser (Ctrl+Shift+R)
2. Check network tab in DevTools
3. Verify backend is returning messages

### **Issue**: Unread count not updating
**Cause**: `markMessagesAsRead` endpoint not called or failing
**Solution**: Check console logs for API errors

---

## 📁 File Structure for Messaging

```
lib/
  ├── screens/
  │   ├── chat_list_screen.dart       ← Conversation list
  │   ├── chat_screen.dart            ← Individual chat
  │   ├── parent_dashboard.dart       ← "Contacter" button
  │   ├── parent_enrollments_screen.dart
  │   └── manage_enrolled_screen.dart ← "Contacter ce parent"
  │
  ├── services/
  │   ├── conversation_service_web.dart ← API calls
  │   └── [other services]
  │
  └── models/
      ├── conversation.dart
      ├── message.dart
      └── [other models]

backend/
  └── server.js
      ├── Line 2265-2330: POST /conversations/get-or-create
      ├── Line 2332-2390: GET /conversations/user/:userId
      ├── Line 2392-2415: GET /conversations/:conversationId/messages
      ├── Line 2417-2450: POST /conversations/:conversationId/messages
      └── Line 2452-2480: POST /conversations/:conversationId/mark-read
```

---

## 🔐 Future Enhancements

- [ ] Real-time messaging with WebSockets instead of polling
- [ ] Message search and filtering
- [ ] Message attachments (images, files)
- [ ] Typing indicators
- [ ] User presence status
- [ ] Message reactions/emojis
- [ ] Voice messages
- [ ] Video/audio calls

---
