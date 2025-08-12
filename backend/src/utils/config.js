const envalid = require('envalid');
const { str, url, port, bool } = envalid;

function validateEnv() {
  // Optional Atlas URL uses 'url' but Mongo URI is not strictly URL per spec; use str
  return envalid.cleanEnv(process.env, {
    NODE_ENV: str({ default: 'development' }),
    PORT: port({ default: 3000 }),
    MONGODB_URI: str(),
    JWT_SECRET: str(),
    JWT_EXPIRES_IN: str({ default: '7d' }),
    CORS_ORIGIN: str({ default: 'http://localhost:3000,http://localhost:8080' }),
    ENABLE_EMAIL_VERIFICATION: bool({ default: false })
  });
}

module.exports = { validateEnv };
