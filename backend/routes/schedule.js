const express = require('express');
const router = express.Router();
const pool = require('../config/database');

// Update daily schedule item
router.put('/:scheduleId', async (req, res) => {
  const { scheduleId } = req.params;
  const { timeSlot, activityName, description, participantCount } = req.body;

  try {
    const query = `
      UPDATE daily_schedule
      SET time_slot = COALESCE($1, time_slot),
          activity_name = COALESCE($2, activity_name),
          description = COALESCE($3, description),
          participant_count = COALESCE($4, participant_count),
          updated_at = CURRENT_TIMESTAMP
      WHERE id = $5
      RETURNING id, time_slot, activity_name, description, participant_count
    `;
    
    const result = await pool.query(query, [timeSlot, activityName, description, participantCount, scheduleId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Schedule not found' });
    }

    const row = result.rows[0];
    res.json({
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
    console.error('Error updating schedule:', error);
    res.status(500).json({ success: false, error: 'Failed to update schedule' });
  }
});

// Delete daily schedule item
router.delete('/:scheduleId', async (req, res) => {
  const { scheduleId } = req.params;

  try {
    const result = await pool.query('DELETE FROM daily_schedule WHERE id = $1 RETURNING id', [scheduleId]);

    if (result.rows.length === 0) {
      return res.status(404).json({ success: false, error: 'Schedule not found' });
    }

    res.json({ success: true, message: 'Schedule deleted successfully' });

  } catch (error) {
    console.error('Error deleting schedule:', error);
    res.status(500).json({ success: false, error: 'Failed to delete schedule' });
  }
});

module.exports = router;
