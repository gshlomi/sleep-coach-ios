/**
 * Sleep Analyzer Service - Pattern analysis and sleep statistics
 * 
 * @author Sleep Coach Team
 */

/**
 * Analyze sleep patterns from sleep logs and task completions
 * 
 * @param {Array} logs - Sleep logs from database
 * @param {Array} taskCompletions - Pre-sleep task completions
 * @param {Object} user - User preferences
 * @returns {Object} Analysis results
 */
function analyzeSleepPatterns(logs, taskCompletions, user) {
  if (!logs || logs.length === 0) {
    return {
      hasData: false,
      message: 'No sleep data available for analysis'
    };
  }
  
  // Basic statistics
  const stats = calculateBasicStats(logs);
  
  // Day of week analysis
  const dayOfWeekAnalysis = analyzeDayOfWeek(logs);
  
  // Pre-sleep task effectiveness
  const taskEffectiveness = analyzeTaskEffectiveness(logs, taskCompletions);
  
  // Sleep quality trends
  const qualityTrend = calculateQualityTrend(logs);
  
  // Best and worst days
  const bestWorstDays = findBestWorstDays(logs);
  
  // Consistency score
  const consistencyScore = calculateConsistencyScore(logs);
  
  // Goal achievement
  const goalAchievement = calculateGoalAchievement(logs, user);
  
  return {
    hasData: true,
    statistics: stats,
    dayOfWeekAnalysis,
    taskEffectiveness,
    qualityTrend,
    bestWorstDays,
    consistencyScore,
    goalAchievement
  };
}

/**
 * Calculate basic sleep statistics
 */
function calculateBasicStats(logs) {
  const durations = logs.map(log => log.sleep_duration_minutes);
  const qualities = logs.filter(log => log.sleep_quality).map(log => log.sleep_quality);
  
  const avgDuration = durations.reduce((sum, d) => sum + d, 0) / durations.length;
  const avgQuality = qualities.length > 0 
    ? qualities.reduce((sum, q) => sum + q, 0) / qualities.length 
    : null;
  
  const minDuration = Math.min(...durations);
  const maxDuration = Math.max(...durations);
  
  const standardDev = calculateStdDev(durations);
  
  return {
    averageDurationMinutes: Math.round(avgDuration),
    averageDurationHours: Math.round((avgDuration / 60) * 100) / 100,
    averageQuality: avgQuality ? Math.round(avgQuality * 10) / 10 : null,
    minDurationMinutes: minDuration,
    maxDurationMinutes: maxDuration,
    standardDeviationMinutes: Math.round(standardDev),
    totalLogs: logs.length
  };
}

/**
 * Analyze sleep patterns by day of week
 */
function analyzeDayOfWeek(logs) {
  const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  const byDay = {};
  
  dayNames.forEach(day => {
    byDay[day] = { durations: [], qualities: [], count: 0 };
  });
  
  logs.forEach(log => {
    const date = new Date(log.bedtime);
    const day = dayNames[date.getDay()];
    byDay[day].durations.push(log.sleep_duration_minutes);
    if (log.sleep_quality) {
      byDay[day].qualities.push(log.sleep_quality);
    }
    byDay[day].count++;
  });
  
  const analysis = {};
  dayNames.forEach(day => {
    const data = byDay[day];
    if (data.count > 0) {
      analysis[day] = {
        count: data.count,
        averageDurationMinutes: Math.round(data.durations.reduce((sum, d) => sum + d, 0) / data.durations.length),
        averageDurationHours: Math.round((data.durations.reduce((sum, d) => sum + d, 0) / data.durations.length / 60) * 100) / 100,
        averageQuality: data.qualities.length > 0 
          ? Math.round((data.qualities.reduce((sum, q) => sum + q, 0) / data.qualities.length) * 10) / 10 
          : null
      };
    }
  });
  
  return analysis;
}

/**
 * Analyze effectiveness of pre-sleep tasks
 */
