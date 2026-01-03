const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const { Pool } = require('pg');
require('dotenv').config();

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

// ============== NURSERY ENDPOINTS ==============

// Create new nursery
app.post('/api/nurseries', async (req, res) => {
  const {
    owner_id,
    name,
    description,
    address,
    city,
    postal_code,
    latitude,
    longitude,
    phone,
    email,
    hours,
    price_per_month,
    total_spots,
    age_range,
    photo_url,
    facilities,
    activities
  } = req.body;

  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    // Insert nursery
    const nurseryQuery = `
      INSERT INTO nurseries (
        owner_id, name, description, address, city, postal_code,
        latitude, longitude, phone, email, hours, price_per_month,
        total_spots, available_spots, age_range, photo_url
      )
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $13, $14, $15)
      RETURNING id, owner_id, name, description, address, city, postal_code,
                phone, email, hours, price_per_month, total_spots, available_spots,
                age_range, rating, photo_url, created_at
    `;
    
    const nurseryValues = [
      owner_id, name, description || null, address, city, postal_code || null,
      latitude || null, longitude || null, phone || null, email || null,
      hours || null, price_per_month, total_spots, age_range || null, photo_url || null
    ];
    
    const nurseryResult = await client.query(nurseryQuery, nurseryValues);
    const nursery = nurseryResult.rows[0];

    // Insert facilities
    if (facilities && facilities.length > 0) {
      const facilityQuery = `
        INSERT INTO nursery_facilities (nursery_id, facility_name)
        VALUES ($1, $2)
      `;
      
      for (const facility of facilities) {
        await client.query(facilityQuery, [nursery.id, facility]);
      }
    }

    // Insert activities
    if (activities && activities.length > 0) {
      const activityQuery = `
        INSERT INTO nursery_activities (nursery_id, activity_name)
        VALUES ($1, $2)
      `;
      
      for (const activity of activities) {
        await client.query(activityQuery, [nursery.id, activity]);
      }
    }

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      nursery: {
        id: nursery.id,
        ownerId: nursery.owner_id,
        name: nursery.name,
        description: nursery.description,
        address: nursery.address,
        city: nursery.city,
        postalCode: nursery.postal_code,
        phone: nursery.phone,
        email: nursery.email,
        hours: nursery.hours,
        price: nursery.price_per_month,
        totalSpots: nursery.total_spots,
        availableSpots: nursery.available_spots,
        ageRange: nursery.age_range,
        rating: nursery.rating,
        photoUrl: nursery.photo_url,
        facilities: facilities || [],
        activities: activities || [],
        createdAt: nursery.created_at
      }
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error creating nursery:', error);
    console.error('Error details:', error.message);
    console.error('Error stack:', error.stack);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to create nursery',
      details: error.message 
    });
  } finally {
    client.release();
  }
});

// Get all nurseries with search filters
app.get('/api/nurseries', async (req, res) => {
  const { city, max_price, min_rating, min_spots } = req.query;

  try {
    let query = `
      SELECT n.id, n.owner_id, n.name, n.description, n.address, n.city,
             n.postal_code, n.phone, n.email, n.hours, n.price_per_month,
             n.total_spots, n.available_spots, n.age_range, n.rating, n.photo_url,
             n.review_count,
             u.name as owner_name,
             COALESCE(
               (SELECT json_agg(facility_name) FROM nursery_facilities WHERE nursery_id = n.id),
               '[]'
             ) as facilities,
             COALESCE(
               (SELECT json_agg(activity_name) FROM nursery_activities WHERE nursery_id = n.id),
               '[]'
             ) as activities
      FROM nurseries n
      LEFT JOIN users u ON n.owner_id = u.id
      WHERE 1=1
    `;
    
    const values = [];
    let paramIndex = 1;

    if (city) {
      query += ` AND LOWER(n.city) = LOWER($${paramIndex})`;
      values.push(city);
      paramIndex++;
    }

    if (max_price) {
      query += ` AND n.price_per_month <= $${paramIndex}`;
      values.push(parseFloat(max_price));
      paramIndex++;
    }

    if (min_rating) {
      query += ` AND n.rating >= $${paramIndex}`;
      values.push(parseFloat(min_rating));
      paramIndex++;
    }

    if (min_spots) {
      query += ` AND n.available_spots >= $${paramIndex}`;
      values.push(parseInt(min_spots));
      paramIndex++;
    }

    query += ' ORDER BY n.rating DESC, n.created_at DESC';

    const result = await pool.query(query, values);

    const nurseries = result.rows.map(row => ({
      id: row.id,
      ownerId: row.owner_id,
      ownerName: row.owner_name,
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
      facilities: row.facilities,
      activities: row.activities
    }));

    res.json({
      success: true,
      nurseries
    });

  } catch (error) {
    console.error('Error fetching nurseries:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch nurseries' 
    });
  }
});

