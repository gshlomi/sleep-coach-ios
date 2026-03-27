/**
 * Insight Generator Service - Personalized sleep recommendations
 * 
 * @author Sleep Coach Team
 */

/**
 * Generate personalized insights and recommendations based on sleep data
 * 
 * @param {Array} logs - Sleep logs
 * @param {Array} taskCompletions - Pre-sleep task completions
 * @param {Object} user - User profile
 * @returns {Array} Array of insight objects
 */
function generateInsights(logs, taskCompletions, user) {
  const insights = [];
  
  if (!logs || logs.length < 3) {
    insights.push({
      type: 'info',
      priority: 'high',
      title: 'Start logging your sleep',
      titleHe: 'התחל לתעד את השינה שלך',
      description: 'Log at least 3 nights of sleep to receive personalized insights.',
      descriptionHe: 'תעד לפחות 3 לילות של שינה כדי לקבל תובנות מותאמות אישית.',
      action: 'log_sleep'
    });
    return insights;
  }
  
  // Analyze and generate insights
  const taskInsight = analyzeTaskInsight(logs, taskCompletions);
  if (taskInsight) insights.push(taskInsight);
  
  const weekendInsight = analyzeWeekendVsWeekday(logs);
  if (weekendInsight) insights.push(weekendInsight);
  
  const screenInsight = analyzeScreenImpact(logs);
  if (screenInsight) insights.push(screenInsight);
  
  const qualityInsight = analyzeQualityPatterns(logs);
  if (qualityInsight) insights.push(qualityInsight);
  
  const durationInsight = analyzeDurationPatterns(logs, user);
  if (durationInsight) insights.push(durationInsight);
  
  const timingInsight = analyzeTimingPatterns(logs);
  if (timingInsight) insights.push(timingInsight);
  
  // Sort by priority
  const priorityOrder = { high: 0, medium: 1, low: 2 };
  insights.sort((a, b) => priorityOrder[a.priority] - priorityOrder[b.priority]);
  
  return insights;
}

/**
 * Analyze the impact of pre-sleep tasks on sleep quality
 */
function analyzeTaskInsight(logs, taskCompletions) {
  if (taskCompletions.length === 0) {
    return {
      type: 'recommendation',
      priority: 'high',
      title: 'Complete your pre-sleep routine',
      titleHe: 'השלם את שגרת הקינון',
      description: 'Users who complete pre-sleep tasks report 25% better sleep quality on average.',
      descriptionHe: 'משתמשים שמשלימים משימות לפני השינה מדווחים על איכות שינה טובה יותר ב-25% בממוצע.',
      action: 'enable_tasks'
    };
  }
  
  const taskTypes = ['screen_shutdown', 'wind_down', 'worry_list', 'breathing', 'cognitive_shuffle'];
  let bestTask = null;
  let bestImpact = 0;
  
  taskTypes.forEach(taskType => {
    const taskLogs = taskCompletions.filter(tc => tc.task_type === taskType);
    const taskLogIds = new Set(taskLogs.map(t => t.sleep_log_id).filter(Boolean));
    
    const logsWithTask = logs.filter(log => taskLogIds.has(log.id));
    const logsWithoutTask = logs.filter(log => !taskLogIds.has(log.id));
    
    if (logsWithTask.length >= 2 && logsWithoutTask.length >= 2) {
      const avgQualityWith = logsWithTask.filter(l => l.sleep_quality).reduce((sum, l) => sum + l.sleep_quality, 0) / logsWithTask.filter(l => l.sleep_quality).length;
      const avgQualityWithout = logsWithoutTask.filter(l => l.sleep_quality).reduce((sum, l) => sum + l.sleep_quality, 0) / logsWithoutTask.filter(l => l.sleep_quality).length;
      
      const impact = avgQualityWith - avgQualityWithout;
      if (impact > bestImpact) {
        bestImpact = impact;
        bestTask = taskType;
      }
    }
  });
  
  if (bestTask && bestImpact > 0.3) {
    const taskNames = {
      screen_shutdown: { en: 'Screen Shutdown', he: 'כיבוי מסכים' },
      wind_down: { en: 'Wind Down Routine', he: 'שגרת הרגעה' },
      worry_list: { en: 'Worry List Journaling', he: 'כתיבת רשימת דאגות' },
      breathing: { en: 'Breathing Exercises', he: 'תרגילי נשימה' },
      cognitive_shuffle: { en: 'Cognitive Shuffling', he: 'ערבוב קוגניטיבי' }
    };
    
    const impactPercent = Math.round(bestImpact * 20);
    
    return {
      type: 'positive',
      priority: 'medium',
      title: `${taskNames[bestTask].en} improves your sleep by ${impactPercent}%`,
      titleHe: `${taskNames[bestTask].he} משפר את השינה שלך ב-${impactPercent}%`,
      description: `You sleep ${impactPercent}% better when you complete the ${taskNames[bestTask].en.toLowerCase()} exercise.`,
      descriptionHe: `אתה ישן ${impactPercent}% יותר טוב כשאתה משלים את תרגיל ה${taskNames[bestTask].he.toLowerCase()}.`,
      action: `task_${bestTask}`
    };
  }
  
  return null;
}

