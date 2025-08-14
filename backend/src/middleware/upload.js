const multer = require('multer');
const path = require('path');
const fs = require('fs');

const MAX_FILE_SIZE = parseInt(process.env.MAX_FILE_SIZE || (5 * 1024 * 1024), 10); // 5MB default
const UPLOAD_ROOT = process.env.UPLOAD_PATH || path.join(process.cwd(), 'uploads');

function ensureDir(dirPath) {
  if (!fs.existsSync(dirPath)) {
    fs.mkdirSync(dirPath, { recursive: true });
  }
}

const imageFileFilter = (req, file, cb) => {
  const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif'];
  if (!allowed.includes(file.mimetype)) {
    return cb(new Error('Only image files are allowed (jpeg, png, webp, gif)'));
  }
  cb(null, true);
};

// Per-service destination: uploads/services/<serviceId>
const serviceImagesStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    const serviceId = req.params.id || 'unknown';
    const dest = path.join(UPLOAD_ROOT, 'services', serviceId);
    ensureDir(dest);
    cb(null, dest);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname) || '.jpg';
    const base = path.basename(file.originalname, ext).replace(/[^a-zA-Z0-9_-]/g, '');
    const stamp = Date.now();
    cb(null, `${base || 'img'}_${stamp}${ext}`);
  }
});

const uploadServiceImages = multer({
  storage: serviceImagesStorage,
  fileFilter: imageFileFilter,
  limits: { fileSize: MAX_FILE_SIZE, files: 10 }
});

module.exports = { uploadServiceImages };
