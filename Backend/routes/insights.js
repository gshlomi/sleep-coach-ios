/**
 * Insights Routes - Sleep analysis and personalized recommendations
 * 
 * @author Sleep Coach Team
 */

const express = require('express');
const { authenticate } = require('../services/auth');
const { getDatabase } = require('../services/database');
const { analyzeSleepPatterns } = require('../services/sleepAnalyzer');
const { generateInsights } = require('../services/insightGenerator');

const router = express.Router();

/**
 * GET /api/insights/weekly
 * Get weekly sleep analysis
 */
router.get('/weekly', authenticate, async (req, res) => {
  try {
    const db = getDatabase();
    
    // Get sleep logs from the last 7 days
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    
    const logs = db.prepare(`
      SELECT * FROM sleep_logs 
      WHERE user_id = ? AND bedtime >= ?
      ORDER BY bedtime DESC
    `).all(req.user.id, sevenDaysAgo.toISOString());
    
    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);
    
    // Get task completions for correlation
    const taskCompletions = db.prepare(`
      SELECT * FROM task_completions 
      WHERE user_id = ? AND completed_at >= ?
    `).all(req.user.id, sevenDaysAgo.toISOString());
    
    // Analyze patterns
    const analysis = analyzeSleepPatterns(logs, taskCompletions, user);
    
    res.json({
      period: 'weekly',
      startDate: sevenDaysAgo.toISOString(),
      endDate: new Date().toISOString(),
      logsCount: logs.length,
      analysis
    });
    
  } catch (error) {
    console.error('Weekly insights error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get weekly insights'
    });
  }
});

/**
 * GET /api/insights/monthly
 * Get monthly sleep analysis
 */
router.get('/monthly', authenticate, async (req, res) => {
  try {
    const db = getDatabase();
    
    // Get sleep logs from the last 30 days
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    const logs = db.prepare(`
      SELECT * FROM sleep_logs 
      WHERE user_id = ? AND bedtime >= ?
      ORDER BY bedtime DESC
    `).all(req.user.id, thirtyDaysAgo.toISOString());
    
    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);
    
    // Get task completions for correlation
    const taskCompletions = db.prepare(`
      SELECT * FROM task_completions 
      WHERE user_id = ? AND completed_at >= ?
    `).all(req.user.id, thirtyDaysAgo.toISOString());
    
    // Analyze patterns
    const analysis = analyzeSleepPatterns(logs, taskCompletions, user);
    
    res.json({
      period: 'monthly',
      startDate: thirtyDaysAgo.toISOString(),
      endDate: new Date().toISOString(),
      logsCount: logs.length,
      analysis
    });
    
  } catch (error) {
    console.error('Monthly insights error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get monthly insights'
    });
  }
});

/**
 * GET /api/insights/recommendations
 * Get personalized recommendations based on sleep patterns
 */
router.get('/recommendations', authenticate, async (req, res) => {
  try {
    const db = getDatabase();
    
    // Get all sleep logs for comprehensive analysis
    const allLogs = db.prepare(`
      SELECT * FROM sleep_logs 
      WHERE user_id = ?
      ORDER BY bedtime DESC
      LIMIT 90
    `).all(req.user.id);
    
    // Get task completions
    const ninetyDaysAgo = new Date();
    ninetyDaysAgo.setDate(ninetyDaysAgo.getDate() - 90);
    
    const taskCompletions = db.prepare(`
      SELECT * FROM task_completions 
      WHERE user_id = ? AND completed_at >= ?
    `).all(req.user.id, ninetyDaysAgo.toISOString());
    
    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);
    
    // Get recent insights to avoid duplicates
    const recentInsights = db.prepare(`
      SELECT * FROM insights 
      WHERE user_id = ? AND created_at >= ?
      ORDER BY created_at DESC
    `).all(req.user.id, thirtyDaysAgo.toISOString());
    
    const recommendations = generateInsights(allLogs, taskCompletions, user);
    
    res.json({
      recommendations,
      generatedAt: new Date().toISOString()
    });
    
  } catch (error) {
    console.error('Recommendations error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get recommendations'
    });
  }
});

/**
 * GET /api/insights/summary
 * Get a quick summary for the dashboard
 */
