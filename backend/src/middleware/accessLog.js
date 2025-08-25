const fs = require('fs');
const path = require('path');
const morgan = require('morgan');
const rfs = require('rotating-file-stream');

const logsDir = path.join(__dirname, '../../logs');
if (!fs.existsSync(logsDir)) {
  fs.mkdirSync(logsDir, { recursive: true });
}

const accessLogStream = rfs.createStream('access.log', {
  interval: '1d', // rotate daily
  path: logsDir,
  compress: 'gzip',
  maxFiles: 14
});

// Common combined format; remove sensitive headers
const accessLog = morgan('combined', {
  stream: accessLogStream,
  skip: (req) => req.url.startsWith('/api/health') || req.url.startsWith('/api/livez') || req.url.startsWith('/api/readyz')
});

module.exports = { accessLog };