// Get nursery by ID
app.get('/api/nurseries/:id', async (req, res) => {
  const { id } = req.params;

  try {
    const query = `
      SELECT n.id, n.owner_id, n.name, n.description, n.address, n.city,
             n.postal_code, n.phone, n.email, n.hours, n.price_per_month,
             n.total_spots, n.available_spots, n.age_range, n.rating, n.photo_url,
             u.name as owner_name,
             COALESCE(
               (SELECT json_agg(facility_name) FROM nursery_facilities WHERE nursery_id = n.id),
               '[]'
             ) as facilities,
             COALESCE(
               (SELECT json_agg(activity_name) FROM nursery_activities WHERE nursery_id = n.id),
               '[]'
             ) as activities
      FROM nurseries n
      LEFT JOIN users u ON n.owner_id = u.id
      WHERE n.id = $1
    `;
    
    const result = await pool.query(query, [id]);

    if (result.rows.length === 0) {
      return res.status(404).json({ 
        success: false, 
        error: 'Nursery not found' 
      });
    }

    const row = result.rows[0];
    const nursery = {
      id: row.id,
      ownerId: row.owner_id,
      ownerName: row.owner_name,
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
      photoUrl: row.photo_url,
      facilities: row.facilities,
      activities: row.activities
    };

    res.json({
      success: true,
      nursery
    });

  } catch (error) {
    console.error('Error fetching nursery:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch nursery' 
    });
  }
});

// Get reviews for a nursery
app.get('/api/nurseries/:id/reviews', async (req, res) => {
  const { id } = req.params;

  try {
    const query = `
      SELECT r.id, r.nursery_id, r.parent_id, r.rating, r.comment, r.created_at,
             u.name as parent_name
      FROM reviews r
      LEFT JOIN users u ON r.parent_id = u.id
      WHERE r.nursery_id = $1
      ORDER BY r.created_at DESC
    `;

    const result = await pool.query(query, [id]);

    res.json({
      success: true,
      reviews: result.rows
    });
  } catch (error) {
    console.error('Error fetching reviews:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch reviews' });
  }
});

// Post a review for a nursery
app.post('/api/nurseries/:id/reviews', async (req, res) => {
  const { id } = req.params; // nursery id
  const { parentId, rating, comment } = req.body;

  if (!parentId || rating == null) {
    return res.status(400).json({ success: false, error: 'parentId and rating are required' });
  }

  try {
    const insert = `
      INSERT INTO reviews (nursery_id, parent_id, rating, comment)
      VALUES ($1, $2, $3, $4)
      RETURNING id, nursery_id, parent_id, rating, comment, created_at
    `;

    const result = await pool.query(insert, [id, parentId, parseFloat(rating), comment || null]);

    res.status(201).json({ success: true, review: result.rows[0] });
  } catch (error) {
    console.error('Error creating review:', error);
    res.status(500).json({ success: false, error: 'Failed to create review' });
  }
});

// Update a review (only parent who created it should update)
app.put('/api/reviews/:reviewId', async (req, res) => {
  const { reviewId } = req.params;
  const { parentId, rating, comment } = req.body;

  if (!parentId || rating == null) {
    return res.status(400).json({ success: false, error: 'parentId and rating are required' });
  }

  try {
    // Verify ownership
    const check = await pool.query('SELECT parent_id FROM reviews WHERE id = $1', [reviewId]);
    if (check.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Review not found' });
    }
    if (check.rows[0].parent_id !== parentId) {
      return res.status(403).json({ success: false, error: 'Not allowed to edit this review' });
    }

    const update = `
      UPDATE reviews SET rating = $1, comment = $2, updated_at = CURRENT_TIMESTAMP
      WHERE id = $3 RETURNING id, nursery_id, parent_id, rating, comment, updated_at
    `;
    const result = await pool.query(update, [parseFloat(rating), comment || null, reviewId]);
    res.json({ success: true, review: result.rows[0] });
  } catch (error) {
    console.error('Error updating review:', error);
    res.status(500).json({ success: false, error: 'Failed to update review' });
  }
});

// Delete a review (only parent who created it should delete)
app.delete('/api/reviews/:reviewId', async (req, res) => {
  const { reviewId } = req.params;
  const { parentId } = req.body;

  if (!parentId) return res.status(400).json({ success: false, error: 'parentId required' });

  try {
    const check = await pool.query('SELECT parent_id FROM reviews WHERE id = $1', [reviewId]);
    if (check.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Review not found' });
    }
    if (check.rows[0].parent_id !== parentId) {
      return res.status(403).json({ success: false, error: 'Not allowed to delete this review' });
    }

    await pool.query('DELETE FROM reviews WHERE id = $1', [reviewId]);
    res.json({ success: true });
  } catch (error) {
    console.error('Error deleting review:', error);
    res.status(500).json({ success: false, error: 'Failed to delete review' });
  }
});

// Get nurseries by owner ID
app.get('/api/nurseries/owner/:ownerId', async (req, res) => {
  const { ownerId } = req.params;

  try {
    const query = `
      SELECT n.id, n.owner_id, n.name, n.description, n.address, n.city,
             n.postal_code, n.phone, n.email, n.hours, n.price_per_month,
             n.total_spots, n.available_spots, n.age_range, n.rating, n.photo_url,
             n.staff_count, n.review_count,
             COALESCE(
               (SELECT json_agg(facility_name) FROM nursery_facilities WHERE nursery_id = n.id),
               '[]'
             ) as facilities,
             COALESCE(
               (SELECT json_agg(activity_name) FROM nursery_activities WHERE nursery_id = n.id),
               '[]'
             ) as activities
      FROM nurseries n
      WHERE n.owner_id = $1
      ORDER BY n.created_at DESC
    `;
    
    const result = await pool.query(query, [ownerId]);

    const nurseries = result.rows.map(row => ({
      id: row.id,
      ownerId: row.owner_id,
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
      photoUrl: row.photo_url,
      staff: row.staff_count || 0,
      reviewCount: row.review_count || 0,
      facilities: row.facilities,
      activities: row.activities
    }));

    res.json({
      success: true,
      nurseries
    });

  } catch (error) {
    console.error('Error fetching nurseries by owner:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch nurseries by owner' 
    });
  }
});

