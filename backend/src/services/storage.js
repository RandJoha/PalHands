const { S3Client, PutObjectCommand, HeadObjectCommand, ListObjectsV2Command, DeleteObjectsCommand } = require('@aws-sdk/client-s3');
const { getSignedUrl } = require('@aws-sdk/s3-request-presigner');
const path = require('path');
const { validateEnv } = require('../utils/config');

const env = validateEnv();

function createS3Client() {
  const isMinio = env.STORAGE_DRIVER === 'minio';
  const client = new S3Client({
    region: env.S3_REGION,
    endpoint: env.S3_ENDPOINT || undefined,
    forcePathStyle: isMinio || env.S3_FORCE_PATH_STYLE,
    credentials: env.S3_ACCESS_KEY_ID && env.S3_SECRET_ACCESS_KEY ? {
      accessKeyId: env.S3_ACCESS_KEY_ID,
      secretAccessKey: env.S3_SECRET_ACCESS_KEY
    } : undefined
  });
  return client;
}

const ALLOWED_IMAGE_TYPES = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];

function ensureAllowedFile({ contentType, size }) {
  if (!ALLOWED_IMAGE_TYPES.includes(contentType)) {
    const err = new Error('Invalid content type');
    err.statusCode = 400;
    throw err;
  }
  if (size && size > env.MAX_FILE_SIZE) {
    const err = new Error('File too large');
    err.statusCode = 413;
    throw err;
  }
}

async function getPresignedPutUrls({ serviceId, files }) {
  const client = createS3Client();
  const bucket = env.S3_BUCKET;
  const ttl = env.S3_SIGNED_URL_TTL;
  const results = [];
  for (const f of files) {
    ensureAllowedFile(f);
    const base = path.basename(f.filename).replace(/[^a-zA-Z0-9_.-]/g, '');
    const key = `services/${serviceId}/${Date.now()}_${base}`;
    const cmd = new PutObjectCommand({ Bucket: bucket, Key: key, ContentType: f.contentType });
    const putUrl = await getSignedUrl(client, cmd, { expiresIn: ttl });
    results.push({ key, putUrl });
  }
  return results;
}

async function objectExists(key) {
  const client = createS3Client();
  try {
    await client.send(new HeadObjectCommand({ Bucket: env.S3_BUCKET, Key: key }));
    return true;
  } catch (e) {
    return false;
  }
}

async function listKeysUnder(prefix) {
  const client = createS3Client();
  const out = [];
  let ContinuationToken;
  do {
    const resp = await client.send(new ListObjectsV2Command({ Bucket: env.S3_BUCKET, Prefix: prefix, ContinuationToken }));
    (resp.Contents || []).forEach((o) => out.push(o.Key));
    ContinuationToken = resp.IsTruncated ? resp.NextContinuationToken : undefined;
  } while (ContinuationToken);
  return out;
}

async function deleteKeys(keys) {
  if (!keys.length) return;
  const client = createS3Client();
  const chunks = [keys];
  for (const chunk of chunks) {
    await client.send(new DeleteObjectsCommand({ Bucket: env.S3_BUCKET, Delete: { Objects: chunk.map((k) => ({ Key: k })) } }));
  }
}

async function cleanupOrphansForService(service) {
  const prefix = `services/${service._id}/`;
  const keys = await listKeysUnder(prefix);
  const referenced = new Set((service.images || []).map((img) => (img.url || '').replace(/^.*services\//, 'services/')));
  const orphans = keys.filter((k) => !referenced.has(k));
  await deleteKeys(orphans);
  return { deleted: orphans.length };
}

module.exports = {
  createS3Client,
  getPresignedPutUrls,
  objectExists,
  cleanupOrphansForService,
  ALLOWED_IMAGE_TYPES
};
