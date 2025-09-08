const envalid = require('envalid');
const { str, url, port, bool, num } = envalid;

function validateEnv() {
  // Optional Atlas URL uses 'url' but Mongo URI is not strictly URL per spec; use str
  return envalid.cleanEnv(process.env, {
    NODE_ENV: str({ default: 'development' }),
    PORT: port({ default: 3000 }),
    MONGODB_URI: str({ default: 'mongodb://127.0.0.1:27017/palhands-dev' }),
    JWT_SECRET: str({ default: 'your-super-secret-jwt-key-change-this-in-production' }),
    JWT_EXPIRES_IN: str({ default: '7d' }),
    CORS_ORIGIN: str({ default: 'http://localhost:3000,http://localhost:8080' }),
  ENABLE_EMAIL_VERIFICATION: bool({ default: false }),
  // Storage config
  STORAGE_DRIVER: str({ default: 'local' }), // local | s3 | minio
  S3_BUCKET: str({ default: '' }),
  S3_REGION: str({ default: 'us-east-1' }),
  S3_ENDPOINT: str({ default: '' }),
  S3_ACCESS_KEY_ID: str({ default: '' }),
  S3_SECRET_ACCESS_KEY: str({ default: '' }),
  S3_FORCE_PATH_STYLE: bool({ default: false }),
  S3_SIGNED_URL_TTL: num({ default: 900 }), // seconds
  MAX_FILE_SIZE: num({ default: 5 * 1024 * 1024 }),
  UPLOAD_PATH: str({ default: './uploads' }),
  ENABLE_MEDIA_CLEANUP: bool({ default: false }),
  MEDIA_CLEANUP_INTERVAL_MIN: num({ default: 120 })
  });
}

module.exports = { validateEnv };
