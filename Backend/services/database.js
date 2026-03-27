/**
 * Database Service - SQLite initialization (sql.js for Vercel compatibility)
 * 
 * @author Sleep Coach Team
 */

const initSqlJs = require('sql.js');
const fs = require('fs');
const path = require('path');

// Database file path (for local development)
const DB_PATH = process.env.DB_PATH || path.join(__dirname, '..', 'storage', 'sleep_coach.db');

// In-memory database for serverless (Vercel)
let db = null;
let SQL = null;

/**
 * Initialize the database with required tables
 */
async function initDatabase() {
  try {
    SQL = await initSqlJs();
    
    // Try to load existing database from storage (local dev)
    const dbPath = DB_PATH;
    if (fs.existsSync(dbPath)) {
      const fileBuffer = fs.readFileSync(dbPath);
      db = new SQL.Database(fileBuffer);
      console.log('✅ Database loaded from storage');
    } else {
      // Create new in-memory database
      db = new SQL.Database();
      console.log('✅ New in-memory database created');
    }
    
    // Create tables
    db.run(`
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
        created_at TEXT DEFAULT (datetime('now')),
        updated_at TEXT DEFAULT (datetime('now'))
      )
    `);
    
    db.run(`
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
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);
    
    db.run(`
      CREATE TABLE IF NOT EXISTS pre_sleep_tasks (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        task_type TEXT NOT NULL,
        minutes_before_bedtime INTEGER NOT NULL,
        is_enabled INTEGER DEFAULT 1,
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);
    
    db.run(`
      CREATE TABLE IF NOT EXISTS task_completions (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        sleep_log_id TEXT,
        task_type TEXT NOT NULL,
        completed_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE,
        FOREIGN KEY (sleep_log_id) REFERENCES sleep_logs(id) ON DELETE SET NULL
      )
    `);
    
    db.run(`
      CREATE TABLE IF NOT EXISTS insights (
        id TEXT PRIMARY KEY,
        user_id TEXT NOT NULL,
        insight_type TEXT NOT NULL,
        title TEXT NOT NULL,
        description TEXT NOT NULL,
        impact_score REAL,
        is_read INTEGER DEFAULT 0,
        created_at TEXT DEFAULT (datetime('now')),
        FOREIGN KEY (user_id) REFERENCES users(id) ON DELETE CASCADE
      )
    `);
    
    // Create indexes
    db.run(`CREATE INDEX IF NOT EXISTS idx_sleep_logs_user_id ON sleep_logs(user_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_sleep_logs_bedtime ON sleep_logs(bedtime)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_insights_user_id ON insights(user_id)`);
    db.run(`CREATE INDEX IF NOT EXISTS idx_task_completions_user_id ON task_completions(user_id)`);
    
    // Save to file for local development
    if (!process.env.VERCEL) {
      const data = db.export();
      const buffer = Buffer.from(data);
      const storageDir = path.dirname(DB_PATH);
      if (!fs.existsSync(storageDir)) {
        fs.mkdirSync(storageDir, { recursive: true });
      }
      fs.writeFileSync(DB_PATH, buffer);
      console.log('💾 Database saved to storage');
    }
    
    console.log('✅ Database tables created successfully');
    return db;
  } catch (error) {
    console.error('❌ Database initialization failed:', error);
    throw error;
  }
}

/**
 * Save database to file (for local development)
 */
function saveDatabase() {
  if (!process.env.VERCEL && db) {
    try {
      const data = db.export();
      const buffer = Buffer.from(data);
      fs.writeFileSync(DB_PATH, buffer);
    } catch (error) {
      console.error('Failed to save database:', error);
    }
  }
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
    SQL = null;
  }
}

module.exports = {
  initDatabase,
  getDatabase,
  closeDatabase,
  saveDatabase,
  DB_PATH
};