/**
 * Analyze weekend vs weekday sleep patterns
 */
function analyzeWeekendVsWeekday(logs) {
  const weekendLogs = logs.filter(log => {
    const day = new Date(log.bedtime).getDay();
    return day === 0 || day === 6; // Sunday or Saturday
  });
  
  const weekdayLogs = logs.filter(log => {
    const day = new Date(log.bedtime).getDay();
    return day !== 0 && day !== 6;
  });
  
  if (weekendLogs.length < 2 || weekdayLogs.length < 2) return null;
  
  const weekendAvg = weekendLogs.reduce((sum, l) => sum + l.sleep_duration_minutes, 0) / weekendLogs.length;
  const weekdayAvg = weekdayLogs.reduce((sum, l) => sum + l.sleep_duration_minutes, 0) / weekdayLogs.length;
  
  const diffHours = Math.round((weekendAvg - weekdayAvg) / 60 * 10) / 10;
  
  if (diffHours > 1) {
    return {
      type: 'insight',
      priority: 'medium',
      title: `Weekend sleep is ${diffHours}h longer than weekdays`,
      titleHe: `שינת סוף שבוע ארוכה ב-${diffHours} שעות מימות החול`,
      description: 'This pattern may cause social jetlag. Try adjusting your weekday bedtime slightly.',
      descriptionHe: "דפוס זה עלול לגרום לג'ט לג חברתי. נסה להתאים את שעת השינה בימות החול.",
      action: 'adjust_schedule'
    };
  }
  
  if (diffHours < -1) {
    return {
      type: 'insight',
      priority: 'low',
      title: `You sleep ${Math.abs(diffHours)}h less on weekends`,
      titleHe: `אתה ישן ${Math.abs(diffHours)} שעות פחות בסוף השבוע`,
      description: 'This is unusual! Are you sleeping enough on weekends?',
      descriptionHe: 'זה לא רגיל! האם אתה ישן מספיק בסוף השבוע?',
      action: 'check_sleep'
    };
  }
  
  return null;
}

/**
 * Analyze screen usage impact (inferred from notes or patterns)
 */
function analyzeScreenImpact(logs) {
  // Look for patterns where late night activity correlates with poor sleep
  // This is simplified - in production, would analyze screen time data
  
  const lateNightLogs = logs.filter(log => {
    const bedtime = new Date(log.bedtime);
    return bedtime.getHours() >= 23;
  });
  
  const earlyLogs = logs.filter(log => {
    const bedtime = new Date(log.bedtime);
    return bedtime.getHours() < 23;
  });
  
  if (lateNightLogs.length < 2 || earlyLogs.length < 2) return null;
  
  const lateNightQuality = lateNightLogs.filter(l => l.sleep_quality).reduce((sum, l) => sum + l.sleep_quality, 0) / lateNightLogs.filter(l => l.sleep_quality).length;
  const earlyQuality = earlyLogs.filter(l => l.sleep_quality).reduce((sum, l) => sum + l.sleep_quality, 0) / earlyLogs.filter(l => l.sleep_quality).length;
  
  const impact = earlyQuality - lateNightQuality;
  
  if (impact > 0.5) {
    const percent = Math.round(impact * 20);
    return {
      type: 'warning',
      priority: 'high',
      title: `Sleep quality drops ${percent}% when you sleep after 23:00`,
      titleHe: `איכות השינה יורדת ב-${percent}% כשאתה ישן אחרי 23:00`,
      description: 'Going to bed earlier correlates with significantly better sleep quality.',
      descriptionHe: 'ללכת לישון מוקדם יותר קשור לאיכות שינה טובה משמעותית.',
      action: 'earlier_bedtime'
    };
  }
  
  return null;
}

/**
 * Analyze sleep quality patterns
 */
