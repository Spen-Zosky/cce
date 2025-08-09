#!/usr/bin/env node
/**
 * CCE Web Server - Simplified Bootstrap
 * This server points to the existing full-featured dashboard
 */

const express = require('express');
const path = require('path');
const fs = require('fs');

const app = express();
const PORT = process.env.CCE_WEB_PORT || 3456;

// Check if full dashboard exists
const dashboardPath = path.join(process.env.HOME, '.cce-universal/web/dashboard/build');
const hasFullDashboard = fs.existsSync(dashboardPath);

if (hasFullDashboard) {
    // Serve full dashboard if available
    app.use(express.static(dashboardPath));
    
    app.get('*', (req, res) => {
        res.sendFile(path.join(dashboardPath, 'index.html'));
    });
    
    console.log(`🚀 CCE Full Dashboard running at http://localhost:${PORT}`);
} else {
    // Serve basic placeholder
    app.get('/', (req, res) => {
        res.send(`
<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>CCE Dashboard</title>
    <style>
        * { margin: 0; padding: 0; box-sizing: border-box; }
        body {
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, sans-serif;
            background: linear-gradient(135deg, #667eea 0%, #764ba2 100%);
            min-height: 100vh;
            display: flex;
            align-items: center;
            justify-content: center;
            color: white;
        }
        .container {
            text-align: center;
            padding: 2rem;
            background: rgba(255, 255, 255, 0.1);
            backdrop-filter: blur(10px);
            border-radius: 20px;
            box-shadow: 0 8px 32px rgba(0, 0, 0, 0.1);
        }
        h1 { font-size: 3rem; margin-bottom: 1rem; }
        p { font-size: 1.2rem; opacity: 0.9; margin-bottom: 2rem; }
        .status { 
            padding: 1rem 2rem;
            background: rgba(255, 255, 255, 0.2);
            border-radius: 10px;
            margin-top: 1rem;
        }
        .badge {
            display: inline-block;
            padding: 0.3rem 0.8rem;
            background: #10b981;
            border-radius: 20px;
            font-size: 0.9rem;
            margin: 0.5rem;
        }
    </style>
</head>
<body>
    <div class="container">
        <h1>🚀 CCE Dashboard</h1>
        <p>Web Interface Ready</p>
        <div class="status">
            <div class="badge">✓ Server Running</div>
            <div class="badge">✓ Core Installed</div>
        </div>
        <p style="margin-top: 2rem; font-size: 1rem; opacity: 0.7;">
            Full dashboard available when web components are built.<br>
            Run <code>cce-web dev</code> for development mode.
        </p>
    </div>
</body>
</html>
        `);
    });
    
    console.log(`🚀 CCE Basic Dashboard running at http://localhost:${PORT}`);
    console.log('💡 Install full dashboard with: cce-install --with-web');
}

app.listen(PORT, () => {
    console.log(`✅ Web server ready at http://localhost:${PORT}`);
});