// ============== ENROLLMENT ENDPOINTS ==============

// Create child and enrollment
app.post('/api/enrollments', async (req, res) => {
  const { 
    childName, 
    birthDate, 
    parentName, 
    parentPhone, 
    nurseryId, 
    startDate, 
    notes,
    parentId 
  } = req.body;

  console.log('📝 Enrollment request:', { childName, parentId, nurseryId });

  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    // 1. Use provided parentId OR create a new parent
    let parentIdToUse = parentId;
    
    if (!parentIdToUse) {
      // Create a simple user account for the parent
      const parentQuery = `
        INSERT INTO users (email, password_hash, user_type, name, phone)
        VALUES ($1, $2, 'parent', $3, $4)
        RETURNING id
      `;
      // Generate a temporary email and password
      const tempEmail = `parent_${Date.now()}@temp.com`;
      const tempPassword = 'temp123'; // In production, this should be handled differently
      const passwordHash = require('crypto').createHash('sha256').update(tempPassword).digest('hex');
      
      const parentResult = await client.query(parentQuery, [tempEmail, passwordHash, parentName, parentPhone]);
      parentIdToUse = parentResult.rows[0].id;
      console.log('✅ New parent created:', parentIdToUse);
    } else {
      console.log('✅ Using existing parent:', parentIdToUse);
    }

    // 2. Calculate age from birth date
    const birthDateObj = new Date(birthDate);
    const age = Math.floor((new Date() - birthDateObj) / (365.25 * 24 * 60 * 60 * 1000));

    // 3. Create child with medical notes
    const childQuery = `
      INSERT INTO children (parent_id, name, age, date_of_birth, medical_notes)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id
    `;
    const childResult = await client.query(childQuery, [parentIdToUse, childName, age, birthDate, notes || null]);
    const childId = childResult.rows[0].id;
    console.log('✅ Child created:', childId);

    // 4. Create enrollment
    const enrollmentQuery = `
      INSERT INTO enrollments (child_id, nursery_id, start_date, status)
      VALUES ($1, $2, $3, 'pending')
      RETURNING id, created_at
    `;
    const enrollmentResult = await client.query(enrollmentQuery, [
      childId, 
      nurseryId, 
      startDate
    ]);
    console.log('✅ Enrollment created:', enrollmentResult.rows[0].id);

    await client.query('COMMIT');

    res.status(201).json({
      success: true,
      enrollment: {
        id: enrollmentResult.rows[0].id,
        childId: childId,
        parentId: parentIdToUse,
        nurseryId: nurseryId,
        createdAt: enrollmentResult.rows[0].created_at
      }
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error creating enrollment:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to create enrollment' 
    });
  } finally {
    client.release();
  }
});

// Get enrollments by nursery
app.get('/api/enrollments/nursery/:nurseryId', async (req, res) => {
  const { nurseryId } = req.params;

  try {
    const query = `
      SELECT 
        e.id as enrollment_id,
        e.start_date,
        e.status,
        e.created_at,
        c.id as child_id,
        c.name as child_name,
        c.date_of_birth,
        c.age,
        u.id as parent_id,
        u.name as parent_name,
        u.phone as parent_phone
      FROM enrollments e
      JOIN children c ON e.child_id = c.id
      JOIN users u ON c.parent_id = u.id
      WHERE e.nursery_id = $1
      ORDER BY e.created_at DESC
    `;
    
    const result = await pool.query(query, [nurseryId]);

    const enrollments = result.rows.map(row => ({
      id: row.enrollment_id,
      enrollmentId: row.enrollment_id,
      startDate: row.start_date,
      status: row.status,
      createdAt: row.created_at,
      child: {
        id: row.child_id,
        childName: row.child_name,
        name: row.child_name,
        birthDate: row.date_of_birth,
        age: row.age
      },
      parent: {
        id: row.parent_id,
        name: row.parent_name,
        phone: row.parent_phone
      }
    }));

    res.json({
      success: true,
      enrollments
    });

  } catch (error) {
    console.error('Error fetching enrollments:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch enrollments' 
    });
  }
});

// Get ALL enrollments (for verification)
app.get('/api/enrollments', async (req, res) => {
  try {
    const query = `
      SELECT 
        e.id as enrollment_id,
        e.start_date,
        e.status,
        e.created_at,
        c.id as child_id,
        c.name as child_name,
        c.date_of_birth,
        c.age,
        u.id as parent_id,
        u.name as parent_name,
        u.phone as parent_phone,
        u.email as parent_email,
        n.id as nursery_id,
        n.name as nursery_name,
        n.description,
        n.address,
        n.city,
        n.postal_code,
        n.phone as nursery_phone,
        n.email as nursery_email,
        n.hours,
        n.price_per_month,
        n.total_spots,
        n.available_spots,
        n.age_range,
        n.rating,
        n.review_count,
        n.photo_url
      FROM enrollments e
      JOIN children c ON e.child_id = c.id
      JOIN users u ON c.parent_id = u.id
      JOIN nurseries n ON e.nursery_id = n.id
      ORDER BY e.created_at DESC
    `;
    
    const result = await pool.query(query);

    const enrollments = result.rows.map(row => ({
      enrollmentId: row.enrollment_id,
      startDate: row.start_date,
      status: row.status,
      createdAt: row.created_at,
      child: {
        id: row.child_id,
        name: row.child_name,
        birthDate: row.date_of_birth,
        age: row.age
      },
      parent: {
        id: row.parent_id,
        name: row.parent_name,
        phone: row.parent_phone,
        email: row.parent_email
      },
      nursery: {
        id: row.nursery_id,
        name: row.nursery_name,
        description: row.description,
        address: row.address,
        city: row.city,
        postalCode: row.postal_code,
        phone: row.nursery_phone,
        email: row.nursery_email,
        hours: row.hours,
        price: row.price_per_month,
        totalSpots: row.total_spots,
        availableSpots: row.available_spots,
        ageRange: row.age_range,
        rating: row.rating,
        reviewCount: row.review_count,
        photoUrl: row.photo_url
      }
    }));

    res.json({
      success: true,
      count: enrollments.length,
      enrollments
    });

  } catch (error) {
    console.error('Error fetching all enrollments:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch enrollments' 
    });
  }
});

