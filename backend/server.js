const express = require('express');
const cors = require('cors');
const crypto = require('crypto');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors());
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

// ============== AUTH ENDPOINTS ==============

// Register new user
app.post('/api/auth/register', async (req, res) => {
  const { email, password, name, user_type, phone } = req.body;

  try {
    // Check if email already exists
    const checkQuery = 'SELECT id FROM users WHERE email = $1';
    const checkResult = await pool.query(checkQuery, [email]);

    if (checkResult.rows.length > 0) {
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
    console.error('Error registering user:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to register user' 
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

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ 
    status: 'OK', 
    timestamp: new Date().toISOString() 
  });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📝 API endpoints available at http://localhost:${PORT}/api`);
});
