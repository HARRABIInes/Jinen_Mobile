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

  const client = await pool.connect();
  
  try {
    await client.query('BEGIN');

    // 1. Create or get parent (using users table)
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
    console.error('Error creating enrollment:', error);
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
        n.name as nursery_name
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
        name: row.nursery_name
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

    res.json({
      success: true,
      stats: {
        enrolledChildren: enrolledCount,
        totalSpots: nursery.total_spots,
        availableSpots: nursery.available_spots,
        monthlyRevenue: monthlyRevenue,
        pendingEnrollments: pendingCount
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

    // Get enrollment details
    const enrollmentQuery = 'SELECT nursery_id, status FROM enrollments WHERE id = $1';
    const enrollmentResult = await client.query(enrollmentQuery, [enrollmentId]);

    console.log('🔍 Enrollment found:', enrollmentResult.rows.length > 0);

    if (enrollmentResult.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({ success: false, error: 'Enrollment not found' });
    }

    const enrollment = enrollmentResult.rows[0];

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

// Reject enrollment (change status to cancelled)
app.post('/api/enrollments/:enrollmentId/reject', async (req, res) => {
  const { enrollmentId } = req.params;

  try {
    // Update enrollment status to cancelled
    const result = await pool.query(
      'UPDATE enrollments SET status = $1, updated_at = CURRENT_TIMESTAMP WHERE id = $2 AND status = $3 RETURNING id',
      ['cancelled', enrollmentId, 'pending']
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Enrollment not found or not pending' });
    }

    res.json({ success: true, message: 'Enrollment rejected successfully' });

  } catch (error) {
    console.error('Error rejecting enrollment:', error);
    res.status(500).json({ success: false, error: 'Failed to reject enrollment' });
  }
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📝 API endpoints available at http://localhost:${PORT}/api`);
});
