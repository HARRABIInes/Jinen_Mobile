const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// Get children for a parent
router.get('/:parentId/children', async (req, res) => {
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
router.get('/:parentId/nurseries', async (req, res) => {
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

// Get today's program for parent's children
router.get('/:parentId/today-program', async (req, res) => {
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
router.get('/:parentId/nursery-reviews', async (req, res) => {
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

module.exports = router;
