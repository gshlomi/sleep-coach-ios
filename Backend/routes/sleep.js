/**
 * Sleep Routes - Sleep logging endpoints
 * 
 * @author Sleep Coach Team
 */

const express = require('express');
const { v4: uuidv4 } = require('uuid');
const { authenticate } = require('../services/auth');
const { getDatabase } = require('../services/database');

const router = express.Router();

/**
 * GET /api/sleep/logs
 * Get all sleep logs for the authenticated user
 * Query params: limit, offset, startDate, endDate
 */
router.get('/logs', authenticate, (req, res) => {
  try {
    const { limit = 30, offset = 0, startDate, endDate } = req.query;
    
    const db = getDatabase();
    
    let query = 'SELECT * FROM sleep_logs WHERE user_id = ?';
    const params = [req.user.id];
    
    if (startDate) {
      query += ' AND bedtime >= ?';
      params.push(startDate);
    }
    if (endDate) {
      query += ' AND bedtime <= ?';
      params.push(endDate);
    }
    
    query += ' ORDER BY bedtime DESC LIMIT ? OFFSET ?';
    params.push(parseInt(limit), parseInt(offset));
    
    const logs = db.prepare(query).all(...params);
    
    // Get total count
    let countQuery = 'SELECT COUNT(*) as total FROM sleep_logs WHERE user_id = ?';
    const countParams = [req.user.id];
    if (startDate) {
      countQuery += ' AND bedtime >= ?';
      countParams.push(startDate);
    }
    if (endDate) {
      countQuery += ' AND bedtime <= ?';
      countParams.push(endDate);
    }
    const { total } = db.prepare(countQuery).get(...countParams);
    
    res.json({
      logs: logs.map(formatSleepLog),
      pagination: {
        total,
        limit: parseInt(limit),
        offset: parseInt(offset),
        hasMore: parseInt(offset) + logs.length < total
      }
    });
    
  } catch (error) {
    console.error('Get sleep logs error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get sleep logs'
    });
  }
});

/**
 * POST /api/sleep/logs
 * Submit a new sleep log
 */
