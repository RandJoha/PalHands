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
    return cb(new Error(`Invalid file type: ${file.mimetype}. Only JPEG, PNG, WebP, and GIF files are allowed.`));
  }
  
  // Check file size
  if (file.size && file.size > MAX_FILE_SIZE) {
    const maxSizeMB = Math.round(MAX_FILE_SIZE / (1024 * 1024));
    return cb(new Error(`File too large: ${Math.round(file.size / (1024 * 1024))}MB. Maximum allowed size is ${maxSizeMB}MB.`));
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
  limits: { 
    fileSize: MAX_FILE_SIZE, 
    files: 10,
    fieldSize: MAX_FILE_SIZE 
  }
}).array('images', 10);

// Enhanced error handling wrapper
const uploadServiceImagesWithErrorHandling = (req, res, next) => {
  uploadServiceImages(req, res, (err) => {
    if (err instanceof multer.MulterError) {
      if (err.code === 'LIMIT_FILE_SIZE') {
        const maxSizeMB = Math.round(MAX_FILE_SIZE / (1024 * 1024));
        return res.status(413).json({
          success: false,
          message: `File too large. Maximum allowed size is ${maxSizeMB}MB.`
        });
      }
      if (err.code === 'LIMIT_FILE_COUNT') {
        return res.status(413).json({
          success: false,
          message: 'Too many files. Maximum 10 images allowed.'
        });
      }
      if (err.code === 'LIMIT_UNEXPECTED_FILE') {
        return res.status(400).json({
          success: false,
          message: 'Unexpected file field. Use "images" field for file uploads.'
        });
      }
      return res.status(400).json({
        success: false,
        message: `Upload error: ${err.message}`
      });
    } else if (err) {
      return res.status(400).json({
        success: false,
        message: err.message
      });
    }
    next();
  });
};

module.exports = { uploadServiceImages: uploadServiceImagesWithErrorHandling };

// Reports evidence: uploads/reports/<reportId>
const evidenceFileFilter = (req, file, cb) => {
  const allowed = ['image/jpeg', 'image/png', 'image/webp', 'image/gif', 'application/pdf'];
  if (!allowed.includes(file.mimetype)) {
    return cb(new Error(`Invalid file type: ${file.mimetype}. Only images (JPEG, PNG, WebP, GIF) and PDF files are allowed for evidence.`));
  }
  
  // Check file size
  if (file.size && file.size > MAX_FILE_SIZE) {
    const maxSizeMB = Math.round(MAX_FILE_SIZE / (1024 * 1024));
    return cb(new Error(`File too large: ${Math.round(file.size / (1024 * 1024))}MB. Maximum allowed size is ${maxSizeMB}MB.`));
  }
  
  cb(null, true);
};

const reportEvidenceStorage = multer.diskStorage({
  destination: function (req, file, cb) {
    const reportId = req.params.id || 'unknown';
    const dest = path.join(UPLOAD_ROOT, 'reports', reportId);
    ensureDir(dest);
    cb(null, dest);
  },
  filename: function (req, file, cb) {
    const ext = path.extname(file.originalname) || '.bin';
    const base = path.basename(file.originalname, ext).replace(/[^a-zA-Z0-9_-]/g, '');
    const stamp = Date.now();
    cb(null, `${base || 'evidence'}_${stamp}${ext}`);
  }
});

const uploadReportEvidence = multer({
  storage: reportEvidenceStorage,
  fileFilter: evidenceFileFilter,
  limits: { 
    fileSize: MAX_FILE_SIZE, 
    files: 10,
    fieldSize: MAX_FILE_SIZE 
  }
});

module.exports.uploadReportEvidence = uploadReportEvidence;
