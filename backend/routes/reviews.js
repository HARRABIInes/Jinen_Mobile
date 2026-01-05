const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// Update a review (only parent who created it should update)
router.put('/:reviewId', async (req, res) => {
  const { reviewId } = req.params;
  const { parentId, rating, comment } = req.body;

  if (!parentId || rating == null) {
    return res.status(400).json({ success: false, error: 'parentId and rating are required' });
  }

  try {
    // Verify ownership
    const check = await pool.query('SELECT parent_id FROM reviews WHERE id = $1', [reviewId]);
    if (check.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Review not found' });
    }
    if (check.rows[0].parent_id !== parentId) {
      return res.status(403).json({ success: false, error: 'Not allowed to edit this review' });
    }

    const update = `
      UPDATE reviews SET rating = $1, comment = $2, updated_at = CURRENT_TIMESTAMP
      WHERE id = $3 RETURNING id, nursery_id, parent_id, rating, comment, updated_at
    `;
    const result = await pool.query(update, [parseFloat(rating), comment || null, reviewId]);
    res.json({ success: true, review: result.rows[0] });
  } catch (error) {
    console.error('Error updating review:', error);
    res.status(500).json({ success: false, error: 'Failed to update review' });
  }
});

// Delete a review (only parent who created it should delete)
router.delete('/:reviewId', async (req, res) => {
  const { reviewId } = req.params;
  const { parentId } = req.body;

  if (!parentId) return res.status(400).json({ success: false, error: 'parentId required' });

  try {
    const check = await pool.query('SELECT parent_id FROM reviews WHERE id = $1', [reviewId]);
    if (check.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Review not found' });
    }
    if (check.rows[0].parent_id !== parentId) {
      return res.status(403).json({ success: false, error: 'Not allowed to delete this review' });
    }

    await pool.query('DELETE FROM reviews WHERE id = $1', [reviewId]);
    res.json({ success: true });
  } catch (error) {
    console.error('Error deleting review:', error);
    res.status(500).json({ success: false, error: 'Failed to delete review' });
  }
});

module.exports = router;
