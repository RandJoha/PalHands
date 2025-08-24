const pino = require('pino');
const pinoHttp = require('pino-http');
const { v4: uuidv4 } = require('uuid');

const redact = {
  paths: [
    'req.headers.authorization',
    'req.headers.cookie',
    'res.headers["set-cookie"]',
    'req.body.password',
    'req.body.token',
    'req.body.refreshToken'
  ],
  remove: true
};

const logger = pino({
  level: process.env.NODE_ENV === 'production' ? 'info' : 'debug',
  redact
});

const httpLogger = pinoHttp({
  logger,
  genReqId: (req) => req.headers['x-request-id'] || uuidv4(),
  customProps: (req) => ({ ip: req.ip }),
  autoLogging: true,
  redact
});

module.exports = { logger, httpLogger };
