const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { createNotification } = require('../utils/helpers');

// Create new enrollment
router.post('/', async (req, res) => {
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
    const enrollmentId = enrollmentResult.rows[0].id;
    console.log('✅ Enrollment created:', enrollmentId);

    // 5. Create payment for this enrollment
    const paymentQuery = `
      INSERT INTO payments (enrollment_id, parent_id, nursery_id, child_id, amount, payment_status, description)
      SELECT 
        e.id,
        c.parent_id,
        e.nursery_id,
        e.child_id,
        COALESCE(n.price_per_month, 100.00),
        'unpaid',
        'Monthly fee for ' || c.name || ' at ' || n.name
      FROM enrollments e
      JOIN nurseries n ON e.nursery_id = n.id
      JOIN children c ON e.child_id = c.id
      WHERE e.id = $1
      AND NOT EXISTS (
        SELECT 1 FROM payments WHERE enrollment_id = e.id
      )
      RETURNING id
    `;
    const paymentResult = await client.query(paymentQuery, [enrollmentId]);
    if (paymentResult.rows.length > 0) {
      console.log('✅ Payment created:', paymentResult.rows[0].id);
    } else {
      console.log('⚠️ Payment already exists for enrollment:', enrollmentId);
    }

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

// Get enrollments by nursery ID
router.get('/nursery/:nurseryId', async (req, res) => {
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

// Get enrollments by parent ID
router.get('/parent/:parentId', async (req, res) => {
  const { parentId } = req.params;
  
  console.log('📋 Fetching enrollments for parent:', parentId);

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
      WHERE c.parent_id = $1
      ORDER BY e.created_at DESC
    `;
    
    const result = await pool.query(query, [parentId]);

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

    console.log(`✅ Found ${enrollments.length} enrollments for parent ${parentId}`);

    res.json({
      success: true,
      count: enrollments.length,
      enrollments
    });

  } catch (error) {
    console.error('❌ Error fetching parent enrollments:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch parent enrollments' 
    });
  }
});

// Get all enrollments
router.get('/', async (req, res) => {
  console.log('📋 Fetching all enrollments');

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
router.patch('/:enrollmentId/status', async (req, res) => {
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

  const client = await pool.connect();
  try {
    await client.query('BEGIN');

    const query = `
      UPDATE enrollments
      SET status = $1, updated_at = CURRENT_TIMESTAMP
      WHERE id = $2
      RETURNING id, status, updated_at
    `;
    
    const result = await client.query(query, [status, enrollmentId]);

    if (result.rows.length === 0) {
      await client.query('ROLLBACK');
      return res.status(404).json({
        success: false,
        error: 'Enrollment not found'
      });
    }

    // If status is being set to 'active', create payment if it doesn't exist
    if ((status === 'active')) {
      const paymentQuery = `
        INSERT INTO payments (enrollment_id, parent_id, nursery_id, child_id, amount, payment_status)
        SELECT 
          e.id,
          c.parent_id,
          e.nursery_id,
          e.child_id,
          COALESCE(n.price_per_month, 100.00),
          'unpaid'
        FROM enrollments e
        JOIN nurseries n ON e.nursery_id = n.id
        JOIN children c ON e.child_id = c.id
        WHERE e.id = $1
        ON CONFLICT (enrollment_id) DO NOTHING
        RETURNING id
      `;
      const paymentResult = await client.query(paymentQuery, [enrollmentId]);
      if (paymentResult.rows.length > 0) {
        console.log('✅ Payment created for enrollment:', enrollmentId);
      }
    }

    await client.query('COMMIT');

    res.json({
      success: true,
      enrollment: {
        id: result.rows[0].id,
        status: result.rows[0].status,
        updatedAt: result.rows[0].updated_at
      }
    });

  } catch (error) {
    await client.query('ROLLBACK');
    console.error('Error updating enrollment status:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to update enrollment status'
    });
  } finally {
    client.release();
  }
});

// Accept enrollment (change status to active)
router.post('/:enrollmentId/accept', async (req, res) => {
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

    // Create payment record for this enrollment
    const paymentQuery = `
      INSERT INTO payments (enrollment_id, parent_id, nursery_id, child_id, amount, payment_status)
      SELECT 
        e.id,
        c.parent_id,
        e.nursery_id,
        e.child_id,
        COALESCE(n.price_per_month, 100.00),
        'unpaid'
      FROM enrollments e
      JOIN nurseries n ON e.nursery_id = n.id
      JOIN children c ON e.child_id = c.id
      WHERE e.id = $1
      ON CONFLICT (enrollment_id) DO NOTHING
      RETURNING id
    `;
    const paymentResult = await client.query(paymentQuery, [enrollmentId]);
    if (paymentResult.rows.length > 0) {
      console.log('💰 Payment created for enrollment:', enrollmentId, 'Payment ID:', paymentResult.rows[0].id);
    } else {
      console.log('ℹ️  Payment already exists for enrollment:', enrollmentId);
    }

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
router.post('/:enrollmentId/reject', async (req, res) => {
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

module.exports = router;
