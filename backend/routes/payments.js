const express = require('express');
const router = express.Router();
const crypto = require('crypto');
const pool = require('../config/database');
const { createNotification } = require('../utils/helpers');

// Sync payments with enrollments
router.post('/sync', async (req, res) => {
  try {
    const query = `
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
      WHERE e.status IN ('pending', 'active')
      AND NOT EXISTS (
        SELECT 1 FROM payments p 
        WHERE p.enrollment_id = e.id
      )
      ON CONFLICT (enrollment_id) DO NOTHING
      RETURNING id
    `;

    const result = await pool.query(query);

    res.json({
      success: true,
      message: `${result.rows.length} paiements créés`,
      paymentsCreated: result.rows.length
    });

  } catch (error) {
    console.error('Error syncing payments:', error);
    res.status(500).json({
      success: false,
      error: 'Failed to sync payments'
    });
  }
});

// Get payment status for a parent
router.get('/parent/:parentId/status', async (req, res) => {
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
        AND e.status IN ('pending', 'active')
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
router.post('/process', async (req, res) => {
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
router.get('/nursery/:nurseryId', async (req, res) => {
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
        AND e.status IN ('pending', 'active')
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
router.get('/owner/:ownerId', async (req, res) => {
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
        AND e.status IN ('pending', 'active')
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
router.get('/nursery/:nurseryId/stats', async (req, res) => {
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
        AND e.status IN ('pending', 'active')
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
router.get('/owner/:ownerId/stats', async (req, res) => {
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
        AND e.status IN ('pending', 'active')
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
router.get('/parent/:parentId/history', async (req, res) => {
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

module.exports = router;