function analyzeTaskEffectiveness(logs, taskCompletions) {
  const taskTypes = ['screen_shutdown', 'wind_down', 'worry_list', 'breathing', 'cognitive_shuffle'];
  const effectiveness = {};
  
  taskTypes.forEach(taskType => {
    // Find logs where this task was completed
    const taskLogs = taskCompletions.filter(tc => tc.task_type === taskType);
    const taskLogIds = new Set(taskLogs.map(t => t.sleep_log_id).filter(Boolean));
    
    const logsWithTask = logs.filter(log => taskLogIds.has(log.id));
    const logsWithoutTask = logs.filter(log => !taskLogIds.has(log.id));
    
    // Calculate average quality with and without task
    const avgQualityWith = logsWithTask.filter(l => l.sleep_quality).length > 0
      ? logsWithTask.filter(l => l.sleep_quality).reduce((sum, l) => sum + l.sleep_quality, 0) / logsWithTask.filter(l => l.sleep_quality).length
      : null;
    
    const avgQualityWithout = logsWithoutTask.filter(l => l.sleep_quality).length > 0
      ? logsWithoutTask.filter(l => l.sleep_quality).reduce((sum, l) => sum + l.sleep_quality, 0) / logsWithoutTask.filter(l => l.sleep_quality).length
      : null;
    
    const avgDurationWith = logsWithTask.length > 0
      ? logsWithTask.reduce((sum, l) => sum + l.sleep_duration_minutes, 0) / logsWithTask.length
      : 0;
    
    const avgDurationWithout = logsWithoutTask.length > 0
      ? logsWithoutTask.reduce((sum, l) => sum + l.sleep_duration_minutes, 0) / logsWithoutTask.length
      : 0;
    
    effectiveness[taskType] = {
      timesCompleted: taskLogs.length,
      timesSkipped: logsWithoutTask.length,
      averageQualityWithTask: avgQualityWith ? Math.round(avgQualityWith * 10) / 10 : null,
      averageQualityWithoutTask: avgQualityWithout ? Math.round(avgQualityWithout * 10) / 10 : null,
      qualityImpact: (avgQualityWith && avgQualityWithout) 
        ? Math.round(((avgQualityWith - avgQualityWithout) / avgQualityWithout) * 100) 
        : null,
      averageDurationWithMinutes: Math.round(avgDurationWith),
      averageDurationWithoutMinutes: Math.round(avgDurationWithout),
      durationImpactMinutes: Math.round(avgDurationWith - avgDurationWithout)
    };
  });
  
  return effectiveness;
}

/**
 * Calculate sleep quality trend over time
 */
function calculateQualityTrend(logs) {
  if (logs.length < 3) {
    return { trend: 'insufficient_data', message: 'Need at least 3 sleep logs to determine trend' };
  }
  
  // Sort by date
  const sorted = [...logs].sort((a, b) => new Date(a.bedtime) - new Date(b.bedtime));
  
  // Calculate moving average (last 7 days or available)
  const recentCount = Math.min(7, Math.floor(sorted.length / 2));
  const olderCount = sorted.length - recentCount;
  
  if (olderCount < 2) {
    return { trend: 'insufficient_data', message: 'Need more historical data to determine trend' };
  }
  
  const olderLogs = sorted.slice(0, olderCount);
  const recentLogs = sorted.slice(-recentCount);
  
  const olderAvg = olderLogs.filter(l => l.sleep_quality).reduce((sum, l) => sum + l.sleep_quality, 0) / olderLogs.filter(l => l.sleep_quality).length;
  const recentAvg = recentLogs.filter(l => l.sleep_quality).reduce((sum, l) => sum + l.sleep_quality, 0) / recentLogs.filter(l => l.sleep_quality).length;
  
  const change = recentAvg - olderAvg;
  const percentChange = Math.round((change / olderAvg) * 100);
  
  return {
    trend: change > 0.2 ? 'improving' : change < -0.2 ? 'declining' : 'stable',
    change: Math.round(change * 10) / 10,
    percentChange,
    olderAverage: Math.round(olderAvg * 10) / 10,
    recentAverage: Math.round(recentAvg * 10) / 10
  };
}