// Update enrollment status
app.patch('/api/enrollments/:enrollmentId/status', async (req, res) => {
  const { enrollmentId } = req.params;
  const { status } = req.body;

  // Validate status
  const validStatuses = ['pending', 'active', 'completed', 'cancelled'];
  if (!validStatuses.includes(status)) {
    return res.status(400).json({
      success: false,
      error: 'Invalid status. Must be one of: ' + validStatuses.join(', ')
    });
  }

  try {
    const query = `
      UPDATE enrollments
      SET status = $1, updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING id, status, updated_at
    `;
    
    const result = await pool.query(query, [status, enrollmentId]);

    if (result.rows.length === 0) {
      return res.status(404).json({
        success: false,
        error: 'Enrollment not found'
      });
    }

    res.json({
      success: true,
      enrollment: {
        id: result.rows[0].id,
        status: result.rows[0].status,
        updatedAt: result.rows[0].updated_at
      }
    });

  } catch (error) {
    console.error('Error updating enrollment status:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update enrollment status'
    });
  }
});

// ==============NURSERY DASHBOARD STATISTICS ==============

// Get nursery statistics (enrolled children, revenue, etc.)
app.get('/api/nurseries/:nurseryId/stats', async (req, res) => {
  const { nurseryId } = req.params;

  try {
    // Get total spots and available spots
    const nurseryQuery = 'SELECT total_spots, available_spots, price_per_month FROM nurseries WHERE id = $1';
    const nurseryResult = await pool.query(nurseryQuery, [nurseryId]);
    
    if (nurseryResult.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Nursery not found' });
    }

    const nursery = nurseryResult.rows[0];
    const enrolledCount = nursery.total_spots - nursery.available_spots;
    const monthlyRevenue = enrolledCount * parseFloat(nursery.price_per_month);

    // Get pending enrollments count
    const pendingQuery = `
      SELECT COUNT(*) as pending_count
      FROM enrollments
      WHERE nursery_id = $1 AND status = 'pending'
    `;
    const pendingResult = await pool.query(pendingQuery, [nurseryId]);
    const pendingCount = parseInt(pendingResult.rows[0].pending_count);

    // Get rating and recent reviews
    const ratingQuery = `SELECT rating, review_count FROM nurseries WHERE id = $1`;
    const ratingResult = await pool.query(ratingQuery, [nurseryId]);
    const ratingRow = ratingResult.rows[0] || { rating: 0, review_count: 0 };

    const reviewsQuery = `
      SELECT r.id, r.parent_id, r.rating, r.comment, r.created_at, u.name as parent_name
      FROM reviews r
      LEFT JOIN users u ON r.parent_id = u.id
      WHERE r.nursery_id = $1
      ORDER BY r.created_at DESC
      LIMIT 5
    `;
    const reviewsResult = await pool.query(reviewsQuery, [nurseryId]);

    res.json({
      success: true,
      stats: {
        enrolledChildren: enrolledCount,
        totalSpots: nursery.total_spots,
        availableSpots: nursery.available_spots,
        monthlyRevenue: monthlyRevenue,
        pendingEnrollments: pendingCount,
        rating: ratingRow.rating,
        reviewCount: ratingRow.review_count,
        recentReviews: reviewsResult.rows
      }
    });

  } catch (error) {
    console.error('Error fetching nursery stats:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch statistics' });
  }
});

// ============== ENROLLED CHILDREN MANAGEMENT ==============

