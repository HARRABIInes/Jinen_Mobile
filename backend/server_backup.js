const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const { Pool } = require('pg');
require('dotenv').config();

// Import route files
const nurseriesRouter = require('./routes/nurseries');
const reviewsRouter = require('./routes/reviews');
const scheduleRouter = require('./routes/schedule');
const enrollmentsRouter = require('./routes/enrollments');
const notificationsRouter = require('./routes/notifications');
const paymentsRouter = require('./routes/payments');
const conversationsRouter = require('./routes/conversations');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
// CORS configuration to allow localhost web dev
const corsOptions = {
  origin: (origin, callback) => {
    // Allow requests from localhost (web dev) and from the same origin (mobile)
    if (!origin || origin.includes('localhost') || origin.includes('127.0.0.1')) {
      callback(null, true);
    } else {
      callback(null, true); // For development, allow all; tighten for production
    }
  },
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization'],
  credentials: true,
};
app.use(cors(corsOptions));
app.use(express.json());

// Use route files
app.use('/api/nurseries', nurseriesRouter);
app.use('/api/reviews', reviewsRouter);
app.use('/api/schedule', scheduleRouter);
app.use('/api/enrollments', enrollmentsRouter);
app.use('/api/notifications', notificationsRouter);
app.use('/api/payments', paymentsRouter);
app.use('/api/conversations', conversationsRouter);

// PostgreSQL connection pool
const pool = new Pool({
  host: process.env.DB_HOST,
  port: process.env.DB_PORT,
  database: process.env.DB_NAME,
  user: process.env.DB_USER,
  password: process.env.DB_PASSWORD,
});

// Test database connection
pool.query('SELECT NOW()', (err, res) => {
  if (err) {
    console.error('❌ Database connection failed:', err);
  } else {
    console.log('✅ Database connected successfully');
  }
});

// Hash password using SHA-256
function hashPassword(password) {
  return crypto.createHash('sha256').update(password).digest('hex');
}

// Create notification for a user
async function createNotification(userId, type, title, message, relatedId = null) {
  try {
    const query = `
      INSERT INTO notifications (user_id, type, title, message, related_id)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id
    `;
    const result = await pool.query(query, [userId, type, title, message, relatedId]);
    console.log(`📬 Notification created for user ${userId}: ${type}`);
    return result.rows[0];
  } catch (error) {
    console.error('❌ Error creating notification:', error);
  }
}

// ============== AUTH ENDPOINTS ==============

// Register new user
app.post('/api/auth/register', async (req, res) => {
  const { email, password, name, user_type, phone } = req.body;

  console.log('📝 Register request received:', { email, name, user_type, phone });

  try {
    // Check if email already exists
    const checkQuery = 'SELECT id FROM users WHERE email = $1';
    const checkResult = await pool.query(checkQuery, [email]);

    console.log('🔍 Email check result:', checkResult.rows);

    if (checkResult.rows.length > 0) {
      console.log('❌ Email already exists:', email);
      return res.status(400).json({ 
        success: false, 
        error: 'Email already exists' 
      });
    }

    // Hash password
    const passwordHash = hashPassword(password);

    // Insert new user
    const insertQuery = `
      INSERT INTO users (email, password_hash, user_type, name, phone)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id, email, user_type, name, phone, created_at
    `;
    
    const values = [email, passwordHash, user_type, name, phone || null];
    const result = await pool.query(insertQuery, values);

    const user = result.rows[0];

    console.log('✅ User registered successfully:', user.id);

    res.status(201).json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        type: user.user_type,
        name: user.name,
        phone: user.phone,
        createdAt: user.created_at
      }
    });

  } catch (error) {
    console.error('❌ Error registering user:', error.message);
    console.error('Stack:', error.stack);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to register user',
      details: error.message
    });
  }
});

// Login user
app.post('/api/auth/login', async (req, res) => {
  const { email, password } = req.body;

  try {
    // Hash password
    const passwordHash = hashPassword(password);

    // Find user
    const query = `
      SELECT id, email, user_type, name, phone, created_at
      FROM users
      WHERE email = $1 AND password_hash = $2
    `;
    
    const result = await pool.query(query, [email, passwordHash]);

    if (result.rows.length === 0) {
      return res.status(401).json({ 
        success: false, 
        error: 'Invalid email or password' 
      });
    }

    const user = result.rows[0];

    res.json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        type: user.user_type,
        name: user.name,
        phone: user.phone,
        createdAt: user.created_at
      }
    });

  } catch (error) {
    console.error('Error logging in:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to login' 
    });
  }
});

