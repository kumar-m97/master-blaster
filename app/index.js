'use strict';

const express = require('express');
const rateLimit = require('express-rate-limit');
const path = require('path');

const app = express();
const PORT = process.env.PORT || 3000;
const HOST = process.env.HOST || '0.0.0.0';

// Rate-limit all incoming requests to prevent abuse
const limiter = rateLimit({
  windowMs: 60 * 1000, // 1 minute
  max: 200,            // max 200 requests per window per IP
  standardHeaders: true,
  legacyHeaders: false,
});
app.use(limiter);

// Serve static files from the public directory
app.use(express.static(path.join(__dirname, 'public')));

// Health-check endpoint used by Kubernetes liveness / readiness probes
app.get('/health', (req, res) => {
  res.status(200).json({ status: 'healthy', timestamp: new Date().toISOString() });
});

// Readiness probe endpoint
app.get('/ready', (req, res) => {
  res.status(200).json({ status: 'ready', timestamp: new Date().toISOString() });
});

// Default route – serves the SPA entry point
app.get('*', (req, res) => {
  res.sendFile(path.join(__dirname, 'public', 'index.html'));
});

const server = app.listen(PORT, HOST, () => {
  console.log(`Server running at http://${HOST}:${PORT}`);
});

module.exports = server;