// Get all parents and their children enrolled in a nursery (for nursery dashboard)
app.get('/api/nurseries/:nurseryId/enrolled-children', async (req, res) => {
  const { nurseryId } = req.params;

  console.log('📋 Fetching enrolled children for nursery:', nurseryId);

  try {
    const query = `
      SELECT DISTINCT
        u.id as parent_id,
        u.name as parent_name,
        u.email as parent_email,
        u.phone as parent_phone,
        c.id as child_id,
        c.name as child_name,
        c.date_of_birth,
        c.age,
        e.id as enrollment_id,
        e.status as enrollment_status,
        e.start_date,
        e.created_at as enrollment_date
      FROM enrollments e
      JOIN children c ON e.child_id = c.id
      JOIN users u ON c.parent_id = u.id
      WHERE e.nursery_id = $1 AND e.status IN ('active', 'pending')
      ORDER BY u.name ASC, c.name ASC
    `;
    
    const result = await pool.query(query, [nurseryId]);

    console.log('✅ Found', result.rows.length, 'enrollment records');

    // Group data by parent
    const parentMap = new Map();

    result.rows.forEach(row => {
      if (!parentMap.has(row.parent_id)) {
        parentMap.set(row.parent_id, {
          parentId: row.parent_id,
          parentName: row.parent_name,
          parentEmail: row.parent_email,
          parentPhone: row.parent_phone,
          children: []
        });
      }

      parentMap.get(row.parent_id).children.push({
        childId: row.child_id,
        childName: row.child_name,
        age: row.age,
        birthDate: row.date_of_birth,
        enrollmentId: row.enrollment_id,
        enrollmentStatus: row.enrollment_status,
        startDate: row.start_date,
        enrollmentDate: row.enrollment_date
      });
    });

    const parents = Array.from(parentMap.values());

    console.log('✅ Grouped into', parents.length, 'parent(s)');

    res.json({
      success: true,
      nurseryId: nurseryId,
      totalParents: parents.length,
      totalChildren: result.rows.length,
      parents: parents
    });

  } catch (error) {
    console.error('❌ Error fetching enrolled children:', error);
    console.error('Stack:', error.stack);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch enrolled children',
      details: error.message
    });
  }
});

// ============== DAILY SCHEDULE ENDPOINTS ==============

// Get daily schedule for a nursery
app.get('/api/nurseries/:nurseryId/schedule', async (req, res) => {
  const { nurseryId } = req.params;

  try {
    const query = `
      SELECT id, time_slot, activity_name, description, participant_count
      FROM daily_schedule
      WHERE nursery_id = $1
      ORDER BY time_slot ASC
    `;
    
    const result = await pool.query(query, [nurseryId]);

    res.json({
      success: true,
      schedule: result.rows.map(row => ({
        id: row.id,
        timeSlot: row.time_slot,
        activityName: row.activity_name,
        description: row.description,
        participantCount: row.participant_count
      }))
    });

  } catch (error) {
    console.error('Error fetching schedule:', error);
    res.status(500).json({ success: false, error: 'Failed to fetch schedule' });
  }
});

// Create daily schedule item
app.post('/api/nurseries/:nurseryId/schedule', async (req, res) => {
  const { nurseryId } = req.params;
  const { timeSlot, activityName, description, participantCount } = req.body;

  try {
    const query = `
      INSERT INTO daily_schedule (nursery_id, time_slot, activity_name, description, participant_count)
      VALUES ($1, $2, $3, $4, $5)
      RETURNING id, time_slot, activity_name, description, participant_count
    `;
    
    const result = await pool.query(query, [nurseryId, timeSlot, activityName, description || null, participantCount || 0]);
    const row = result.rows[0];

    res.status(201).json({
      success: true,
      schedule: {
        id: row.id,
        timeSlot: row.time_slot,
        activityName: row.activity_name,
        description: row.description,
        participantCount: row.participant_count
      }
    });

  } catch (error) {
    console.error('Error creating schedule:', error);
    res.status(500).json({ success: false, error: 'Failed to create schedule' });
  }
});

// Update daily schedule item
app.put('/api/schedule/:scheduleId', async (req, res) => {
  const { scheduleId } = req.params;
  const { timeSlot, activityName, description, participantCount } = req.body;

  try {
    const query = `
      UPDATE daily_schedule
      SET time_slot = COALESCE($1, time_slot),
          activity_name = COALESCE($2, activity_name),
          description = COALESCE($3, description),
          participant_count = COALESCE($4, participant_count),
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $5
      RETURNING id, time_slot, activity_name, description, participant_count
    `;
    
    const result = await pool.query(query, [timeSlot, activityName, description, participantCount, scheduleId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Schedule not found' });
    }

    const row = result.rows[0];
    res.json({
      success: true,
      schedule: {
        id: row.id,
        timeSlot: row.time_slot,
        activityName: row.activity_name,
        description: row.description,
        participantCount: row.participant_count
      }
    });

  } catch (error) {
    console.error('Error updating schedule:', error);
    res.status(500).json({ success: false, error: 'Failed to update schedule' });
  }
});

// Delete daily schedule item
app.delete('/api/schedule/:scheduleId', async (req, res) => {
  const { scheduleId } = req.params;

  try {
    const result = await pool.query('DELETE FROM daily_schedule WHERE id = $1 RETURNING id', [scheduleId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Schedule not found' });
    }

    res.json({ success: true, message: 'Schedule deleted successfully' });

  } catch (error) {
    console.error('Error deleting schedule:', error);
    res.status(500).json({ success: false, error: 'Failed to delete schedule' });
  }
});

// ============== ENROLLMENT MANAGEMENT ==============

// Accept enrollment (change status to active)
app.post('/api/enrollments/:enrollmentId/accept', async (req, res) => {
  const { enrollmentId } = req.params;

  console.log('📥 Accept enrollment request for ID:', enrollmentId);

  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    // Get enrollment details with parent and child info
    const enrollmentQuery = `
      SELECT e.id, e.nursery_id, e.status, c.parent_id, c.name as child_name, n.name as nursery_name
      FROM enrollments e
      JOIN children c ON e.child_id = c.id
      JOIN nurseries n ON e.nursery_id = n.id
      WHERE e.id = $1
    `;
    const enrollmentResult = await client.query(enrollmentQuery, [enrollmentId]);

    console.log('🔍 Enrollment found:', enrollmentResult.rows.length > 0);

    if (enrollmentResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ success: false, error: 'Enrollment not found' });
    }

    const enrollment = enrollmentResult.rows[0];
    const parentId = enrollment.parent_id;
    const childName = enrollment.child_name;
    const nurseryName = enrollment.nursery_name;

    if (enrollment.status !== 'pending') {
      await client.query('ROLLBACK');
      return res.status(400).json({ success: false, error: 'Enrollment is not pending' });
    }

    // Update enrollment status to active
    const updateResult = await client.query('UPDATE enrollments SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *', ['active', enrollmentId]);
    console.log('✅ Enrollment updated:', updateResult.rows[0]);

    // Decrease available spots
    const spotsResult = await client.query('UPDATE nurseries SET available_spots = available_spots - 1 WHERE id = $1 AND available_spots > 0 RETURNING available_spots', [enrollment.nursery_id]);
    console.log('📊 Available spots updated to:', spotsResult.rows[0]?.available_spots);

    // Create notification for parent
    await client.query(
      `INSERT INTO notifications (user_id, type, title, message, related_id)
       VALUES ($1, $2, $3, $4, $5)`,
      [
        parentId,
        'enrollment_accepted',
        'Inscription Acceptée',
        `L'inscription de ${childName} à ${nurseryName} a été acceptée!`,
        enrollmentId
      ]
    );
    console.log('📬 Notification sent to parent:', parentId);

    await client.query('COMMIT');
    console.log('✅ Transaction committed successfully');

    res.json({ success: true, message: 'Enrollment accepted successfully' });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error accepting enrollment:', error);
    res.status(500).json({ success: false, error: 'Failed to accept enrollment' });
  } finally {
    client.release();
  }
});