// Get user by ID
app.get('/api/users/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const query = `
      SELECT id, email, user_type, name, phone, created_at
      FROM users
      WHERE id = $1
    `;
    
    const result = await pool.query(query, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        error: 'User not found' 
      });
    }

    const user = result.rows[0];

    res.json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        type: user.user_type,
        name: user.name,
        phone: user.phone,
        createdAt: user.created_at
      }
    });

  } catch (error) {
    console.error('Error getting user:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to get user' 
    });
  }
});

// Update user
app.put('/api/users/:id', async (req, res) => {
  const { id } = req.params;
  const { name, phone } = req.body;

  try {
    const query = `
      UPDATE users
      SET name = COALESCE($1, name),
          phone = COALESCE($2, phone)
      WHERE id = $3
      RETURNING id, email, user_type, name, phone
    `;
    
    const result = await pool.query(query, [name, phone, id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        error: 'User not found' 
      });
    }

    const user = result.rows[0];

    res.json({
      success: true,
      user: {
        id: user.id,
        email: user.email,
        type: user.user_type,
        name: user.name,
        phone: user.phone
      }
    });

  } catch (error) {
    console.error('Error updating user:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to update user' 
    });
  }
});

// Get children by parent ID
app.get('/api/parents/:parentId/children', async (req, res) => {
  const { parentId } = req.params;

  console.log('👶 Fetching children for parent:', parentId);

  try {
    const query = `
      SELECT 
        c.id,
        c.name,
        c.age,
        c.date_of_birth,
        c.photo_url,
        c.medical_notes,
        c.created_at,
        n.id as nursery_id,
        n.name as nursery_name
      FROM children c
      LEFT JOIN enrollments e ON c.id = e.child_id AND e.status = 'active'
      LEFT JOIN nurseries n ON e.nursery_id = n.id
      WHERE c.parent_id = $1
      ORDER BY c.created_at DESC
    `;
    
    const result = await pool.query(query, [parentId]);

    const children = result.rows.map(row => ({
      id: row.id,
      name: row.name,
      age: row.age,
      dateOfBirth: row.date_of_birth,
      photoUrl: row.photo_url,
      medicalNotes: row.medical_notes,
      createdAt: row.created_at,
      nurseryId: row.nursery_id,
      nurseryName: row.nursery_name
    }));

    console.log(`✅ Found ${children.length} children for parent ${parentId}`);

    res.json({
      success: true,
      count: children.length,
      children
    });

  } catch (error) {
    console.error('❌ Error fetching children:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch children' 
    });
  }
});

// Get nurseries where a parent has enrolled children (with review count)
app.get('/api/parents/:parentId/nurseries', async (req, res) => {
  const { parentId } = req.params;

  try {
    const query = `
      SELECT DISTINCT
        n.id,
        n.name,
        n.description,
        n.address,
        n.city,
        n.postal_code,
        n.phone,
        n.email,
        n.hours,
        n.price_per_month,
        n.total_spots,
        n.available_spots,
        n.age_range,
        n.rating,
        n.photo_url,
        n.review_count,
        COUNT(DISTINCT e.child_id) as childCount
      FROM enrollments e
      JOIN nurseries n ON e.nursery_id = n.id
      JOIN children c ON e.child_id = c.id
      WHERE c.parent_id = $1 AND e.status IN ('active', 'pending', 'completed')
      GROUP BY n.id, n.name, n.description, n.address, n.city, n.postal_code, 
               n.phone, n.email, n.hours, n.price_per_month, n.total_spots, 
               n.available_spots, n.age_range, n.rating, n.photo_url, n.review_count
      ORDER BY n.name ASC
    `;
    
    const result = await pool.query(query, [parentId]);

    const nurseries = result.rows.map(row => ({
      id: row.id,
      name: row.name,
      description: row.description,
      address: row.address,
      city: row.city,
      postalCode: row.postal_code,
      phone: row.phone,
      email: row.email,
      hours: row.hours,
      price: row.price_per_month,
      totalSpots: row.total_spots,
      availableSpots: row.available_spots,
      ageRange: row.age_range,
      rating: row.rating,
      reviewCount: row.review_count,
      photoUrl: row.photo_url,
      childCount: parseInt(row.childCount)
    }));

    res.json({
      success: true,
      parentId: parentId,
      nurseries: nurseries
    });

  } catch (error) {
    console.error('Error fetching parent nurseries:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch nurseries' 
    });
  }
});

// ============== ENROLLMENT ENDPOINTS ==============
// Enrollment routes moved to routes/enrollments.js

// ============== NOTIFICATIONS ENDPOINTS ==============

// Get notifications for a user


// Get nurseries where a parent has enrolled children
app.get('/api/parents/:parentId/nurseries', async (req, res) => {
  const { parentId } = req.params;

  console.log('🏫 Fetching nurseries for parent:', parentId);

  try {
    const query = `
      SELECT DISTINCT
        n.id,
        n.name,
        n.description,
        n.phone,
        n.email,
        n.address,
        n.city,
        n.rating,
        n.available_spots,
        n.total_spots,
        COUNT(DISTINCT c.id) as child_count
      FROM nurseries n
      JOIN enrollments e ON n.id = e.nursery_id
      JOIN children c ON e.child_id = c.id
      WHERE c.parent_id = $1 AND e.status IN ('active', 'pending')
      GROUP BY n.id, n.name, n.description, n.phone, n.email, n.address, n.city, n.rating, n.available_spots, n.total_spots
      ORDER BY n.name ASC
    `;
    
    const result = await pool.query(query, [parentId]);

    console.log('✅ Found', result.rows.length, 'nurseries for parent');

    res.json({
      success: true,
      parentId: parentId,
      nurseries: result.rows.map(row => ({
        id: row.id,
        name: row.name,
        description: row.description,
        phone: row.phone,
        email: row.email,
        address: row.address,
        city: row.city,
        rating: row.rating,
        availableSpots: row.available_spots,
        totalSpots: row.total_spots,
        childCount: row.child_count
      }))
    });

  } catch (error) {
    console.error('❌ Error fetching parent nurseries:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch nurseries'
    });
  }
});

// ============== REVIEWS/RATINGS ENDPOINTS ==============

// Create or update a review for a nursery
app.post('/api/reviews', async (req, res) => {
  const { nurseryId, parentId, rating, comment } = req.body;

  console.log('⭐ Creating review:', { nurseryId, parentId, rating, comment });

  // Validate rating
  if (!rating || rating < 0 || rating > 5) {
    return res.status(400).json({
      success: false,
      error: 'Rating must be between 0 and 5'
    });
  }

  try {
    // Check if review already exists
    const checkQuery = `
      SELECT id FROM reviews
      WHERE nursery_id = $1 AND parent_id = $2
    `;
    const checkResult = await pool.query(checkQuery, [nurseryId, parentId]);

    let result;

    if (checkResult.rows.length > 0) {
      // Update existing review
      const updateQuery = `
        UPDATE reviews
        SET rating = $1, comment = $2, updated_at = CURRENT_TIMESTAMP
        WHERE nursery_id = $3 AND parent_id = $4
        RETURNING id, nursery_id, parent_id, rating, comment, created_at, updated_at
      `;
      result = await pool.query(updateQuery, [rating, comment || null, nurseryId, parentId]);
      console.log('✏️ Review updated');
    } else {
      // Create new review
      const insertQuery = `
        INSERT INTO reviews (nursery_id, parent_id, rating, comment)
        VALUES ($1, $2, $3, $4)
        RETURNING id, nursery_id, parent_id, rating, comment, created_at, updated_at
      `;
      result = await pool.query(insertQuery, [nurseryId, parentId, rating, comment || null]);
      console.log('✅ Review created');
    }

    const review = result.rows[0];

    // Update nursery rating average
    const ratingQuery = `
      SELECT AVG(rating) as avg_rating, COUNT(*) as review_count
      FROM reviews
      WHERE nursery_id = $1
    `;
    const ratingResult = await pool.query(ratingQuery, [nurseryId]);
    const avgRating = parseFloat(ratingResult.rows[0].avg_rating) || 0;
    const reviewCount = parseInt(ratingResult.rows[0].review_count) || 0;

    // Update nursery with new average rating
    await pool.query(
      'UPDATE nurseries SET rating = $1, review_count = $2 WHERE id = $3',
      [avgRating.toFixed(2), reviewCount, nurseryId]
    );

    console.log('📊 Nursery rating updated to:', avgRating.toFixed(2));

    res.status(201).json({
      success: true,
      review: {
        id: review.id,
        nurseryId: review.nursery_id,
        parentId: review.parent_id,
        rating: review.rating,
        comment: review.comment,
        createdAt: review.created_at,
        updatedAt: review.updated_at
      },
      nurseryRating: {
        averageRating: avgRating.toFixed(2),
        reviewCount: reviewCount
      }
    });

  } catch (error) {
    console.error('❌ Error creating/updating review:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to create/update review',
      details: error.message
    });
  }
});

// Get all reviews for a nursery
app.get('/api/nurseries/:nurseryId/reviews', async (req, res) => {
  const { nurseryId } = req.params;

  try {
    const query = `
      SELECT 
        r.id,
        r.rating,
        r.comment,
        r.created_at,
        u.name as parent_name,
        u.id as parent_id
      FROM reviews r
      JOIN users u ON r.parent_id = u.id
      WHERE r.nursery_id = $1
      ORDER BY r.created_at DESC
    `;

    const result = await pool.query(query, [nurseryId]);

    const reviews = result.rows.map(row => ({
      id: row.id,
      rating: row.rating,
      comment: row.comment,
      createdAt: row.created_at,
      parentName: row.parent_name,
      parentId: row.parent_id
    }));

    res.json({
      success: true,
      nurseryId: nurseryId,
      totalReviews: reviews.length,
      reviews: reviews
    });

  } catch (error) {
    console.error('Error fetching reviews:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch reviews'
    });
  }
});

// Get all reviews by parent
app.get('/api/reviews/parent/:parentId', async (req, res) => {
  const { parentId } = req.params;

  console.log('⭐ Fetching reviews for parent:', parentId);

  try {
    const query = `
      SELECT 
        r.id,
        r.rating,
        r.comment,
        r.created_at,
        r.updated_at,
        n.id as nursery_id,
        n.name as nursery_name,
        n.photo_url as nursery_photo
      FROM reviews r
      JOIN nurseries n ON r.nursery_id = n.id
      WHERE r.parent_id = $1
      ORDER BY r.created_at DESC
    `;

    const result = await pool.query(query, [parentId]);

    const reviews = result.rows.map(row => ({
      id: row.id,
      rating: parseFloat(row.rating),
      comment: row.comment,
      createdAt: row.created_at,
      updatedAt: row.updated_at,
      nurseryId: row.nursery_id,
      nurseryName: row.nursery_name,
      nurseryPhoto: row.nursery_photo
    }));

    console.log(`✅ Found ${reviews.length} reviews for parent ${parentId}`);

    res.json({
      success: true,
      count: reviews.length,
      reviews
    });

  } catch (error) {
    console.error('❌ Error fetching parent reviews:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch reviews'
    });
  }
});

// Get a specific review by parent for a nursery
app.get('/api/reviews/parent/:parentId/nursery/:nurseryId', async (req, res) => {
  const { parentId, nurseryId } = req.params;

  try {
    const query = `
      SELECT id, rating, comment, created_at, updated_at
      FROM reviews
      WHERE parent_id = $1 AND nursery_id = $2
    `;

    const result = await pool.query(query, [parentId, nurseryId]);

    if (result.rows.length === 0) {
      return res.json({
        success: true,
        review: null
      });
    }

    const review = result.rows[0];

    res.json({
      success: true,
      review: {
        id: review.id,
        rating: review.rating,
        comment: review.comment,
        createdAt: review.created_at,
        updatedAt: review.updated_at
      }
    });

  } catch (error) {
    console.error('Error fetching review:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to fetch review'
    });
  }
});

// Delete a review
app.delete('/api/reviews/:reviewId', async (req, res) => {
  const { reviewId } = req.params;

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Get review details
    const reviewQuery = 'SELECT nursery_id FROM reviews WHERE id = $1';
    const reviewResult = await client.query(reviewQuery, [reviewId]);

    if (reviewResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        error: 'Review not found'
      });
    }

    const nurseryId = reviewResult.rows[0].nursery_id;

    // Delete review
    await client.query('DELETE FROM reviews WHERE id = $1', [reviewId]);

    // Update nursery rating
    const ratingQuery = `
      SELECT AVG(rating) as avg_rating, COUNT(*) as review_count
      FROM reviews
      WHERE nursery_id = $1
    `;
    const ratingResult = await client.query(ratingQuery, [nurseryId]);
    const avgRating = parseFloat(ratingResult.rows[0].avg_rating) || 0;
    const reviewCount = parseInt(ratingResult.rows[0].review_count) || 0;

    // Update nursery
    await client.query(
      'UPDATE nurseries SET rating = $1, review_count = $2 WHERE id = $3',
      [avgRating.toFixed(2), reviewCount, nurseryId]
    );

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Review deleted successfully',
      nurseryRating: {
        averageRating: avgRating.toFixed(2),
        reviewCount: reviewCount
      }
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error deleting review:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to delete review'
    });
  } finally {
    client.release();
  }
});

// ============== CONVERSATION ENDPOINTS ==============

// Get or create a conversation between parent and nursery owner
app.post('/api/conversations/get-or-create', async (req, res) => {
  const { parentId, nurseryId } = req.body;

  if (!parentId || !nurseryId) {
    return res.status(400).json({ 
      success: false, 
      error: 'parentId and nurseryId are required' 
    });
  }

  try {
    // Check if conversation already exists
    const checkQuery = `
      SELECT c.id, c.parent_id, c.nursery_id, n.name as nursery_name, p.name as parent_name
      FROM conversations c
      LEFT JOIN nurseries n ON c.nursery_id = n.id
      LEFT JOIN users p ON c.parent_id = p.id
      WHERE c.parent_id = $1 AND c.nursery_id = $2
    `;
    const checkResult = await pool.query(checkQuery, [parentId, nurseryId]);

    if (checkResult.rows.length > 0) {
      const conversation = checkResult.rows[0];
      return res.json({
        success: true,
        conversation: {
          id: conversation.id,
          parentId: conversation.parent_id,
          nurseryId: conversation.nursery_id,
          parentName: conversation.parent_name,
          nurseryName: conversation.nursery_name
        }
      });
    }

    // Create new conversation and get nursery/parent info
    const insertQuery = `
      INSERT INTO conversations (parent_id, nursery_id, last_message_at)
      VALUES ($1, $2, CURRENT_TIMESTAMP)
      RETURNING id, parent_id, nursery_id
    `;
    const insertResult = await pool.query(insertQuery, [parentId, nurseryId]);
    const conversation = insertResult.rows[0];

    // Get nursery and parent names
    const infoQuery = `
      SELECT n.name as nursery_name, p.name as parent_name
      FROM nurseries n, users p
      WHERE n.id = $1 AND p.id = $2
    `;
    const infoResult = await pool.query(infoQuery, [nurseryId, parentId]);
    const info = infoResult.rows[0] || { nursery_name: null, parent_name: null };

    res.status(201).json({
      success: true,
      conversation: {
        id: conversation.id,
        parentId: conversation.parent_id,
        nurseryId: conversation.nursery_id,
        parentName: info.parent_name,
        nurseryName: info.nursery_name
      }
    });

  } catch (error) {
    console.error('Error creating conversation:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to create conversation' 
    });
  }
});

// Get all conversations for a user (parent or nursery owner)
app.get('/api/conversations/user/:userId', async (req, res) => {
  const { userId } = req.params;

  try {
    const query = `
      SELECT DISTINCT
        c.id,
        c.parent_id,
        c.nursery_id,
        c.last_message_at,
        p.name as parent_name,
        n.name as nursery_name,
        n.owner_id,
        u.name as owner_name,
        (SELECT content FROM messages WHERE conversation_id = c.id ORDER BY sent_at DESC LIMIT 1) as last_message,
        COUNT(CASE WHEN m.is_read = false AND m.recipient_id = $1 THEN 1 END) as unread_count
      FROM conversations c
      LEFT JOIN users p ON c.parent_id = p.id
      LEFT JOIN nurseries n ON c.nursery_id = n.id
      LEFT JOIN users u ON n.owner_id = u.id
      LEFT JOIN messages m ON c.id = m.conversation_id
      WHERE c.parent_id = $1 OR n.owner_id = $1
      GROUP BY c.id, p.name, n.name, u.name, n.owner_id
      ORDER BY c.last_message_at DESC
    `;

    const result = await pool.query(query, [userId]);

    const conversations = result.rows.map(row => ({
      id: row.id,
      parentId: row.parent_id,
      parentName: row.parent_name,
      nurseryId: row.nursery_id,
      nurseryName: row.nursery_name,
      ownerId: row.owner_id,
      ownerName: row.owner_name,
      lastMessage: row.last_message || 'Nouvelle conversation',
      lastMessageAt: row.last_message_at,
      unreadCount: parseInt(row.unread_count) || 0
    }));

    res.json({
      success: true,
      conversations: conversations
    });

  } catch (error) {
    console.error('Error fetching conversations:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch conversations' 
    });
  }
});

// Get all messages in a conversation
app.get('/api/conversations/:conversationId/messages', async (req, res) => {
  const { conversationId } = req.params;

  try {
    const query = `
      SELECT 
        m.id,
        m.sender_id,
        m.recipient_id,
        m.content,
        m.is_read,
        m.sent_at,
        u.name as sender_name
      FROM messages m
      JOIN users u ON m.sender_id = u.id
      WHERE m.conversation_id = $1
      ORDER BY m.sent_at ASC
    `;

    const result = await pool.query(query, [conversationId]);

    const messages = result.rows.map(row => ({
      id: row.id,
      senderId: row.sender_id,
      senderName: row.sender_name,
      recipientId: row.recipient_id,
      content: row.content,
      isRead: row.is_read,
      sentAt: row.sent_at
    }));

    res.json({
      success: true,
      conversationId: conversationId,
      messages: messages
    });

  } catch (error) {
    console.error('Error fetching messages:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch messages' 
    });
  }
});

// Send a message in a conversation
app.post('/api/conversations/:conversationId/messages', async (req, res) => {
  const { conversationId } = req.params;
  const { senderId, recipientId, content } = req.body;

  if (!senderId || !content) {
    return res.status(400).json({ 
      success: false, 
      error: 'senderId and content are required' 
    });
  }

  try {
    // Get conversation details to determine recipient
    let actualRecipientId = recipientId;
    
    if (!actualRecipientId) {
      // Fetch conversation to determine the other user
      const convQuery = `
        SELECT parent_id, nursery_id FROM conversations WHERE id = $1
      `;
      const convResult = await pool.query(convQuery, [conversationId]);
      
      if (convResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          error: 'Conversation not found'
        });
      }
      
      const conversation = convResult.rows[0];
      
      // Determine recipient: if sender is parent, recipient is owner; otherwise vice versa
      const parentQuery = `
        SELECT owner_id FROM nurseries WHERE id = $1
      `;
      const parentResult = await pool.query(parentQuery, [conversation.nursery_id]);
      
      if (parentResult.rows.length === 0) {
        return res.status(404).json({
          success: false,
          error: 'Nursery not found'
        });
      }
      
      const nurseryOwnerId = parentResult.rows[0].owner_id;
      actualRecipientId = senderId === conversation.parent_id ? nurseryOwnerId : conversation.parent_id;
    }

    const query = `
      INSERT INTO messages (conversation_id, sender_id, recipient_id, content)
      VALUES ($1, $2, $3, $4)
      RETURNING id, sender_id, recipient_id, content, is_read, sent_at
    `;

    const result = await pool.query(query, [conversationId, senderId, actualRecipientId, content]);
    const message = result.rows[0];

    // Update conversation last_message_at
    await pool.query(
      'UPDATE conversations SET last_message_at = CURRENT_TIMESTAMP WHERE id = $1',
      [conversationId]
    );

    // Create notification for recipient (wrapped in try-catch so it doesn't fail the message sending)
    try {
      const senderQuery = `
        SELECT name FROM users WHERE id = $1
      `;
      const senderResult = await pool.query(senderQuery, [senderId]);
      const senderName = senderResult.rows[0]?.name || 'Quelqu\'un';

      const notificationQuery = `
        INSERT INTO notifications (user_id, title, message, type, related_id)
        VALUES ($1, $2, $3, $4, $5)
      `;
      await pool.query(notificationQuery, [
        actualRecipientId,
        `Nouveau message de ${senderName}`,
        `${senderName}: ${content.substring(0, 100)}${content.length > 100 ? '...' : ''}`,
        'message',
        conversationId
      ]);
      console.log('✅ Notification created for message');
    } catch (notificationError) {
      console.warn('⚠️ Could not create notification:', notificationError.message);
      // Don't fail the whole request if notification fails
    }

    res.status(201).json({
      success: true,
      message: {
        id: message.id,
        senderId: message.sender_id,
        recipientId: message.recipient_id,
        content: message.content,
        isRead: message.is_read,
        sentAt: message.sent_at
      }
    });

  } catch (error) {
    console.error('Error sending message:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to send message' 
    });
  }
});

// Mark messages as read in a conversation
app.post('/api/conversations/:conversationId/mark-read', async (req, res) => {
  const { conversationId } = req.params;
  const { userId } = req.body;

  if (!userId) {
    return res.status(400).json({ 
      success: false, 
      error: 'userId is required' 
    });
  }

  try {
    const query = `
      UPDATE messages
      SET is_read = true
      WHERE conversation_id = $1 AND recipient_id = $2 AND is_read = false
      RETURNING id
    `;

    await pool.query(query, [conversationId, userId]);

    res.json({
      success: true,
      message: 'Messages marked as read'
    });

  } catch (error) {
    console.error('Error marking messages as read:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to mark messages as read' 
    });
  }
});

// ============== PARENT PROGRAM & REVIEWS ENDPOINTS ==============

// Get today's program for parent's enrolled nursery
app.get('/api/parents/:parentId/today-program', async (req, res) => {
  try {
    const { parentId } = req.params;

    // First, get the nursery where the parent has enrolled children
    const nurseryQuery = `
      SELECT DISTINCT n.id, n.name
      FROM nurseries n
      JOIN enrollments e ON n.id = e.nursery_id
      JOIN children c ON e.child_id = c.id
      WHERE c.parent_id = $1 AND e.status IN ('pending', 'active')
      LIMIT 1
    `;
    
    const nurseryResult = await pool.query(nurseryQuery, [parentId]);
    
    if (nurseryResult.rows.length === 0) {
      return res.json({
        success: true,
        program: [],
        nurseryName: null
      });
    }

    const nursery = nurseryResult.rows[0];

    // Get today's schedule for this nursery
    const today = new Date().toISOString().split('T')[0];
    const scheduleQuery = `
      SELECT 
        id,
        time_slot,
        activity_name,
        description,
        participant_count,
        created_at
      FROM daily_schedule
      WHERE nursery_id = $1 
        AND DATE(created_at) = $2
      ORDER BY time_slot ASC
    `;
    
    const scheduleResult = await pool.query(scheduleQuery, [nursery.id, today]);

    res.json({
      success: true,
      program: scheduleResult.rows,
      nurseryName: nursery.name
    });

  } catch (error) {
    console.error('Error getting today program:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get program'
    });
  }
});

// Get recent reviews for parent's enrolled nursery
app.get('/api/parents/:parentId/nursery-reviews', async (req, res) => {
  try {
    const { parentId } = req.params;

    // First, get the nursery where the parent has enrolled children
    const nurseryQuery = `
      SELECT DISTINCT n.id
      FROM nurseries n
      JOIN enrollments e ON n.id = e.nursery_id
      JOIN children c ON e.child_id = c.id
      WHERE c.parent_id = $1 AND e.status IN ('pending', 'active')
      LIMIT 1
    `;
    
    const nurseryResult = await pool.query(nurseryQuery, [parentId]);
    
    if (nurseryResult.rows.length === 0) {
      return res.json({
        success: true,
        reviews: []
      });
    }

    const nurseryId = nurseryResult.rows[0].id;

    // Get the 2 most recent reviews for this nursery
    const reviewsQuery = `
      SELECT 
        r.id,
        r.rating,
        r.comment,
        r.created_at,
        u.name as parent_name
      FROM reviews r
      JOIN users u ON r.parent_id = u.id
      WHERE r.nursery_id = $1
      ORDER BY r.created_at DESC
      LIMIT 2
    `;
    
    const reviewsResult = await pool.query(reviewsQuery, [nurseryId]);

    res.json({
      success: true,
      reviews: reviewsResult.rows
    });

  } catch (error) {
    console.error('Error getting nursery reviews:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get reviews'
    });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📝 API endpoints available at http://localhost:${PORT}/api`);
});
