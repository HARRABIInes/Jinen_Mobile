const express = require('express');
const cors = require('cors');
require('dotenv').config();

// Import configuration
const corsOptions = require('./config/cors');
const pool = require('./config/database');

// Import routes
const authRoutes = require('./routes/auth');
const usersRoutes = require('./routes/users');
const parentsRoutes = require('./routes/parents');
const nurseriesRoutes = require('./routes/nurseries');
const reviewsRoutes = require('./routes/reviews');
const scheduleRoutes = require('./routes/schedule');
const enrollmentsRoutes = require('./routes/enrollments');
const notificationsRoutes = require('./routes/notifications');
const paymentsRoutes = require('./routes/payments');
const conversationsRoutes = require('./routes/conversations');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors(corsOptions));
app.use(express.json());

// Mount routes
app.use('/api/auth', authRoutes);
app.use('/api/users', usersRoutes);
app.use('/api/parents', parentsRoutes);
app.use('/api/nurseries', nurseriesRoutes);
app.use('/api/reviews', reviewsRoutes);
app.use('/api/schedule', scheduleRoutes);
app.use('/api/enrollments', enrollmentsRoutes);
app.use('/api/notifications', notificationsRoutes);
app.use('/api/payments', paymentsRoutes);
app.use('/api/conversations', conversationsRoutes);

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({ status: 'OK', timestamp: new Date().toISOString() });
});

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on http://localhost:${PORT}`);
  console.log(`📝 API endpoints available at http://localhost:${PORT}/api`);
});

module.exports = app;