function analyzeQualityPatterns(logs) {
  const qualities = logs.filter(l => l.sleep_quality).map(l => l.sleep_quality);
  if (qualities.length < 5) return null;
  
  const avg = qualities.reduce((sum, q) => sum + q, 0) / qualities.length;
  const lowQualityDays = qualities.filter(q => q <= 2).length;
  const highQualityDays = qualities.filter(q => q >= 4).length;
  
  if (avg < 3 && lowQualityDays > highQualityDays) {
    return {
      type: 'concern',
      priority: 'high',
      title: 'Your sleep quality has been consistently low',
      titleHe: 'איכות השינה שלך הייתה נמוכה באופן עקבי',
      description: 'Consider reviewing your sleep hygiene and pre-sleep routine. A sleep study may be helpful.',
      descriptionHe: 'שקול לבחון את היגיינת השינה שלך ואת שגרת הקינון. מחקר שינה עשוי להיות מועיל.',
      action: 'improve_sleep_hygiene'
    };
  }
  
  if (avg >= 4 && highQualityDays > lowQualityDays * 2) {
    return {
      type: 'positive',
      priority: 'low',
      title: 'Excellent sleep quality recently!',
      titleHe: 'איכות שינה מצוינת לאחרונה!',
      description: 'Keep up the great work! Your sleep habits are paying off.',
      descriptionHe: 'המשך כך! הרגלי השינה שלך משתלמים.',
      action: 'maintain_habits'
    };
  }
  
  return null;
}

/**
 * Analyze sleep duration patterns
 */
function analyzeDurationPatterns(logs, user) {
  const goalMinutes = (user.sleep_goal_hours || 8) * 60;
  const durations = logs.map(l => l.sleep_duration_minutes);
  
  const avgDuration = durations.reduce((sum, d) => sum + d, 0) / durations.length;
  const shortNights = durations.filter(d => d < goalMinutes * 0.85).length;
  const longNights = durations.filter(d => d > goalMinutes * 1.2).length;
  
  if (shortNights > durations.length * 0.5) {
    const deficitHours = Math.round((goalMinutes - avgDuration) / 60 * 10) / 10;
    return {
      type: 'warning',
      priority: 'high',
      title: `You're averaging ${deficitHours}h less sleep than your goal`,
      titleHe: `אתה ממוצע ${deficitHours} שעות פחות שינה מהמטרה שלך`,
      description: 'Chronic sleep deprivation affects memory, mood, and health. Try going to bed 30 minutes earlier.',
      descriptionHe: 'חסך כרוני בשינה משפיע על זיכרון, מצב רוח ובריאות. נסה ללכת לישון 30 דקות מוקדם יותר.',
      action: 'earlier_bedtime'
    };
  }
  
  if (longNights > durations.length * 0.5 && avgDuration > goalMinutes * 1.3) {
    return {
      type: 'info',
      priority: 'low',
      title: 'You may be sleeping too much',
      titleHe: 'אתה עלול לישון יותר מדי',
      description: 'Oversleeping can sometimes indicate underlying health issues or poor sleep quality.',
      descriptionHe: 'שינה מופרזת יכולה להעיד על בעיות בריאותיות או איכות שינה ירודה.',
      action: 'check_quality'
    };
  }
  
  return null;
}

/**
 * Analyze sleep timing patterns
 */
function analyzeTimingPatterns(logs) {
  // Calculate average bedtime and wake time
  const bedtimes = logs.map(log => {
    const date = new Date(log.bedtime);
    let hours = date.getHours() + date.getMinutes() / 60;
    if (hours < 12) hours += 24; // Normalize for night owls
    return hours;
  });
  
  const wakeTimes = logs.map(log => {
    const date = new Date(log.wake_time);
    return date.getHours() + date.getMinutes() / 60;
  });
  
  const avgBedtime = bedtimes.reduce((sum, h) => sum + h, 0) / bedtimes.length;
  const avgWakeTime = wakeTimes.reduce((sum, h) => sum + h, 0) / wakeTimes.length;
  
  // Format bedtime
  const bedtimeHour = Math.round(avgBedtime) % 24;
  const bedtimeMin = Math.round((avgBedtime % 1) * 60);
  
  if (bedtimeHour >= 0 && bedtimeHour < 5) {
    return {
      type: 'recommendation',
      priority: 'medium',
      title: 'Your average bedtime is very late',
      titleHe: 'שעת השינה הממוצעת שלך מאוחרת מאוד',
      description: 'Going to bed before midnight maximizes sleep quality. Try a gradual earlier schedule.',
      descriptionHe: 'ללכת לישון לפני חצות מקסם את איכות השינה. נסה לוח זמנים הדרגתי מוקדם יותר.',
      action: 'adjust_bedtime'
    };
  }
  
  if (avgWakeTime < 6) {
    return {
      type: 'info',
      priority: 'low',
      title: 'You wake up very early',
      titleHe: 'אתה מתעורר מאוד מוקדם',
      description: 'If you feel rested, this may be fine. If not, consider whether you\'re getting enough sleep.',
      descriptionHe: 'אם אתה מרגיש רענן, זה בסדר. אם לא, שקול האם אתה ישן מספיק.',
      action: 'check_duration'
    };
  }
  
  return null;
}

module.exports = {
  generateInsights
};