// Reject enrollment (change status to cancelled) or cancel active enrollment
app.post('/api/enrollments/:enrollmentId/reject', async (req, res) => {
  const { enrollmentId } = req.params;

  console.log('🚫 Reject/Cancel enrollment request for ID:', enrollmentId);

  const client = await pool.connect();

  try {
    await client.query('BEGIN');

    // Get enrollment details with parent and child info
    const enrollmentQuery = `
      SELECT e.id, e.nursery_id, e.status, c.parent_id, c.name as child_name, n.name as nursery_name
      FROM enrollments e
      JOIN children c ON e.child_id = c.id
      JOIN nurseries n ON e.nursery_id = n.id
      WHERE e.id = $1
    `;
    const enrollmentResult = await client.query(enrollmentQuery, [enrollmentId]);

    console.log('🔍 Enrollment found:', enrollmentResult.rows.length > 0);

    if (enrollmentResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ success: false, error: 'Enrollment not found' });
    }

    const enrollment = enrollmentResult.rows[0];
    const nurseryId = enrollment.nursery_id;
    const currentStatus = enrollment.status;
    const parentId = enrollment.parent_id;
    const childName = enrollment.child_name;
    const nurseryName = enrollment.nursery_name;

    // Only allow cancelling pending or active enrollments
    if (!['pending', 'active'].includes(currentStatus)) {
      await client.query('ROLLBACK');
      return res.status(400).json({ success: false, error: 'Cannot cancel this enrollment status' });
    }

    // Update enrollment status to cancelled
    const updateResult = await client.query(
      'UPDATE enrollments SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 RETURNING *',
      ['cancelled', enrollmentId]
    );

    console.log('✅ Enrollment cancelled:', updateResult.rows[0]);

    // If it was active, return the spot to the nursery
    if (currentStatus === 'active') {
      const spotsResult = await client.query(
        'UPDATE nurseries SET available_spots = available_spots + 1 WHERE id = $1 RETURNING available_spots',
        [nurseryId]
      );
      console.log('📊 Available spots returned to:', spotsResult.rows[0]?.available_spots);
    }

    // Create notification for parent
    const notificationType = currentStatus === 'pending' ? 'enrollment_rejected' : 'enrollment_cancelled';
    const notificationTitle = currentStatus === 'pending' ? 'Inscription Rejetée' : 'Inscription Annulée';
    const notificationMessage = currentStatus === 'pending' 
      ? `L'inscription de ${childName} à ${nurseryName} a été rejetée.`
      : `L'inscription de ${childName} à ${nurseryName} a été annulée.`;

    await client.query(
      `INSERT INTO notifications (user_id, type, title, message, related_id)
       VALUES ($1, $2, $3, $4, $5)`,
      [parentId, notificationType, notificationTitle, notificationMessage, enrollmentId]
    );
    console.log('📬 Notification sent to parent:', parentId);

    await client.query('COMMIT');
    console.log('✅ Transaction committed successfully');

    res.json({ success: true, message: 'Enrollment cancelled successfully' });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('❌ Error rejecting enrollment:', error);
    res.status(500).json({ success: false, error: 'Failed to reject enrollment' });
  } finally {
    client.release();
  }
});

// ============== NOTIFICATIONS ENDPOINTS ==============

// Get notifications for a user
app.get('/api/notifications/:userId', async (req, res) => {
  const { userId } = req.params;

  console.log('🔔 Fetching notifications for user:', userId);

  try {
    const query = `
      SELECT id, type, title, message, is_read, related_id, sent_at
      FROM notifications
      WHERE user_id = $1
      ORDER BY sent_at DESC
      LIMIT 50
    `;
    
    const result = await pool.query(query, [userId]);

    console.log('📬 Found', result.rows.length, 'notifications');

    res.json({
      success: true,
      notifications: result.rows.map(row => ({
        id: row.id,
        type: row.type,
        title: row.title,
        message: row.message,
        isRead: row.is_read,
        relatedId: row.related_id,
        sentAt: row.sent_at
      }))
    });

  } catch (error) {
    console.error('❌ Error fetching notifications:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch notifications'
    });
  }
});

