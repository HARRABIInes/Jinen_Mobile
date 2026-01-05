const crypto = require('crypto');
const pool = require('../config/database');

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

module.exports = {
  hashPassword,
  createNotification,
};
