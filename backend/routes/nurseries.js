const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { createNotification } = require('../utils/helpers');

// Create nursery
router.post('/', async (req, res) => {
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
      VALUES ($1, $2, $3, $4, $5, $6, $7, $8, $9, $10, $11, $12, $13, $14, $15, $16)
      RETURNING id, owner_id, name, description, address, city, postal_code,
                phone, email, hours, price_per_month, total_spots, available_spots,
                age_range, rating, photo_url, created_at
    `;
    
    const nurseryValues = [
      owner_id, name, description || null, address, city, postal_code || null,
      latitude || null, longitude || null, phone || null, email || null,
      hours || null, price_per_month, total_spots, total_spots, age_range || null, photo_url || null
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
router.get('/', async (req, res) => {
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

// Get nurseries by owner ID
router.get('/owner/:ownerId', async (req, res) => {
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

// Get nursery by ID
router.get('/:id', async (req, res) => {
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
router.get('/:id/reviews', async (req, res) => {
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
router.post('/:id/reviews', async (req, res) => {
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

// Get nursery statistics (enrolled children, revenue, etc.)
router.get('/:nurseryId/stats', async (req, res) => {
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

// Get all parents and their children enrolled in a nursery (for nursery dashboard)
router.get('/:nurseryId/enrolled-children', async (req, res) => {
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

// Get daily schedule for a nursery
router.get('/:nurseryId/schedule', async (req, res) => {
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
router.post('/:nurseryId/schedule', async (req, res) => {
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

module.exports = router;
