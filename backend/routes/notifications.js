const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// Get user notifications
router.get('/:userId', async (req, res) => {
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

// Get unread notification count
router.get('/:userId/unread-count', async (req, res) => {
  const { userId } = req.params;

  try {
    const query = `
      SELECT COUNT(*) as unread_count
      FROM notifications
      WHERE user_id = $1 AND is_read = FALSE
    `;
    
    const result = await pool.query(query, [userId]);
    const unreadCount = parseInt(result.rows[0].unread_count, 10);

    res.json({
      success: true,
      unreadCount: unreadCount
    });

  } catch (error) {
    console.error('❌ Error fetching unread count:', error);
    res.status(500).json({ 
      success: false, 
      error: 'Failed to fetch unread count'
    });
  }
});

// Mark notification as read
router.post('/:notificationId/read', async (req, res) => {
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

// Mark all notifications as read for a user
router.post('/:userId/read-all', async (req, res) => {
  const { userId } = req.params;

  try {
    console.log('📬 Marking all notifications as read for user:', userId);
    const result = await pool.query(
      'UPDATE notifications SET is_read = TRUE WHERE user_id = $1 AND is_read = FALSE RETURNING id',
      [userId]
    );

    console.log(`✅ Marked ${result.rows.length} notifications as read`);
    res.json({ 
      success: true, 
      message: `${result.rows.length} notifications marked as read`,
      count: result.rows.length 
    });

  } catch (error) {
    console.error('Error marking all notifications as read:', error);
    res.status(500).json({ success: false, error: 'Failed to mark notifications as read' });
  }
});

// Delete a notification
router.delete('/:notificationId', async (req, res) => {
  const { notificationId } = req.params;

  try {
    console.log('🗑️ Deleting notification:', notificationId);
    const result = await pool.query(
      'DELETE FROM notifications WHERE id = $1 RETURNING id',
      [notificationId]
    );

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Notification not found' });
    }

    console.log('✅ Notification deleted');
    res.json({ success: true, message: 'Notification deleted' });

  } catch (error) {
    console.error('Error deleting notification:', error);
    res.status(500).json({ success: false, error: 'Failed to delete notification' });
  }
});

module.exports = router;
