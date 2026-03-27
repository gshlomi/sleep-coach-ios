/**
 * Sleep Coach Backend - Express API Server
 * 
 * This is the main entry point for the Sleep Coach API.
 * It handles user authentication, sleep logging, and personalized insights.
 * 
 * @author Sleep Coach Team
 * @version 1.0.0
 */

require('dotenv').config();
const express = require('express');
const cors = require('cors');
const path = require('path');

// Import routes
const usersRouter = require('./routes/users');
const sleepRouter = require('./routes/sleep');
const insightsRouter = require('./routes/insights');

// Import services
const { initDatabase } = require('./services/database');

const app = express();
const PORT = process.env.PORT || 3000;

// Middleware
app.use(cors({
  origin: '*', // In production, restrict to specific origins
  methods: ['GET', 'POST', 'PUT', 'DELETE', 'OPTIONS'],
  allowedHeaders: ['Content-Type', 'Authorization']
}));
app.use(express.json());
app.use(express.urlencoded({ extended: true }));

// Request logging middleware
app.use((req, res, next) => {
  const timestamp = new Date().toISOString();
  console.log(`[${timestamp}] ${req.method} ${req.path}`);
  next();
});

// Health check endpoint
app.get('/health', (req, res) => {
  res.json({
    status: 'healthy',
    timestamp: new Date().toISOString(),
    version: '1.0.0'
  });
});

// API Routes
app.use('/api/users', usersRouter);
app.use('/api/sleep', sleepRouter);
app.use('/api/insights', insightsRouter);

// Root API endpoint
app.get('/api', (req, res) => {
  res.json({
    name: 'Sleep Coach API',
    version: '1.0.0',
    endpoints: {
      users: '/api/users',
      sleep: '/api/sleep',
      insights: '/api/insights'
    }
  });
});

// 404 handler
app.use((req, res) => {
  res.status(404).json({
    error: 'Not Found',
    message: `Route ${req.method} ${req.path} not found`,
    timestamp: new Date().toISOString()
  });
});

// Error handler
app.use((err, req, res, next) => {
  console.error(`[ERROR] ${err.message}`);
  console.error(err.stack);
  
  res.status(err.status || 500).json({
    error: err.name || 'Internal Server Error',
    message: process.env.NODE_ENV === 'production' 
      ? 'An unexpected error occurred' 
      : err.message,
    timestamp: new Date().toISOString()
  });
});

// Initialize database and start server
async function startServer() {
  try {
    console.log('🚀 Initializing Sleep Coach Backend...');
    
    // Initialize database
    await initDatabase();
    console.log('✅ Database initialized');
    
    // Start server
    app.listen(PORT, () => {
      console.log(`
╔═══════════════════════════════════════════════════════════╗
║                                                           ║
║   🌙  Sleep Coach Backend Started Successfully  🌙        ║
║                                                           ║
║   Server:  http://localhost:${PORT}                        ║
║   Health:  http://localhost:${PORT}/health                  ║
║   API:     http://localhost:${PORT}/api                     ║
║                                                           ║
║   Environment: ${process.env.NODE_ENV || 'development'}                          ║
║                                                           ║
╚═══════════════════════════════════════════════════════════╝
      `);
    });
  } catch (error) {
    console.error('❌ Failed to start server:', error);
    process.exit(1);
  }
}

startServer();

module.exports = app;
