const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// Get user by ID
router.get('/:id', async (req, res) => {
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
router.put('/:id', async (req, res) => {
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

module.exports = router;