// Mark notification as read
app.post('/api/notifications/:notificationId/read', async (req, res) => {
  const { notificationId } = req.params;

  try {
    const result = await pool.query(
      'UPDATE notifications SET is_read = TRUE WHERE id = $1 RETURNING id',
      [notificationId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Notification not found' });
    }

    res.json({ success: true, message: 'Notification marked as read' });

  } catch (error) {
    console.error('Error marking notification as read:', error);
    res.status(500).json({ success: false, error: 'Failed to mark notification as read' });
  }
});

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

// ============================================================================
// PAYMENT ENDPOINTS (SIMPLIFIED - ONE-TIME PAYMENT PER ENROLLMENT)
// ============================================================================

// Get payment status for a parent
app.get('/api/payments/parent/:parentId/status', async (req, res) => {
  try {
    const { parentId } = req.params;

    // Get all payments for this parent
    const query = `
      SELECT 
        p.id,
        p.enrollment_id,
        p.amount,
        p.payment_status,
        p.payment_date,
        p.payment_month,
        p.payment_year,
        c.name as child_name,
        n.name as nursery_name,
        n.id as nursery_id
      FROM payments p
      JOIN enrollments e ON p.enrollment_id = e.id
      JOIN children c ON e.child_id = c.id
      JOIN nurseries n ON p.nursery_id = n.id
      WHERE p.parent_id = $1 
        AND e.status IN ('accepted', 'active')
      ORDER BY c.name
    `;

    const result = await pool.query(query, [parentId]);

    // Séparer les paiements en payés et non payés
    const pendingPayments = result.rows.filter(p => p.payment_status === 'unpaid');
    const paidPayments = result.rows.filter(p => p.payment_status === 'paid');

    res.json({
      success: true,
      pendingPayments,
      paidPayments,
      totalPending: pendingPayments.length,
      totalPaid: paidPayments.length
    });

  } catch (error) {
    console.error('Error getting payment status:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get payment status'
    });
  }
});

// Process a payment
app.post('/api/payments/process', async (req, res) => {
  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const { enrollmentId, cardNumber, expiryDate, cvv } = req.body;

    // Validate inputs
    if (!enrollmentId || !cardNumber || !expiryDate || !cvv) {
      return res.status(400).json({
        success: false,
        error: 'Missing required fields'
      });
    }

    // Get payment record
    const paymentQuery = `
      SELECT p.*, c.parent_id, e.child_id, e.nursery_id, n.owner_id
      FROM payments p
      JOIN enrollments e ON p.enrollment_id = e.id
      JOIN children c ON e.child_id = c.id
      JOIN nurseries n ON e.nursery_id = n.id
      WHERE p.enrollment_id = $1 
        AND p.payment_status = 'unpaid'
    `;
    const paymentResult = await client.query(paymentQuery, [enrollmentId]);

    if (paymentResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        error: 'Payment not found or already paid'
      });
    }

    const payment = paymentResult.rows[0];

    // Simulate payment processing (in real app, integrate with payment gateway)
    // For now, we assume payment is successful

    // Update payment record
    const transactionId = crypto.randomBytes(16).toString('hex');
    const cardLastDigits = cardNumber.slice(-4);

    const updateQuery = `
      UPDATE payments
      SET 
        payment_status = 'paid',
        payment_date = CURRENT_TIMESTAMP,
        card_last_digits = $1,
        transaction_id = $2
      WHERE id = $3
      RETURNING *
    `;

    const updateResult = await client.query(updateQuery, [
      cardLastDigits,
      transactionId,
      payment.id
    ]);

    // Create notification for nursery
    const notificationQuery = `
      INSERT INTO notifications (user_id, title, message, type, related_id)
      VALUES ($1, $2, $3, $4, $5)
    `;

    const notificationMessage = `Nouveau paiement reçu pour l'inscription #${enrollmentId}`;
    await client.query(notificationQuery, [
      payment.owner_id,
      'Paiement reçu',
      notificationMessage,
      'payment',
      payment.id
    ]);

    await client.query('COMMIT');

    res.json({
      success: true,
      message: 'Payment processed successfully',
      payment: updateResult.rows[0],
      transactionId
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error processing payment:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to process payment'
    });
  } finally {
    client.release();
  }
});

// Get all payments for a nursery
app.get('/api/payments/nursery/:nurseryId', async (req, res) => {
  try {
    const { nurseryId } = req.params;

    const query = `
      SELECT 
        p.id,
        p.amount,
        p.payment_status,
        p.payment_date,
        p.payment_month,
        p.payment_year,
        p.card_last_digits,
        c.name as child_name,
        u.name as parent_name,
        u.email as parent_email,
        u.phone as parent_phone
      FROM payments p
      JOIN enrollments e ON p.enrollment_id = e.id
      JOIN children c ON e.child_id = c.id
      JOIN users u ON p.parent_id = u.id
      WHERE p.nursery_id = $1 
        AND e.status IN ('accepted', 'active')
      ORDER BY p.payment_status, c.name
    `;

    const result = await pool.query(query, [nurseryId]);

    res.json({
      success: true,
      payments: result.rows
    });

  } catch (error) {
    console.error('Error getting nursery payments:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get payments'
    });
  }
});

