# Backend Structure

This backend has been refactored into a modular structure for better organization and maintainability.

## Directory Structure

```
backend/
├── config/
│   ├── database.js        # PostgreSQL connection pool
│   └── cors.js           # CORS configuration
├── routes/
│   ├── auth.js           # Authentication routes (register, login)
│   ├── users.js          # User management routes
│   ├── parents.js        # Parent-specific routes (children, nurseries)
│   ├── nurseries.js      # Nursery management routes
│   ├── reviews.js        # Review management routes
│   ├── schedule.js       # Daily schedule routes
│   ├── enrollments.js    # Enrollment management routes
│   ├── notifications.js  # Notification routes
│   ├── payments.js       # Payment processing routes
│   └── conversations.js  # Chat/messaging routes
├── utils/
│   └── helpers.js        # Utility functions (hashPassword, createNotification)
├── server.js             # Main server file (now ~52 lines)
├── server_backup.js      # Backup of original server.js
└── package.json
```

## Route Organization

### Authentication Routes (`/api/auth`)
- `POST /register` - Register new user
- `POST /login` - Login user

### User Routes (`/api/users`)
- `GET /:id` - Get user by ID
- `PUT /:id` - Update user

### Parent Routes (`/api/parents`)
- `GET /:parentId/children` - Get children by parent ID
- `GET /:parentId/nurseries` - Get nurseries where parent has enrolled children
- `GET /:parentId/today-program` - Get today's program for parent's children
- `GET /:parentId/nursery-reviews` - Get reviews for nurseries

### Nursery Routes (`/api/nurseries`)
- `POST /` - Create new nursery
- `GET /` - Get all nurseries (with search/filter)
- `GET /:id` - Get nursery by ID
- `GET /:id/reviews` - Get reviews for a nursery
- `POST /:id/reviews` - Add review to nursery
- `GET /owner/:ownerId` - Get nurseries by owner
- `GET /:nurseryId/stats` - Get nursery statistics
- `GET /:nurseryId/enrolled-children` - Get enrolled children
- `GET /:nurseryId/schedule` - Get daily schedule
- `POST /:nurseryId/schedule` - Create schedule item

### Review Routes (`/api/reviews`)
- `POST /` - Create or update review
- `GET /nurseries/:nurseryId/reviews` - Get reviews for nursery
- `GET /parent/:parentId` - Get reviews by parent
- `GET /parent/:parentId/nursery/:nurseryId` - Get specific review
- `PUT /:reviewId` - Update review
- `DELETE /:reviewId` - Delete review

### Schedule Routes (`/api/schedule`)
- `PUT /:scheduleId` - Update schedule item
- `DELETE /:scheduleId` - Delete schedule item

### Enrollment Routes (`/api/enrollments`)
- `POST /` - Create new enrollment
- `GET /nursery/:nurseryId` - Get enrollments by nursery
- `GET /parent/:parentId` - Get enrollments by parent
- `GET /` - Get all enrollments
- `PATCH /:enrollmentId/status` - Update enrollment status
- `POST /:enrollmentId/accept` - Accept enrollment
- `POST /:enrollmentId/reject` - Reject enrollment

### Notification Routes (`/api/notifications`)
- `GET /:userId` - Get user notifications
- `GET /:userId/unread-count` - Get unread count
- `POST /:notificationId/read` - Mark notification as read
- `POST /:userId/read-all` - Mark all as read
- `DELETE /:notificationId` - Delete notification

### Payment Routes (`/api/payments`)
- `POST /sync` - Sync payments
- `GET /parent/:parentId/status` - Get payment status
- `POST /process` - Process payment
- `GET /nursery/:nurseryId` - Get payments by nursery
- `GET /owner/:ownerId` - Get payments by owner
- `GET /nursery/:nurseryId/stats` - Get payment statistics
- `GET /owner/:ownerId/stats` - Get owner payment statistics
- `GET /parent/:parentId/history` - Get payment history

### Conversation Routes (`/api/conversations`)
- `POST /get-or-create` - Get or create conversation
- `GET /user/:userId` - Get user conversations
- `GET /:conversationId/messages` - Get messages
- `POST /:conversationId/messages` - Send message
- `POST /:conversationId/mark-read` - Mark messages as read

## Benefits of This Structure

1. **Better Organization**: Each domain (auth, users, nurseries, etc.) has its own file
2. **Easier Maintenance**: Changes to specific features are isolated to their respective files
3. **Improved Readability**: Reduced from 3128 lines to ~52 lines in main server file
4. **Reusability**: Shared utilities and configs in dedicated folders
5. **Scalability**: Easy to add new routes or modify existing ones
6. **Team Collaboration**: Multiple developers can work on different route files simultaneously

## Original File

The original `server.js` (3128 lines) has been backed up as `server_backup.js` for reference.
