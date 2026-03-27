/**
 * Database Service - SQLite initialization and utilities
 * 
 * @author Sleep Coach Team
 */

const Database = require('better-sqlite3');
const path = require('path');
const fs = require('fs');

// Database file path
const DB_PATH = process.env.DB_PATH || path.join(__dirname, '..', 'storage', 'sleep_coach.db');

// Ensure storage directory exists
const storageDir = path.dirname(DB_PATH);
if (!fs.existsSync(storageDir)) {
  fs.mkdirSync(storageDir, { recursive: true });
}

let db = null;

/**
 * Initialize the database with required tables
 */
function initDatabase() {
  return new Promise((resolve, reject) => {
    try {
      db = new Database(DB_PATH);
      
      // Enable foreign keys
      db.pragma('foreign_keys = ON');
      
      // Create users table
      db.exec(`
        CREATE TABLE IF NOT EXISTS users (
          id TEXT PRIMARY KEY,
          email TEXT UNIQUE NOT NULL,
          password_hash TEXT NOT NULL,
          name TEXT,
          planned_bedtime TEXT,
          planned_wake_time TEXT,
          sleep_goal_hours REAL DEFAULT 8.0,
          timezone TEXT DEFAULT 'Asia/Jerusalem',
          language TEXT DEFAULT 'he',
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          updated_at TEXT DEFAULT CURRENT_TIMESTAMP
        )
      `);
      
      // Create sleep_logs table
      db.exec(`
        CREATE TABLE IF NOT EXISTS sleep_logs (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          bedtime TEXT NOT NULL,
          wake_time TEXT NOT NULL,
          sleep_duration_minutes INTEGER NOT NULL,
          sleep_quality INTEGER CHECK(sleep_quality >= 1 AND sleep_quality <= 5),
          notes TEXT,
          pre_sleep_tasks_completed TEXT,
          healthkit_synced INTEGER DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      `);
      
      // Create pre_sleep_tasks table
      db.exec(`
        CREATE TABLE IF NOT EXISTS pre_sleep_tasks (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          task_type TEXT NOT NULL,
          minutes_before_bedtime INTEGER NOT NULL,
          is_enabled INTEGER DEFAULT 1,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      `);
      
      // Create task_completions table
      db.exec(`
        CREATE TABLE IF NOT EXISTS task_completions (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          sleep_log_id TEXT,
          task_type TEXT NOT NULL,
          completed_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
          FOREIGN KEY (sleep_log_id) REFERENCES sleep_logs(id) ON DELETE SET NULL
        )
      `);
      
      // Create insights table
      db.exec(`
        CREATE TABLE IF NOT EXISTS insights (
          id TEXT PRIMARY KEY,
          user_id TEXT NOT NULL,
          insight_type TEXT NOT NULL,
          title TEXT NOT NULL,
          description TEXT NOT NULL,
          impact_score REAL,
          is_read INTEGER DEFAULT 0,
          created_at TEXT DEFAULT CURRENT_TIMESTAMP,
          FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
        )
      `);
      
      // Create indexes for better query performance
      db.exec(`
        CREATE INDEX IF NOT EXISTS idx_sleep_logs_user_id ON sleep_logs(user_id);
        CREATE INDEX IF NOT EXISTS idx_sleep_logs_bedtime ON sleep_logs(bedtime);
        CREATE INDEX IF NOT EXISTS idx_insights_user_id ON insights(user_id);
        CREATE INDEX IF NOT EXISTS idx_task_completions_user_id ON task_completions(user_id);
      `);
      
      console.log('✅ Database tables created successfully');
      resolve(db);
    } catch (error) {
      console.error('❌ Database initialization failed:', error);
      reject(error);
    }
  });
}

/**
 * Get the database instance
 */
function getDatabase() {
  if (!db) {
    throw new Error('Database not initialized. Call initDatabase() first.');
  }
  return db;
}

/**
 * Close the database connection
 */
function closeDatabase() {
  if (db) {
    db.close();
    db = null;
  }
}

module.exports = {
  initDatabase,
  getDatabase,
  closeDatabase,
  DB_PATH
};