router.get('/summary', authenticate, async (req, res) => {
  try {
    const db = getDatabase();
    
    // Get last 7 days logs
    const sevenDaysAgo = new Date();
    sevenDaysAgo.setDate(sevenDaysAgo.getDate() - 7);
    
    const weekLogs = db.prepare(`
      SELECT * FROM sleep_logs 
      WHERE user_id = ? AND bedtime >= ?
      ORDER BY bedtime DESC
    `).all(req.user.id, sevenDaysAgo.toISOString());
    
    // Get last 30 days logs
    const thirtyDaysAgo = new Date();
    thirtyDaysAgo.setDate(thirtyDaysAgo.getDate() - 30);
    
    const monthLogs = db.prepare(`
      SELECT * FROM sleep_logs 
      WHERE user_id = ? AND bedtime >= ?
      ORDER BY bedtime DESC
    `).all(req.user.id, thirtyDaysAgo.toISOString());
    
    const user = db.prepare('SELECT * FROM users WHERE id = ?').get(req.user.id);
    
    // Calculate streak
    let streak = 0;
    const today = new Date();
    today.setHours(0, 0, 0, 0);
    
    for (let i = 0; i < 30; i++) {
      const checkDate = new Date(today);
      checkDate.setDate(checkDate.getDate() - i);
      const checkDateStr = checkDate.toISOString().split('T')[0];
      
      const hasLog = weekLogs.some(log => {
        const logDate = new Date(log.bedtime).toISOString().split('T')[0];
        return logDate === checkDateStr;
      });
      
      if (hasLog) {
        streak++;
      } else if (i > 0) {
        break;
      }
    }
    
    // Calculate weekly averages
    const weekAvgDuration = weekLogs.length > 0 
      ? weekLogs.reduce((sum, log) => sum + log.sleep_duration_minutes, 0) / weekLogs.length 
      : 0;
    
    const weekAvgQuality = weekLogs.length > 0
      ? weekLogs.filter(log => log.sleep_quality).reduce((sum, log) => sum + log.sleep_quality, 0) / weekLogs.filter(log => log.sleep_quality).length
      : 0;
    
    // Calculate consistency score
    const consistencyScore = calculateConsistencyScore(weekLogs);
    
    res.json({
      summary: {
        streak,
        weeklyAverage: {
          durationMinutes: Math.round(weekAvgDuration),
          durationHours: Math.round((weekAvgDuration / 60) * 10) / 10,
          quality: weekAvgQuality ? Math.round(weekAvgQuality * 10) / 10 : null
        },
        monthlyLogs: monthLogs.length,
        weeklyLogs: weekLogs.length,
        consistencyScore,
        sleepGoalHours: user.sleep_goal_hours,
        goalAchievementRate: monthLogs.length > 0
          ? Math.round((monthLogs.filter(log => log.sleep_duration_minutes >= user.sleep_goal_hours * 60).length / monthLogs.length) * 100)
          : 0
      }
    });
    
  } catch (error) {
    console.error('Summary error:', error);
    res.status(500).json({
      error: 'Internal Server Error',
      message: 'Failed to get summary'
    });
  }
});

/**
 * Calculate sleep consistency score (0-100)
 */
function calculateConsistencyScore(logs) {
  if (logs.length < 2) return 50;
  
  // Extract hours of bedtime and wake time
  const bedtimes = logs.map(log => {
    const date = new Date(log.bedtime);
    let hours = date.getHours() + date.getMinutes() / 60;
    // Normalize: if after midnight, add 24
    if (hours < 12) hours += 24;
    return hours;
  });
  
  const wakeTimes = logs.map(log => {
    const date = new Date(log.wake_time);
    return date.getHours() + date.getMinutes() / 60;
  });
  
  // Calculate standard deviation
  const bedtimeStdDev = calculateStdDev(bedtimes);
  const wakeTimeStdDev = calculateStdDev(wakeTimes);
  
  // Lower std dev = more consistent = higher score
  // 1 hour std dev = 0 score, 0 std dev = 100 score
  const bedtimeScore = Math.max(0, 100 - (bedtimeStdDev * 10));
  const wakeTimeScore = Math.max(0, 100 - (wakeTimeStdDev * 10));
  
  return Math.round((bedtimeScore + wakeTimeScore) / 2);
}

function calculateStdDev(arr) {
  const avg = arr.reduce((sum, val) => sum + val, 0) / arr.length;
  const squareDiffs = arr.map(val => Math.pow(val - avg, 2));
  const avgSquareDiff = squareDiffs.reduce((sum, val) => sum + val, 0) / squareDiffs.length;
  return Math.sqrt(avgSquareDiff);
}

module.exports = router;
