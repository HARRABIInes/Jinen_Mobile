const express = require('express');
const router = express.Router();
const pool = require('../config/database');
const { hashPassword } = require('../utils/helpers');

// Register user
router.post('/register', async (req, res) => {
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
router.post('/login', async (req, res) => {
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

module.exports = router;