/**
 * Find best and worst sleep days
 */
function findBestWorstDays(logs) {
  const dayNames = ['Sunday', 'Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday'];
  
  // Group by day of week
  const byDay = {};
  dayNames.forEach(day => {
    byDay[day] = { total: 0, count: 0, qualitySum: 0 };
  });
  
  logs.forEach(log => {
    const date = new Date(log.bedtime);
    const day = dayNames[date.getDay()];
    byDay[day].total += log.sleep_duration_minutes;
    byDay[day].count++;
    if (log.sleep_quality) {
      byDay[day].qualitySum += log.sleep_quality;
    }
  });
  
  // Calculate average scores (combining duration and quality)
  const dayScores = dayNames.map(day => {
    const data = byDay[day];
    if (data.count === 0) return { day, score: 0, hasData: false };
    
    const avgDuration = data.total / data.count;
    const avgQuality = data.qualitySum / data.count;
    // Score: 40% duration (normalized to 8h = perfect) + 60% quality (1-5 scale)
    const score = (Math.min(avgDuration / 480, 1) * 40) + ((avgQuality / 5) * 60);
    
    return { day, score: Math.round(score), hasData: true };
  }).filter(d => d.hasData);
  
  dayScores.sort((a, b) => b.score - a.score);
  
  return {
    bestDay: dayScores[0] || null,
    worstDay: dayScores[dayScores.length - 1] || null,
    ranking: dayScores
  };
}

/**
 * Calculate sleep consistency score (0-100)
 */
function calculateConsistencyScore(logs) {
  if (logs.length < 2) return 50;
  
  // Extract hours of bedtime and wake time
  const bedtimes = logs.map(log => {
    const date = new Date(log.bedtime);
    let hours = date.getHours() + date.getMinutes() / 60;
    // Normalize: if before noon, add 24 (assume night sleep)
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
  const durationStdDev = calculateStdDev(logs.map(l => l.sleep_duration_minutes));
  
  // Convert to scores (lower std dev = higher score)
  const bedtimeScore = Math.max(0, 100 - (bedtimeStdDev * 15));
  const wakeTimeScore = Math.max(0, 100 - (wakeTimeStdDev * 15));
  const durationScore = Math.max(0, 100 - (durationStdDev / 3));
  
  return Math.round((bedtimeScore + wakeTimeScore + durationScore) / 3);
}

/**
 * Calculate goal achievement rate
 */
function calculateGoalAchievement(logs, user) {
  if (logs.length === 0) return { rate: 0, achieved: 0, total: 0 };
  
  const goalMinutes = (user.sleep_goal_hours || 8) * 60;
  const achieved = logs.filter(log => log.sleep_duration_minutes >= goalMinutes).length;
  
  return {
    rate: Math.round((achieved / logs.length) * 100),
    achieved,
    total: logs.length,
    goalHours: user.sleep_goal_hours || 8
  };
}

/**
 * Calculate standard deviation
 */
function calculateStdDev(arr) {
  if (arr.length === 0) return 0;
  const avg = arr.reduce((sum, val) => sum + val, 0) / arr.length;
  const squareDiffs = arr.map(val => Math.pow(val - avg, 2));
  const avgSquareDiff = squareDiffs.reduce((sum, val) => sum + val, 0) / squareDiffs.length;
  return Math.sqrt(avgSquareDiff);
}

module.exports = {
  analyzeSleepPatterns,
  calculateBasicStats,
  analyzeDayOfWeek,
  analyzeTaskEffectiveness,
  calculateQualityTrend,
  findBestWorstDays,
  calculateConsistencyScore,
  calculateGoalAchievement
};
