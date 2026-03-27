/**
 * Users Routes - User registration, login, and profile management
 * 
 * @author Sleep Coach Team
 */

const express = require('express');
const bcrypt = require('bcryptjs');
const { v4: uuidv4 } = require('uuid');
const { authenticate, generateToken } = require('../services/auth');
const { getDatabase } = require('../services/database');

const router = express.Router();

/**
 * POST /api/users/register
 * Create a new user account
 */
router.post('/register', async (req, res) => {
  try {
    const { email, password, name, plannedBedtime, plannedWakeTime, sleepGoalHours, timezone, language } = req.body;
    
    // Validation
    if (!email || !password) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Email and password are required'
      });
    }
    
    if (password.length < 6) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Password must be at least 6 characters'
      });
    }
    
    const emailRegex = /^[^\s@]+@[^\s@]+\.[^\s@]+$/;
    if (!emailRegex.test(email)) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Invalid email format'
      });
    }
    
    const db = getDatabase();
    
    // Check if user already exists
    const existingUser = db.prepare('SELECT id FROM users WHERE email = ?').get(email);
    if (existingUser) {
      return res.status(409).json({
        error: 'Conflict',
        message: 'A user with this email already exists'
      });
    }
    
    // Hash password
    const passwordHash = await bcrypt.hash(password, 12);
    
    // Create user
    const userId = uuidv4();
    const stmt = db.prepare(`
      INSERT INTO users (id, email, password_hash, name, planned_bedtime, planned_wake_time, sleep_goal_hours, timezone, language)
      VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?)
    `);
    
    stmt.run(
      userId,
      email,
      passwordHash,
      name || null,
      plannedBedtime || '23:00',
      plannedWakeTime || '07:00',
      sleepGoalHours || 8.0,
      timezone || 'Asia/Jerusalem',
      language || 'he'
    );
    
    // Generate token
    const token = generateToken(userId, email);
    
    // Return user data (without password)
    res.status(201).json({
      message: 'User registered successfully',
      user: {
        id: userId,
        email,
        name: name || null,
        plannedBedtime: plannedBedtime || '23:00',
        plannedWakeTime: plannedWakeTime || '07:00',
        sleepGoalHours: sleepGoalHours || 8.0,
        timezone: timezone || 'Asia/Jerusalem',
        language: language || 'he'
      },
      token
    });
    
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to register user'
    });
  }
});

/**
 * POST /api/users/login
 * Authenticate user and return token
 */
router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body;
    
    if (!email || !password) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'Email and password are required'
      });
    }
    
    const db = getDatabase();
    
    // Find user
    const user = db.prepare('SELECT * FROM users WHERE email = ?').get(email);
    if (!user) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid email or password'
      });
    }
    
    // Verify password
    const isValidPassword = await bcrypt.compare(password, user.password_hash);
    if (!isValidPassword) {
      return res.status(401).json({
        error: 'Unauthorized',
        message: 'Invalid email or password'
      });
    }
    
    // Generate token
    const token = generateToken(user.id, user.email);
    
    res.json({
      message: 'Login successful',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        plannedBedtime: user.planned_bedtime,
        plannedWakeTime: user.planned_wake_time,
        sleepGoalHours: user.sleep_goal_hours,
        timezone: user.timezone,
        language: user.language
      },
      token
    });
    
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to login'
    });
  }
});

/**
 * GET /api/users/profile
 * Get current user's profile
 */
router.get('/profile', authenticate, (req, res) => {
  try {
    const db = getDatabase();
    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);
    
    if (!user) {
      return res.status(404).json({
        error: 'Not Found',
        message: 'User not found'
      });
    }
    
    res.json({
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        plannedBedtime: user.planned_bedtime,
        plannedWakeTime: user.planned_wake_time,
        sleepGoalHours: user.sleep_goal_hours,
        timezone: user.timezone,
        language: user.language,
        createdAt: user.created_at
      }
    });
    
  } catch (error) {
    console.error('Get profile error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get profile'
    });
  }
});

/**
 * PUT /api/users/profile
 * Update current user's profile
 */
router.put('/profile', authenticate, (req, res) => {
  try {
    const { name, plannedBedtime, plannedWakeTime, sleepGoalHours, timezone, language } = req.body;
    
    const db = getDatabase();
    
    // Build update query dynamically
    const updates = [];
    const values = [];
    
    if (name !== undefined) {
      updates.push('name = ?');
      values.push(name);
    }
    if (plannedBedtime !== undefined) {
      updates.push('planned_bedtime = ?');
      values.push(plannedBedtime);
    }
    if (plannedWakeTime !== undefined) {
      updates.push('planned_wake_time = ?');
      values.push(plannedWakeTime);
    }
    if (sleepGoalHours !== undefined) {
      updates.push('sleep_goal_hours = ?');
      values.push(sleepGoalHours);
    }
    if (timezone !== undefined) {
      updates.push('timezone = ?');
      values.push(timezone);
    }
    if (language !== undefined) {
      updates.push('language = ?');
      values.push(language);
    }
    
    if (updates.length === 0) {
      return res.status(400).json({
        error: 'Bad Request',
        message: 'No fields to update'
      });
    }
    
    updates.push('updated_at = CURRENT_TIMESTAMP');
    values.push(req.user.id);
    
    const query = `UPDATE users SET ${updates.join(', ')} WHERE id = ?`;
    db.prepare(query).run(...values);
    
    // Get updated user
    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);
    
    res.json({
      message: 'Profile updated successfully',
      user: {
        id: user.id,
        email: user.email,
        name: user.name,
        plannedBedtime: user.planned_bedtime,
        plannedWakeTime: user.planned_wake_time,
        sleepGoalHours: user.sleep_goal_hours,
        timezone: user.timezone,
        language: user.language
      }
    });
    
  } catch (error) {
    console.error('Update profile error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to update profile'
    });
  }
});

module.exports = router;