// Get all payments for a nursery by owner ID
app.get('/api/payments/owner/:ownerId', async (req, res) => {
  try {
    const { ownerId } = req.params;

    const query = `
      SELECT 
        p.id,
        p.amount,
        p.payment_status,
        p.payment_date,
        p.payment_month,
        p.payment_year,
        p.card_last_digits,
        c.name as child_name,
        u.name as parent_name,
        u.email as parent_email,
        u.phone as parent_phone
      FROM payments p
      JOIN nurseries n ON p.nursery_id = n.id
      JOIN enrollments e ON p.enrollment_id = e.id
      JOIN children c ON e.child_id = c.id
      JOIN users u ON p.parent_id = u.id
      WHERE n.owner_id = $1 
        AND e.status IN ('accepted', 'active')
      ORDER BY p.payment_status, c.name
    `;

    const result = await pool.query(query, [ownerId]);

    res.json({
      success: true,
      payments: result.rows
    });

  } catch (error) {
    console.error('Error getting owner payments:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get payments'
    });
  }
});

// Get financial statistics for nursery
app.get('/api/payments/nursery/:nurseryId/stats', async (req, res) => {
  try {
    const { nurseryId } = req.params;

    const query = `
      SELECT 
        COUNT(*) as total_enrollments,
        SUM(amount) as total_expected,
        SUM(CASE WHEN payment_status = 'paid' THEN amount ELSE 0 END) as total_received,
        SUM(CASE WHEN payment_status = 'unpaid' THEN amount ELSE 0 END) as total_pending,
        COUNT(CASE WHEN payment_status = 'paid' THEN 1 END) as paid_count,
        COUNT(CASE WHEN payment_status = 'unpaid' THEN 1 END) as unpaid_count
      FROM payments p
      JOIN enrollments e ON p.enrollment_id = e.id
      WHERE p.nursery_id = $1 
        AND e.status IN ('accepted', 'active')
    `;

    const result = await pool.query(query, [nurseryId]);
    const stats = result.rows[0];

    const totalExpected = parseFloat(stats.total_expected) || 0;
    const totalReceived = parseFloat(stats.total_received) || 0;
    const paymentPercentage = totalExpected > 0 
      ? (totalReceived / totalExpected) * 100 
      : 0;

    res.json({
      success: true,
      stats: {
        total_enrollments: parseInt(stats.total_enrollments) || 0,
        total_expected: totalExpected,
        total_received: totalReceived,
        total_pending: parseFloat(stats.total_pending) || 0,
        paid_count: parseInt(stats.paid_count) || 0,
        unpaid_count: parseInt(stats.unpaid_count) || 0,
        payment_percentage: paymentPercentage
      }
    });

  } catch (error) {
    console.error('Error getting payment stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get statistics'
    });
  }
});

// Get financial statistics for nursery by owner ID
app.get('/api/payments/owner/:ownerId/stats', async (req, res) => {
  try {
    const { ownerId } = req.params;

    const query = `
      SELECT 
        COUNT(*) as total_enrollments,
        SUM(p.amount) as total_expected,
        SUM(CASE WHEN p.payment_status = 'paid' THEN p.amount ELSE 0 END) as total_received,
        SUM(CASE WHEN p.payment_status = 'unpaid' THEN p.amount ELSE 0 END) as total_pending,
        COUNT(CASE WHEN p.payment_status = 'paid' THEN 1 END) as paid_count,
        COUNT(CASE WHEN p.payment_status = 'unpaid' THEN 1 END) as unpaid_count
      FROM payments p
      JOIN nurseries n ON p.nursery_id = n.id
      JOIN enrollments e ON p.enrollment_id = e.id
      WHERE n.owner_id = $1 
        AND e.status IN ('accepted', 'active')
    `;

    const result = await pool.query(query, [ownerId]);
    const stats = result.rows[0];

    const totalExpected = parseFloat(stats.total_expected) || 0;
    const totalReceived = parseFloat(stats.total_received) || 0;
    const paymentPercentage = totalExpected > 0 
      ? (totalReceived / totalExpected) * 100 
      : 0;

    res.json({
      success: true,
      stats: {
        total_enrollments: parseInt(stats.total_enrollments) || 0,
        total_expected: totalExpected,
        total_received: totalReceived,
        total_pending: parseFloat(stats.total_pending) || 0,
        paid_count: parseInt(stats.paid_count) || 0,
        unpaid_count: parseInt(stats.unpaid_count) || 0,
        payment_percentage: paymentPercentage
      }
    });

  } catch (error) {
    console.error('Error getting owner payment stats:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get statistics'
    });
  }
});

// Get payment history for a parent
app.get('/api/payments/parent/:parentId/history', async (req, res) => {
  try {
    const { parentId } = req.params;
    const { limit = 100 } = req.query;

    const query = `
      SELECT 
        p.id,
        p.amount,
        p.payment_status,
        p.payment_date,
        p.card_last_digits,
        c.name as child_name,
        n.name as nursery_name
      FROM payments p
      JOIN enrollments e ON p.enrollment_id = e.id
      JOIN children c ON e.child_id = c.id
      JOIN nurseries n ON p.nursery_id = n.id
      WHERE p.parent_id = $1
      ORDER BY p.payment_date DESC
      LIMIT $2
    `;

    const result = await pool.query(query, [parentId, limit]);

    res.json({
      success: true,
      payments: result.rows
    });

  } catch (error) {
    console.error('Error getting payment history:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to get payment history'
    });
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

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📝 API endpoints available at http://localhost:${PORT}/api`);
});