router.post('/logs', authenticate, (req, res) => {
  try {
    const { bedtime, wakeTime, sleepQuality, notes, preSleepTasksCompleted, healthkitSynced } = req.body;
    
    // Validation
    if (!bedtime || !wakeTime) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Bedtime and wake time are required'
      });
    }
    
    // Calculate sleep duration
    const bedtimeDate = new Date(bedtime);
    const wakeTimeDate = new Date(wakeTime);
    let durationMs = wakeTimeDate - bedtimeDate;
    
    // Handle overnight sleep (bedtime after midnight)
    if (durationMs < 0) {
      durationMs += 24 * 60 * 60 * 1000;
    }
    
    const sleepDurationMinutes = Math.round(durationMs / (1000 * 60));
    
    // Validate sleep quality
    if (sleepQuality && (sleepQuality < 1 || sleepQuality > 5)) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Sleep quality must be between 1 and 5'
      });
    }
    
    const db = getDatabase();
    const logId = uuidv4();
    
    const stmt = db.prepare(`
      INSERT INTO sleep_logs (id, user_id, bedtime, wake_time, sleep_duration_minutes, sleep_quality, notes, pre_sleep_tasks_completed, healthkit_synced)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);
    
    stmt.run(
      logId,
      req.user.id,
      bedtime,
      wakeTime,
      sleepDurationMinutes,
      sleepQuality || null,
      notes || null,
      preSleepTasksCompleted ? JSON.stringify(preSleepTasksCompleted) : null,
      healthkitSynced ? 1 : 0
    );
    
    // Get the created log
    const log = db.prepare('SELECT * FROM sleep_logs WHERE id = ?').get(logId);
    
    res.status(201).json({
      message: 'Sleep log created successfully',
      log: formatSleepLog(log)
    });
    
  } catch (error) {
    console.error('Create sleep log error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to create sleep log'
    });
  }
});

/**
 * GET /api/sleep/logs/:id
 * Get a specific sleep log
 */
router.get('/logs/:id', authenticate, (req, res) => {
  try {
    const db = getDatabase();
    const log = db.prepare('SELECT * FROM sleep_logs WHERE id = ? AND user_id = ?').get(req.params.id, req.user.id);
    
    if (!log) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Sleep log not found'
      });
    }
    
    res.json({
      log: formatSleepLog(log)
    });
    
  } catch (error) {
    console.error('Get sleep log error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get sleep log'
    });
  }
});

/**
 * PUT /api/sleep/logs/:id
 * Update a sleep log
 */
router.put('/logs/:id', authenticate, (req, res) => {
  try {
    const { bedtime, wakeTime, sleepQuality, notes, preSleepTasksCompleted } = req.body;
    
    const db = getDatabase();
    
    // Check if log exists and belongs to user
    const existingLog = db.prepare('SELECT * FROM sleep_logs WHERE id = ? AND user_id = ?').get(req.params.id, req.user.id);
    if (!existingLog) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Sleep log not found'
      });
    }
    
    // Build update query
    const updates = [];
    const values = [];
    
    if (bedtime !== undefined) {
      updates.push('bedtime = ?');
      values.push(bedtime);
    }
    if (wakeTime !== undefined) {
      updates.push('wake_time = ?');
      values.push(wakeTime);
    }
    if (sleepQuality !== undefined) {
      updates.push('sleep_quality = ?');
      values.push(sleepQuality);
    }
    if (notes !== undefined) {
      updates.push('notes = ?');
      values.push(notes);
    }
    if (preSleepTasksCompleted !== undefined) {
      updates.push('pre_sleep_tasks_completed = ?');
      values.push(JSON.stringify(preSleepTasksCompleted));
    }
    
    // Recalculate duration if times changed
    const finalBedtime = bedtime || existingLog.bedtime;
    const finalWakeTime = wakeTime || existingLog.wake_time;
    const bedtimeDate = new Date(finalBedtime);
    const wakeTimeDate = new Date(finalWakeTime);
    let durationMs = wakeTimeDate - bedtimeDate;
    if (durationMs < 0) {
      durationMs += 24 * 60 * 60 * 1000;
    }
    updates.push('sleep_duration_minutes = ?');
    values.push(Math.round(durationMs / (1000 * 60)));
    
    values.push(req.params.id);
    values.push(req.user.id);
    
    const query = `UPDATE sleep_logs SET ${updates.join(', ')} WHERE id = ? AND user_id = ?`;
    db.prepare(query).run(...values);
    
    // Get updated log
    const log = db.prepare('SELECT * FROM sleep_logs WHERE id = ?').get(req.params.id);
    
    res.json({
      message: 'Sleep log updated successfully',
      log: formatSleepLog(log)
    });
    
  } catch (error) {
    console.error('Update sleep log error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to update sleep log'
    });
  }
});

/**
 * DELETE /api/sleep/logs/:id
 * Delete a sleep log
 */
router.delete('/logs/:id', authenticate, (req, res) => {
  try {
    const db = getDatabase();
    const result = db.prepare('DELETE FROM sleep_logs WHERE id = ? AND user_id = ?').run(req.params.id, req.user.id);
    
    if (result.changes === 0) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'Sleep log not found'
      });
    }
    
    res.json({
      message: 'Sleep log deleted successfully'
    });
    
  } catch (error) {
    console.error('Delete sleep log error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to delete sleep log'
    });
  }
});

/**
 * POST /api/sleep/tasks/complete
 * Record completion of a pre-sleep task
 */
router.post('/tasks/complete', authenticate, (req, res) => {
  try {
    const { taskType, sleepLogId } = req.body;
    
    if (!taskType) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Task type is required'
      });
    }
    
    const validTaskTypes = ['screen_shutdown', 'wind_down', 'worry_list', 'breathing', 'cognitive_shuffle'];
    if (!validTaskTypes.includes(taskType)) {
      return res.status(400).json({
        error: 'Bad Request',
        message: `Invalid task type. Must be one of: ${validTaskTypes.join(', ')}`
      });
    }
    
    const db = getDatabase();
    const completionId = uuidv4();
    
    const stmt = db.prepare(`
      INSERT INTO task_completions (id, user_id, sleep_log_id, task_type)
      VALUES (?, ?, ?, ?)
    `);
    
    stmt.run(completionId, req.user.id, sleepLogId || null, taskType);
    
    res.status(201).json({
      message: 'Task completion recorded',
      completion: {
        id: completionId,
        taskType,
        sleepLogId,
        completedAt: new Date().toISOString()
      }
    });
    
  } catch (error) {
    console.error('Record task completion error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to record task completion'
    });
  }
});

/**
 * Helper function to format sleep log for API response
 */
function formatSleepLog(log) {
  return {
    id: log.id,
    bedtime: log.bedtime,
    wakeTime: log.wake_time,
    sleepDurationMinutes: log.sleep_duration_minutes,
    sleepDurationHours: Math.round((log.sleep_duration_minutes / 60) * 10) / 10,
    sleepQuality: log.sleep_quality,
    notes: log.notes,
    preSleepTasksCompleted: log.pre_sleep_tasks_completed ? JSON.parse(log.pre_sleep_tasks_completed) : null,
    healthkitSynced: Boolean(log.healthkit_synced),
    createdAt: log.created_at
  };
}

module.exports = router;
