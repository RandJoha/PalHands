
# PalHands Backend Documentation

## 📋 Overview

**PalHands Backend** is a Node.js/Express API that provides authentication, user management, admin operations, and (planned) service, booking, payments, and reviews modules. It uses MongoDB via Mongoose and JWT-based authentication.

## 🏗️ Architecture Overview

```
backend/
├── src/
│   ├── app.js                 # Express app (middleware, routes, health, errors)
│   ├── config/
│   │   └── database.js        # Database connector (Atlas-only)
│   ├── controllers/
│   │   ├── authController.js  # Authentication logic
│   │   ├── userController.js  # User management
│   │   └── admin/
│   │       ├── dashboardController.js  # Admin dashboard + users/services/bookings mgmt (to be split)
│   │       ├── reportsController.js    # Admin reports & disputes
│   │       ├── settingsController.js   # System settings
│   │       ├── analyticsController.js  # Analytics & growth
│   │       └── actionsController.js    # Admin actions/audit log
│   ├── middleware/
│   │   ├── authMiddleware.js # Unified middleware (auth, roles, admin, permissions, logger)
│   │   ├── auth.js           # Re-exports from unified middleware
│   │   └── adminAuth.js      # Re-exports from unified middleware
│   ├── validators/           # Request/response schemas per route (Phase 0.5)
│   ├── policies/             # Central RBAC/ABAC helpers & authorization policies (Phase 1.5)
│   ├── models/
│   │   ├── User.js           # User schema
│   │   ├── Admin.js          # Admin schema
│   │   ├── AdminAction.js    # Audit logging
│   │   ├── Report.js         # User reports
│   │   ├── SystemSetting.js  # Platform settings
│   │   ├── Service.js        # Service schema
│   │   └── Booking.js        # Booking schema
│   ├── routes/
│   │   ├── auth.js           # Authentication routes
│   │   ├── users.js          # User management routes
│   │   └── admin.js          # Admin routes (overview, users, services, bookings, reports, settings, analytics, actions)
│   ├── services/             # External services (placeholder)
│   └── utils/                # Utility functions (placeholder)
├── uploads/                  # File uploads (Dev-only; in Prod use S3/MinIO + signed URLs)
├── logs/                     # Application logs
├── server.js                 # Server startup (central DB connect)
├── package.json              # Dependencies
└── env.example               # Environment variables template
```

## 🔧 Technology Stack

### Core Technologies (current)
- **Runtime**: Node.js (>=16.0.0)
- **Framework**: Express.js
- **Database**: MongoDB Atlas (Cloud)
- **ODM**: Mongoose
- **Authentication**: JWT (JSON Web Tokens)
- **Password Hashing**: bcryptjs
- **File Upload**: Multer
- **Email**: Nodemailer
- **Real-time**: Socket.io (installed, not yet initialized)

### Installed Dev/Runtime Dependencies
- express, mongoose, jsonwebtoken, bcryptjs, cors, dotenv, multer, nodemailer, socket.io
- helmet, compression, express-rate-limit, pino, pino-http, morgan, rotating-file-stream
- celebrate, joi, envalid, uuid
- dev: nodemon

### Security Hardening (Phase 0 — Implemented)
- helmet: Security headers (enabled)
- compression: Response compression (enabled)
- express-rate-limit: Rate limiting (global + auth/login) (enabled)
- pino + morgan: Structured HTTP/app logging with rotation (enabled)
- CORS allowlist from env (enabled)

## 🗄️ Database Configuration

### MongoDB Atlas Setup
- **Cluster**: PalHands (palhands.rtxny5x.mongodb.net)
- **Database**: palhands
- **Connection**: MongoDB Atlas cloud service
- **Authentication**: Username/password with IP whitelist

### Connection String Format
```
mongodb+srv://<username>:<password>@palhands.rtxny5x.mongodb.net/palhands?retryWrites=true&w=majority&appName=PalHands
```

### Environment Variables
```bash
# Database Configuration
MONGODB_URI=mongodb+srv://admindb:<password>@palhands.rtxny5x.mongodb.net/palhands?retryWrites=true&w=majority&appName=PalHands

# JWT Configuration
JWT_SECRET=your-super-secret-jwt-key-here
JWT_EXPIRES_IN=7d

# Server Configuration
PORT=3000
NODE_ENV=development

# Optional: Email Configuration
EMAIL_HOST=smtp.gmail.com
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password

# CORS Configuration
CORS_ORIGIN=http://localhost:8080,http://localhost:3000
```

## 📊 Database Models

### User Model (`src/models/User.js`)

```javascript
const userSchema = new mongoose.Schema({
  firstName: {
    type: String,
    required: [true, 'First name is required'],
    trim: true,
    maxlength: [50, 'First name cannot exceed 50 characters']
  },
  lastName: {
    type: String,
    default: '',
    trim: true,
    maxlength: [50, 'Last name cannot exceed 50 characters']
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true,
    match: [/^\w+([.-]?\w+)*@\w+([.-]?\w+)*(\.\w{2,3})+$/, 'Please enter a valid email']
  },
  phone: {
    type: String,
    required: [true, 'Phone number is required'],
    unique: true,
    match: [/^[\+]?[0-9\s\-\(\)]{8,15}$/, 'Please enter a valid phone number']
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [6, 'Password must be at least 6 characters'],
    select: false // Don't include password in queries by default
  },
  role: {
    type: String,
    enum: ['client', 'provider', 'admin'],
    default: 'client'
  },
  profileImage: {
    type: String,
    default: null
  },
  address: {
    street: String,
    city: String,
    area: String,
    coordinates: {
      latitude: Number,
      longitude: Number
    }
  },
  isVerified: {
    type: Boolean,
    default: false
  },
  isActive: {
    type: Boolean,
    default: true
  },
  rating: {
    average: {
      type: Number,
      default: 0,
      min: 0,
      max: 5
    },
    count: {
      type: Number,
      default: 0
    }
  }
}, {
  timestamps: true
});
```

Key Features:
- **Password Hashing**: Pre-save middleware using bcryptjs
- **Password Comparison**: Instance method for secure password verification
- **Validation**: Comprehensive input validation with custom error messages
- **Indexing**: Email and phone fields are indexed for performance
- **Timestamps**: Automatic createdAt and updatedAt fields

### Admin Model (`src/models/Admin.js`)

```javascript
const adminSchema = new mongoose.Schema({
  firstName: {
    type: String,
    required: [true, 'First name is required'],
    trim: true
  },
  lastName: {
    type: String,
    required: [true, 'Last name is required'],
    trim: true
  },
  email: {
    type: String,
    required: [true, 'Email is required'],
    unique: true,
    lowercase: true
  },
  password: {
    type: String,
    required: [true, 'Password is required'],
    minlength: [8, 'Password must be at least 8 characters'],
    select: false
  },
  role: {
    type: String,
    enum: ['admin', 'super_admin'],
    default: 'admin'
  },
  permissions: [{
    type: String,
    enum: ['user_management', 'service_management', 'booking_management', 'payment_management', 'system_settings']
  }],
  isActive: {
    type: Boolean,
    default: true
  },
  lastLogin: Date
}, {
  timestamps: true
});
```

### AdminAction Model (`src/models/AdminAction.js`)

```javascript
const adminActionSchema = new mongoose.Schema({
  admin: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin',
    required: true
  },
  action: {
    type: String,
    required: true,
    enum: ['create', 'update', 'delete', 'login', 'logout', 'export', 'import']
  },
  resource: {
    type: String,
    required: true,
    enum: ['user', 'service', 'booking', 'payment', 'system_setting', 'admin']
  },
  resourceId: mongoose.Schema.Types.ObjectId,
  details: {
    before: mongoose.Schema.Types.Mixed,
    after: mongoose.Schema.Types.Mixed,
    changes: [String]
  },
  ipAddress: String,
  userAgent: String
}, {
  timestamps: true
});
```

### Report Model (`src/models/Report.js`)

```javascript
const reportSchema = new mongoose.Schema({
  reporter: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  reportedUser: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'User',
    required: true
  },
  type: {
    type: String,
    required: true,
    enum: ['inappropriate_behavior', 'fake_profile', 'spam', 'harassment', 'other']
  },
  description: {
    type: String,
    required: true,
    maxlength: [1000, 'Description cannot exceed 1000 characters']
  },
  evidence: [{
    type: String,
    description: String
  }],
  status: {
    type: String,
    enum: ['pending', 'under_review', 'resolved', 'dismissed'],
    default: 'pending'
  },
  assignedAdmin: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin'
  },
  resolution: {
    action: String,
    notes: String,
    resolvedBy: {
      type: mongoose.Schema.Types.ObjectId,
      ref: 'Admin'
    },
    resolvedAt: Date
  }
}, {
  timestamps: true
});
```

### SystemSetting Model (`src/models/SystemSetting.js`)

```javascript
const systemSettingSchema = new mongoose.Schema({
  key: {
    type: String,
    required: true,
    unique: true
  },
  value: {
    type: mongoose.Schema.Types.Mixed,
    required: true
  },
  type: {
    type: String,
    enum: ['string', 'number', 'boolean', 'object', 'array'],
    required: true
  },
  description: String,
  category: {
    type: String,
    enum: ['general', 'security', 'payment', 'notification', 'feature'],
    default: 'general'
  },
  isPublic: {
    type: Boolean,
    default: false
  },
  updatedBy: {
    type: mongoose.Schema.Types.ObjectId,
    ref: 'Admin'
  }
}, {
  timestamps: true
});
```

## 🔐 Authentication System

### JWT Configuration
- **Secret**: Environment variable `JWT_SECRET`
- **Expiration**: 7 days (configurable via `JWT_EXPIRES_IN`)
- **Algorithm**: HS256
- **Payload**: Contains userId and role information

### Password Security
- **Hashing**: bcryptjs with salt rounds of 12
- **Comparison**: Secure password comparison method
- **Validation**: Minimum 6 characters for users, 8 for admins

### Authentication Flow

#### 1) User Registration
```javascript
// POST /api/auth/register
{
  "firstName": "John",
  "lastName": "Doe",
  "email": "john@example.com",
  "phone": "+1234567890",
  "password": "password123",
  "role": "client" // Optional, defaults to "client"
}
```

**Response:**
```javascript
{
  "success": true,
  "message": "User registered successfully",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "6887fd1606cd04bccd7ce3af",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "phone": "+1234567890",
    "role": "client",
    "isVerified": false,
    "isActive": true
  }
}
```

#### 2) User Login
```javascript
// POST /api/auth/login
{
  "email": "john@example.com",
  "password": "password123"
}
```

**Response:**
```javascript
{
  "success": true,
  "message": "Login successful",
  "token": "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9...",
  "user": {
    "_id": "6887fd1606cd04bccd7ce3af",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "role": "client",
    "isVerified": false,
    "isActive": true
  }
}
```

#### 3) Token Validation
```javascript
// GET /api/auth/validate
// Headers: Authorization: Bearer <token>
```

**Response:**
```javascript
{
  "valid": true,
  "user": {
    "_id": "6887fd1606cd04bccd7ce3af",
    "firstName": "John",
    "lastName": "Doe",
    "email": "john@example.com",
    "role": "client"
  }
}
```

#### 4) User Logout
```javascript
// POST /api/auth/logout
// Headers: Authorization: Bearer <token>
```

**Response:**
```javascript
{
  "success": true,
  "message": "Logout successful"
}
```

## 🛡️ Middleware System

### Authentication Middleware (`src/middleware/auth.js`)

#### auth Middleware
```javascript
const auth = async (req, res, next) => {
  try {
    // Get token from header
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.'
      });
    }

    // Verify token
    const decoded = jwt.verify(token, process.env.JWT_SECRET);

    // Find user
    const user = await User.findById(decoded.userId).select('-password');
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid token. User not found.'
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated.'
      });
    }

    // Add user info to request
    req.user = user;
    next();
  } catch (error) {
    console.error('Auth error:', error);
    res.status(401).json({
      success: false,
      message: 'Invalid token.'
    });
  }
};
```

#### checkRole Middleware
```javascript
const checkRole = (roles) => {
  return (req, res, next) => {
    if (!req.user) {
      return res.status(401).json({
        success: false,
        message: 'Authentication required.'
      });
    }

    // Check if user has required role
    if (!roles.includes(req.user.role)) {
      return res.status(403).json({
        success: false,
        message: `Access denied. ${roles.join(' or ')} role required.`
      });
    }

    next();
  };
};
```

#### requireVerification Middleware
```javascript
const requireVerification = (req, res, next) => {
  if (!req.user.isVerified) {
    return res.status(403).json({
      success: false,
      message: 'Account verification required.'
    });
  }
  next();
};
```

#### checkOwnership Middleware
```javascript
const checkOwnership = (modelName) => {
  return async (req, res, next) => {
    try {
      const Model = require(`../models/${modelName}`);
      const resource = await Model.findById(req.params.id);

      if (!resource) {
        return res.status(404).json({
          success: false,
          message: `${modelName} not found.`
        });
      }

      // Admin can access everything
      if (req.user.role === 'admin') {
        req.resource = resource;
        return next();
      }

      // Check if user owns the resource
      const ownerField = modelName === 'User' ? '_id' : 'user';
      if (resource[ownerField].toString() !== req.user._id.toString()) {
        return res.status(403).json({
          success: false,
          message: 'Access denied. You can only access your own resources.'
        });
      }

      req.resource = resource;
      next();
    } catch (error) {
      console.error('Ownership check error:', error);
      res.status(500).json({
        success: false,
        message: 'Internal server error.'
      });
    }
  };
};
```

### Admin Authentication Middleware (`src/middleware/adminAuth.js`)

```javascript
const adminAuth = async (req, res, next) => {
  try {
    const token = req.header('Authorization')?.replace('Bearer ', '');

    if (!token) {
      return res.status(401).json({
        success: false,
        message: 'Access denied. No token provided.'
      });
    }

    const decoded = jwt.verify(token, process.env.JWT_SECRET);
    const admin = await Admin.findById(decoded.adminId).select('-password');
    
    if (!admin || !admin.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Invalid or inactive admin account.'
      });
    }

    req.admin = admin;
    next();
  } catch (error) {
    console.error('Admin auth error:', error);
    res.status(401).json({
      success: false,
      message: 'Invalid admin token.'
    });
  }
};
```

## 🎯 API Endpoints

### Authentication Routes (`/api/auth`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/register` | Register new user | No |
| POST | `/login` | User login | No |
| POST | `/logout` | User logout | Yes |
| GET | `/validate` | Validate token | Yes |
| GET | `/profile` | Get user profile | Yes |

### User Management Routes (`/api/users`)

| Method | Endpoint | Description | Auth Required | Role Required |
|--------|----------|-------------|---------------|---------------|
| PUT | `/profile` | Update user profile | Yes | Any |
| PUT | `/change-password` | Change password | Yes | Any |
| GET | `/` | Get all users | Yes | Admin |
| GET | `/:id` | Get user by ID | Yes | Admin |
| PUT | `/:id/status` | Update user status | Yes | Admin |
| DELETE | `/:id` | Delete user | Yes | Admin |

### Admin Routes (`/api/admin`)

| Method | Endpoint | Description | Auth Required | Role Required |
|--------|----------|-------------|---------------|---------------|
| GET | `/dashboard/overview` | Dashboard KPIs and system health | Yes | Admin |
| GET | `/users` | List users with filters | Yes | Admin |
| PUT | `/users/:userId` | Update user status/role/verification | Yes | Admin |
| GET | `/services` | List services with filters | Yes | Admin |
| PUT | `/services/:serviceId` | Update service status/featured | Yes | Admin |
| GET | `/bookings` | List bookings with filters | Yes | Admin |
| PUT | `/bookings/:bookingId` | Update booking status/notes | Yes | Admin |
| GET | `/reports` | Get user reports | Yes | Admin |
| PUT | `/reports/:reportId` | Update report status/assignment/resolution | Yes | Admin |
| GET | `/settings` | Get system settings | Yes | Admin |
| PUT | `/settings/:key` | Update system setting value | Yes | Admin |
| GET | `/analytics` | Growth analytics (users, bookings, categories) | Yes | Admin |
| GET | `/actions` | Admin actions audit log | Yes | Admin |

Note: Public Services/Bookings/Payments/Reviews routes are not yet mounted in `app.js` (planned below). Admin routes above are implemented.

## 🔧 Controllers

### AuthController (`src/controllers/authController.js`)

#### register
```javascript
const register = async (req, res) => {
  try {
    const { firstName, lastName = '', email, phone, password, role = 'client' } = req.body;

    // Validate required fields and provide specific error messages
    const missingFields = [];
    if (!firstName) missingFields.push('firstName');
    if (!email) missingFields.push('email');
    if (!phone) missingFields.push('phone');
    if (!password) missingFields.push('password');

    if (missingFields.length > 0) {
      return res.status(400).json({
        success: false,
        message: `Missing required fields: ${missingFields.join(', ')}`
      });
    }

    // Check if user already exists
    const existingUser = await User.findOne({
      $or: [{ email }, { phone }]
    });

    if (existingUser) {
      return res.status(400).json({
        success: false,
        message: existingUser.email === email 
          ? 'Email already registered' 
          : 'Phone number already registered'
      });
    }

    // Create new user
    const user = new User({
      firstName,
      lastName,
      email,
      phone,
      password,
      role
    });

    await user.save();

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    // Remove password from response
    user.password = undefined;

    res.status(201).json({
      success: true,
      message: 'User registered successfully',
      token,
      user
    });
  } catch (error) {
    console.error('Registration error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};
```

#### login
```javascript
const login = async (req, res) => {
  try {
    const { email, password } = req.body;

    // Validate input
    if (!email || !password) {
      return res.status(400).json({
        success: false,
        message: 'Email and password are required'
      });
    }

    // Find user and include password for comparison
    const user = await User.findOne({ email }).select('+password');
    
    if (!user) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Check if user is active
    if (!user.isActive) {
      return res.status(401).json({
        success: false,
        message: 'Account is deactivated'
      });
    }

    // Verify password
    const isPasswordValid = await user.comparePassword(password);
    if (!isPasswordValid) {
      return res.status(401).json({
        success: false,
        message: 'Invalid email or password'
      });
    }

    // Generate JWT token
    const token = jwt.sign(
      { userId: user._id },
      process.env.JWT_SECRET,
      { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
    );

    // Remove password from response
    user.password = undefined;

    res.json({
      success: true,
      message: 'Login successful',
      token,
      user
    });
  } catch (error) {
    console.error('Login error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};
```

### UserController (`src/controllers/userController.js`)

#### updateProfile
```javascript
const updateProfile = async (req, res) => {
  try {
    const { firstName, lastName, phone, address, profileImage } = req.body;
    
    const updateData = {};
    if (firstName) updateData.firstName = firstName;
    if (lastName !== undefined) updateData.lastName = lastName;
    if (phone) updateData.phone = phone;
    if (address) updateData.address = address;
    if (profileImage) updateData.profileImage = profileImage;

    const user = await User.findByIdAndUpdate(
      req.user._id,
      updateData,
      { new: true, runValidators: true }
    ).select('-password');

    res.json({
      success: true,
      message: 'Profile updated successfully',
      user
    });
  } catch (error) {
    console.error('Profile update error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};
```

### Admin Dashboard Controller (`src/controllers/admin/dashboardController.js`)

#### getDashboardOverview / getUserManagementData / getServiceManagementData / getBookingManagementData / updateUser / updateService / updateBooking
```javascript
const getDashboardData = async (req, res) => {
  try {
    // Get user statistics
    const totalUsers = await User.countDocuments();
    const activeUsers = await User.countDocuments({ isActive: true });
    const verifiedUsers = await User.countDocuments({ isVerified: true });
    const newUsersThisMonth = await User.countDocuments({
      createdAt: { $gte: new Date(new Date().getFullYear(), new Date().getMonth(), 1) }
    });

    // Get role distribution
    const roleDistribution = await User.aggregate([
      {
        $group: {
          _id: '$role',
          count: { $sum: 1 }
        }
      }
    ]);

    // Get recent activity
    const recentUsers = await User.find()
      .sort({ createdAt: -1 })
      .limit(5)
      .select('firstName lastName email role createdAt');

    // Get pending reports
    const pendingReports = await Report.countDocuments({ status: 'pending' });

    res.json({
      success: true,
      data: {
        statistics: {
          totalUsers,
          activeUsers,
          verifiedUsers,
          newUsersThisMonth,
          pendingReports
        },
        roleDistribution,
        recentUsers
      }
    });
  } catch (error) {
    console.error('Dashboard data error:', error);
    res.status(500).json({
      success: false,
      message: 'Internal server error'
    });
  }
};
```

## 🚀 Server Configuration
This section clarifies responsibilities and avoids mixing snippets:

### `src/app.js` — Express app only
- Mounts security middleware: helmet, compression, CORS allowlist, global rate limiters, structured HTTP logging (pino) and access logs (morgan with rotation).
- Mounts routes: `/api/auth`, `/api/users`, `/api/admin`, and future modules (`/api/services`, `/api/bookings`, ...).
- Adds probes: `/api/health` (JSON), `/api/livez` (200 OK), `/api/readyz` (200 when Mongo connected, else 503).
- Wires celebrate/Joi and its error handler (Phase 0.5 initial).
- Exports the configured Express app; does not connect to DB or start listening.

### `server.js` — Process bootstrap only
- Loads environment (dotenv), imports `connectDB` from `src/config/database.js`.
- Connects to MongoDB Atlas (required `MONGODB_URI`), then imports and starts the Express app.
- Handles graceful shutdown signals and process-level error logging.

## 🔒 **Security Features**

### **Password Security**
- **Hashing**: bcryptjs with 12 salt rounds
- **Validation**: Minimum length requirements
- **Comparison**: Secure password comparison method

### **JWT Security**
- **Secret**: Environment variable with strong secret
- **Expiration**: Configurable token expiration
- **Payload**: Minimal user information
- **Validation**: Token verification on protected routes

### **Input Validation**
- **Email**: Regex pattern validation
- **Phone**: Flexible phone number validation
- **Password**: Minimum length requirements
- **Sanitization**: Input trimming and cleaning
 - **Schema Validation**: Request/response schemas using Joi/Zod (Phase 0.5)

### **Rate Limiting**
- **API Protection**: 100 requests per 15 minutes per IP
- **Login Protection**: Stricter limits on auth endpoints
- **Configurable**: Environment-based configuration

### **CORS Protection**
- **Origin Whitelist**: Configured allowed origins
- **Credentials**: Support for authenticated requests
- **Security**: Prevents unauthorized cross-origin requests
 - **No Wildcards in Prod**: Enforce allowlist from `CORS_ORIGIN` (no `*` in production)

### **Log Sanitization**
- Remove/obfuscate secrets, tokens, and PII from logs
- Standardize fields and include requestId/traceId (structured logging)

## 📊 **Error Handling**

### **Standard Error Response Format**
```javascript
{
  "success": false,
  "code": "ERROR|NOT_FOUND|RATE_LIMIT|VALIDATION_ERROR",
  "message": "Error description",
  "details": [ { "path": "email", "message": "Email is required" } ]
}
```

### **HTTP Status Codes**
- **200**: Success
- **201**: Created
- **400**: Bad Request (validation errors)
- **401**: Unauthorized (authentication required)
- **403**: Forbidden (insufficient permissions)
- **404**: Not Found
- **500**: Internal Server Error

### **Validation (Phase 0.5 — Initial)**
- celebrate/Joi is wired; validators added for:
  - POST `/api/auth/register`
  - POST `/api/auth/login`
  - PUT `/api/users/profile`
  - PUT `/api/users/change-password`
- Validation errors are returned by celebrate with `{ success:false, code:'VALIDATION_ERROR', message, details }`.

## 🧪 **Testing**

### **API Testing with Postman**

#### **1. Health Check**
```
GET http://localhost:3000/api/health
```

#### **2. User Registration**
```
POST http://localhost:3000/api/auth/register
Content-Type: application/json

{
  "firstName": "Test",
  "lastName": "User",
  "email": "test@example.com",
  "phone": "+1234567890",
  "password": "password123",
  "role": "client"
}
```

#### **3. User Login**
```
POST http://localhost:3000/api/auth/login
Content-Type: application/json

{
  "email": "test@example.com",
  "password": "password123"
}
```

#### **4. Token Validation**
```
GET http://localhost:3000/api/auth/validate
Authorization: Bearer <token>
```

#### **5. User Profile Update**
```
PUT http://localhost:3000/api/users/profile
Authorization: Bearer <token>
Content-Type: application/json

{
  "firstName": "Updated",
  "lastName": "Name"
}
```

### **PowerShell Testing**
```powershell
# Health check
Invoke-RestMethod -Uri "http://localhost:3000/api/health" -Method Get

# User registration
$body = @{
    firstName = "Test"
    lastName = "User"
    email = "test@example.com"
    phone = "+1234567890"
    password = "password123"
    role = "client"
} | ConvertTo-Json

Invoke-RestMethod -Uri "http://localhost:3000/api/auth/register" -Method Post -Body $body -ContentType "application/json"
```

## 📈 **Performance Optimization**

### **Database Optimization**
- **Indexing**: Email and phone fields indexed
- **Selective Queries**: Password field excluded by default
- **Connection Pooling**: MongoDB connection optimization
- **Query Optimization**: Efficient aggregation pipelines

### **Response Optimization**
- **Compression**: Response compression enabled
- **Caching**: API response caching (future implementation)
- **Pagination**: Large dataset pagination (future implementation)

### **Security Optimization**
- **Rate Limiting**: API abuse prevention
- **Input Validation**: Early validation and rejection
- **Error Handling**: Proper error responses without sensitive data

## 🔄 **Development Workflow**

### **Environment Setup**
1. **Clone Repository**: `git clone <repository-url>`
2. **Install Dependencies**: `npm install`
3. **Environment Configuration**: Copy `env.example` to `.env`
4. **Database Setup**: Configure MongoDB Atlas connection
5. **Start Development Server**: `npm run dev`

### **Development Commands**
```bash
# Start development server with auto-restart
npm run dev

# Start production server
npm start

# Run tests (future implementation)
npm test

# Lint code (future implementation)
npm run lint

# Format code (future implementation)
npm run format
```

### **Code Organization**
- **Controllers**: Business logic and request handling
- **Models**: Database schemas and data validation
- **Routes**: API endpoint definitions
- **Middleware**: Request processing and authentication
- **Utils**: Helper functions and utilities

## 📚 **API Documentation**

### **Authentication Endpoints**

#### **POST /api/auth/register**
Register a new user account.

**Request Body:**
```json
{
  "firstName": "string (required)",
  "lastName": "string (optional)",
  "email": "string (required, unique)",
  "phone": "string (required, unique)",
  "password": "string (required, min 6 chars)",
  "role": "string (optional, enum: client, provider, admin)"
}
```

**Response:**
```json
{
  "success": true,
  "message": "User registered successfully",
  "token": "JWT token",
  "user": {
    "_id": "user id",
    "firstName": "string",
    "lastName": "string",
    "email": "string",
    "phone": "string",
    "role": "string",
    "isVerified": false,
    "isActive": true,
    "createdAt": "date"
  }
}
```

#### **POST /api/auth/login**
Authenticate user and get access token.

**Request Body:**
```json
{
  "email": "string (required)",
  "password": "string (required)"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Login successful",
  "token": "JWT token",
  "user": {
    "_id": "user id",
    "firstName": "string",
    "lastName": "string",
    "email": "string",
    "role": "string",
    "isVerified": false,
    "isActive": true
  }
}
```

#### **POST /api/auth/logout**
Logout user (client-side token removal).

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "success": true,
  "message": "Logout successful"
}
```

#### **GET /api/auth/validate**
Validate JWT token and get user information.

**Headers:**
```
Authorization: Bearer <token>
```

**Response:**
```json
{
  "valid": true,
  "user": {
    "_id": "user id",
    "firstName": "string",
    "lastName": "string",
    "email": "string",
    "role": "string"
  }
}
```

### **User Management Endpoints**

#### **PUT /api/users/profile**
Update user profile information.

**Headers:**
```
Authorization: Bearer <token>
```

**Request Body:**
```json
{
  "firstName": "string (optional)",
  "lastName": "string (optional)",
  "phone": "string (optional)",
  "address": {
    "street": "string",
    "city": "string",
    "area": "string",
    "coordinates": {
      "latitude": "number",
      "longitude": "number"
    }
  },
  "profileImage": "string (optional)"
}
```

**Response:**
```json
{
  "success": true,
  "message": "Profile updated successfully",
  "user": {
    "_id": "user id",
    "firstName": "string",
    "lastName": "string",
    "email": "string",
    "phone": "string",
    "role": "string",
    "address": "object",
    "profileImage": "string"
  }
}
```

## 🎯 **Future Enhancements**

### **Planned Features**
1. **Email Verification**: Email-based account verification
2. **Password Reset**: Secure password reset functionality
3. **Social Login**: Google, Facebook integration
4. **Two-Factor Authentication**: Enhanced security
5. **File Upload**: Profile image and document upload
6. **Real-time Notifications**: WebSocket integration
7. **Advanced Search**: Elasticsearch integration
8. **Caching**: Redis caching layer
9. **Monitoring**: Application performance monitoring
10. **Logging**: Structured logging with Winston

### **Security Enhancements**
1. **API Rate Limiting**: Per-endpoint rate limiting
2. **Request Validation**: Joi schema validation
3. **Audit Logging**: Comprehensive audit trails
4. **IP Whitelisting**: Admin access restrictions
5. **Session Management**: Advanced session handling

### **Performance Enhancements**
1. **Database Indexing**: Optimized query performance
2. **Response Caching**: API response caching
3. **Connection Pooling**: Database connection optimization
4. **Load Balancing**: Horizontal scaling support
5. **CDN Integration**: Static asset delivery

---

## 📝 **Documentation Notes**

This documentation serves as the **comprehensive guide** for the PalHands backend implementation. It should be updated whenever:

1. **New features are implemented**
2. **API endpoints are added or modified**
3. **Security measures are enhanced**
4. **Database schemas are updated**
5. **New team members join the project**

**Last Updated**: August 2025
**Version**: 1.1.0
**Maintained By**: PalHands Development Team

### Server Startup (`server.js`)
Process bootstrap that connects to MongoDB Atlas using `src/config/database.js`, then starts the Express app. Handles graceful shutdown.

---

## ✅ Documentation Accuracy Audit (current vs code)

- Implemented and matching code:
  - Auth routes: register, login, logout, validate, profile
  - User routes: profile update, change password, admin list/get/update-status/delete
  - Admin routes: dashboard overview, users, services, bookings, reports, settings, analytics, actions (routes now call controllers only)
  - Models: User, Admin, AdminAction, Report, SystemSetting, Service, Booking
- Newly implemented in this pass:
  - Phase 0: helmet, compression, rate limiting (global+auth), CORS allowlist, structured logging (pino + morgan with rotation), env validation.
  - Phase 0.5 (initial): celebrate/Joi validators on auth and user profile/password endpoints; celebrate error handler.
  - Phase 0.9: health, liveness, readiness probes; log sanitization for secrets/PII.
- Still not implemented:
  - Public Services/Bookings/Payments/Reviews REST APIs (app.js has them planned)
  - Real-time Socket.io initialization and namespaces
  - Refresh token flow
  - Seeding script referenced in package.json (src/utils/seedDatabase.js) is missing

Docs updated to reflect the above and mark planned items in the phased plan.

---

## 🛠️ Backend Implementation Plan (Phased)

Goal: Enable immediate development with clear priorities, scope, and milestones until completion.

Gating order:
- Complete Phase 0 and 0.5 before building large routers (Services/Bookings/Payments).
- Phase 1.5 (policies) should be in place before widening feature surface.

### Phase 0 — Foundation & Hardening (Priority: High)
- Dependencies: add helmet, compression, express-rate-limit, morgan (or pino/winston)
- App hardening: wire helmet, compression, CORS allowlist from env, JSON/body limits
- Rate limiting: global and auth-specific buckets
- Error handling: unified response helper `{ success, code, message, errors?, data? }` + async wrapper
- Logging: request logging + error logs to files under `logs/`
- DB connection: use `src/config/database.js`; handle retries and shutdown
- Config: env validation early (envalid/zod) with explicit fail on missing/invalid vars (PORT, MONGODB_URI, JWT_SECRET, CORS_ORIGIN)
- Scripts: dev nodemon, lint stub, seed script guard
- Deliverables: updated app.js/server.js, package.json, ENV docs

Milestone: App boots with hardening and healthcheck; lint/build pass.

### Phase 0.5 — API Contract & Validation (Priority: High)
- OpenAPI seed (minimal spec) and CI check for drift
- Request/response validation with Joi/Zod (celebrate middleware or zod-express); introduce `src/validators/`
- Error taxonomy (consistent JSON: code, message, details)
- Deliverables: schemas per route, error codes table, generated Postman

Milestone: Validated inputs/outputs and baseline API spec.

### Phase 0.9 — Observability & Probes (Priority: High)
- Structured logging (pino) with requestId/traceId correlation
- HTTP access logs wired to app logs with correlation IDs
- Health, liveness, and readiness endpoints; integrate with probes
- Basic metrics endpoint (optional) and log rotation guidance
- Log sanitization policy (no secrets/PII): strip or mask `authorization`, `cookie`, `set-cookie`, `password`, `token`, `refreshToken`

Milestone: Actionable logs and operability signals.

### Phase 1 — Auth & Users (Stabilization) (Priority: High)
### Phase 1.5 — RBAC Hardening (Priority: High)
- Centralize RBAC/ABAC helpers (roles + permissions) in `src/policies/` and use in controllers
- Optional refresh tokens and revocation list
- Password policy and 2FA optional toggle

Refactor tasks:
- Replace scattered role/ownership checks in controllers/routes with calls to policies
- Document policy decisions and add tests for critical paths

Milestone: Authorization consistent and centrally enforced.
- Tests: unit/integration for register/login/validate/profile, user profile, change password
- Password policy: ensure min length; rate-limit login; optional lockout on brute-force
- Email stubs: optional verification flag if ENABLE_EMAIL_VERIFICATION=true
- Role guard: verify admin-only flows (users admin endpoints)
- Deliverables: Jest/supertest setup (or mocha/chai), sample seeds, Postman collection

Milestone: Auth/User tests green; API contract frozen.

### Phase 2 — Services Module (Public & Provider) (Priority: High)
### Phase 2.1 — Media Storage (Priority: High)
- Migrate file storage from `/uploads` to S3/MinIO
- Signed URLs for upload/download; validate mime/size
- Orphan cleanup background job

Milestone: Production-grade media pipeline.

### Phase 2.2 — Provider Availability (Priority: High)
- Availability model (slots/exceptions/timezone aware)
- Prevent double-booking (unique constraints or logical locks)
- DST/timezone normalization utilities

Milestone: Accurate availability and booking validation.

### Phase 2.3 — Geo & Search (Priority: Medium)
- 2dsphere indexes for location queries
- Unified pagination and filtering helpers

Milestone: Efficient search and geo features.
- Routes: `/api/services`
  - GET list (filters: category, location, price, rating)
  - GET `/:id`
  - POST (provider) create; PUT/PATCH (provider) update; DELETE (provider) archive
- Permissions: provider-only create/update/delete, verified requirement optional
- Search: text index already present; expose `q` param
- Images: add multer config + file validation; store relative URLs under /uploads
- Deliverables: routes/services.js, controllers/servicesController.js, multer util, validation

Milestone: Services browse + provider CRUD working; admin moderation via existing admin routes.

### Phase 3 — Bookings Module (Public & Provider) (Priority: High)
- Routes: `/api/bookings`
  - POST create booking (client)
  - GET my bookings (client/provider) with filters and pagination
  - GET `/:id`
  - PATCH status transitions: confirm, start, complete, cancel (role-based)
  - Notes: client/provider/admin notes fields
- Pricing: server-side compute `totalAmount` from service price + add-ons
- Permissions: auth + ownership checks; admin override
- FSM: explicit status state machine with guards (confirm/start/complete/cancel)
- Idempotency keys for create/change operations
- Optional transactions for sensitive updates
- Deliverables: routes/bookings.js, controllers/bookingsController.js, status machine, validation

FSM states (enum) and transitions:
- States: `pending` → `confirmed` → `in_progress` → `completed`; with `canceled` and `no_show` as terminal side paths
- Allowed transitions: `pending→confirmed`, `confirmed→in_progress`, `in_progress→completed`, any→`canceled` (guarded), `confirmed→canceled` (guarded)
- Guards: role/ownership, timing windows, service availability, payment status (if applicable)

Idempotency:
- Require `Idempotency-Key` header (UUID) for create/update that change state
- If same key and same payload is replayed: return the original response (200/201)
- If same key with different payload: return 409 Conflict with guidance

Milestone: End-to-end booking lifecycle for client/provider.

### Phase 4 — Payments (Incremental) (Priority: Medium)
- Strategy: start with `cash` and mark-as-paid; abstract interface for Stripe/PayPal later
- Webhooks: if Stripe/PayPal enabled, add `/api/payments/webhook` with signature verification and replay protection
- Outbox pattern + retries for reliable event dispatch
- Reconciliation: scheduled job to ensure consistency between provider and DB
- Deliverables: routes/payments.js, controllers/paymentsController.js, webhook verifier, outbox worker

Milestone: Bookings can be paid and reconciled; admin can adjust refunds.

### Phase 5 — Reviews & Ratings (Priority: Medium)
- Source of truth: ratings embedded in Booking (existing fields)
- Endpoints: POST review on completed bookings (one per party), list my reviews, service rating aggregation
- Aggregations: update Service.rating and User.rating on new review
- Deliverables: routes/reviews.js, controllers/reviewsController.js, aggregation helpers

Milestone: Reviews flow live; ratings reflected on services/providers.

### Phase 6 — Reports & Disputes (Priority: Medium)
- Public endpoints: create report, attach evidence (multer), view my reports
- Admin: existing `/api/admin/reports` to manage; add evidence storage
- Deliverables: routes/reports.js, controllers/reportsController.js (public), evidence upload

Milestone: Reporting pipeline usable end-to-end.

### Phase 7 — Real-time & Notifications (Priority: Low)
- Initialize Socket.io in `server.js`; namespaces for admin dashboard events (optional)
- Push notifications: integrate later with FCM/email as flags allow

Milestone: Basic real-time updates available for dashboards.

### Phase 7.5 — Background Jobs (Priority: Medium)
- Job runner (BullMQ/Agenda + Redis) for reminders, notifications, cleanup, reconciliation
- DLQ and retry strategy

Milestone: Reliable async processing.

### Phase 8 — Deployment & Operations (Priority: High)
- Choose one: PM2 (VM/bare‑metal) OR Containers (Docker/K8s)
- If Docker: Dockerfile + docker-compose for dev; K8s manifests optional later
- If PM2: ecosystem config, health/liveness probes
- Env: production `.env` guidance; secrets via environment
- CI/CD: GitHub Actions for lint/test/build; optional deploy step
- Monitoring: basic logs rotation; optional metrics endpoint

Milestone: One-command deploy; rollbacks supported; monitoring basics in place.

### Phase 8.1 — Migrations & Backups (Priority: High)
- Schema migrations (migrate-mongo or similar), documented process
- Backup/restore runbook (Atlas backups or mongodump) and drills
- Automated backup schedule for non-prod/staging if needed

Milestone: Safe schema evolution and recovery readiness.

---

## 📡 API Contract (Planned Additions)

### Services (`/api/services`)
- GET `/` — list services; query: `q, category, location, minPrice, maxPrice, rating, page, limit`
- GET `/:id` — service details
- POST `/` — create (provider)
- PATCH `/:id` — update (owner provider)
- DELETE `/:id` — archive (owner provider)

### Bookings (`/api/bookings`)
- POST `/` — create booking (client)
- GET `/me` — my bookings (client/provider)
- GET `/:id`
- PATCH `/:id/status` — transitions: pending→confirmed→in_progress→completed; cancel

### Payments (`/api/payments`)
- POST `/mark-paid` — admin/provider mark paid (cash)
- POST `/intent` — create payment intent (Stripe) [flagged]
- POST `/webhook` — webhook receiver

### Reviews (`/api/reviews`)
- POST `/` — add review for completed booking
- GET `/me` — my reviews
- GET `/service/:serviceId` — list reviews for a service

All new endpoints require JWT auth unless explicitly public.

---

## 📋 Phased roadmap and living to‑do (update as you complete tasks)

Status legend: [ ] Todo, [x] Done, [~] In progress

### Phase 0 — Foundation & Hardening (High)
- [x] Centralize DB connect in `src/config/database.js`; export mongoose
- [x] Require `MONGODB_URI` (no local fallback); update `env.simple` and docs
- [x] Add helmet + compression
- [x] Add express-rate-limit (global + stricter on `/api/auth/login`)
- [x] Add request logging (pino + morgan) and rotate to `logs/`
- [x] CORS allowlist from `CORS_ORIGIN` env
- [x] Config validation on boot (PORT, MONGODB_URI, JWT_SECRET)
 - [x] Async handler wrapper + standard error response helper

Milestone: App boots with security middleware and logging; healthcheck works.

### Phase 0.5 — API Contract & Validation (High)
 - [x] OpenAPI seed + CI check (`backend/openapi.yaml`, GitHub Action openapi-validate)
- [x] Request validation (Joi via celebrate) for auth and user endpoints
- [x] Error taxonomy (code/message/details) baseline aligned
 - [x] Generated Postman collection (`backend/postman_collection.json`)

Milestone: Validated inputs/outputs; baseline API spec.

### Phase 1 — Auth & Users (High)
- [x] Consolidate auth duplication into `authMiddleware.js`
- [x] Re-export legacy `auth.js` and `adminAuth.js` from unified middleware
- [ ] Add login attempt rate limiting / optional lockout
- [ ] Optional email verification flow (flagged via `ENABLE_EMAIL_VERIFICATION`)
- [ ] Tests: register/login/validate/profile, profile update, change password
- [ ] Postman collection / OpenAPI stub

Milestone: Tests green; API contract frozen.

### Phase 1.5 — RBAC Hardening (High)
- [ ] Central RBAC/ABAC helpers used by controllers
- [ ] (Optional) refresh tokens + revocation
- [ ] (Optional) 2FA toggle + stronger password policy

Milestone: Authorization consistent and enforced centrally.

### Phase 2 — Services Module (High)
- [ ] Create `controllers/servicesController.js` and `routes/services.js`
- [ ] Endpoints: GET `/`, GET `/:id`, POST, PATCH, DELETE (provider-owned)
- [ ] Text search via existing index; `q` param support
- [ ] Multer upload pipeline + validation; store under `/uploads`
- [ ] Mount `/api/services` in `app.js`

Milestone: Browse + provider CRUD; admin moderation already available.

### Phase 2.1 — Media Storage (High)
- [ ] Switch to S3/MinIO + signed URLs
- [ ] Validate mime/size; strip metadata
- [ ] Orphan cleanup background job

Milestone: Production-grade media handling.

### Phase 2.2 — Provider Availability (High)
- [ ] Availability model + exceptions
- [ ] Anti double-booking (unique constraints/locks)
- [ ] TZ/DST-safe scheduling

Milestone: Accurate availability and booking validation.

### Phase 2.3 — Geo & Search (Medium)
- [ ] 2dsphere indexes for geo queries
- [ ] Unified pagination/filtering helpers

Milestone: Efficient geo search and consistent pagination.

### Phase 3 — Bookings Module (High)
- [ ] Create `controllers/bookingsController.js` and `routes/bookings.js`
- [ ] POST create; GET my bookings; GET by id
- [ ] PATCH status transitions (confirm/start/complete/cancel) with guards
- [ ] Compute `pricing.totalAmount` server-side; helper functions
- [ ] Ownership checks and admin override guards
- [ ] Mount `/api/bookings` in `app.js`
- [ ] FSM for status transitions + guards
- [ ] Idempotency keys for create/change
- [ ] (Optional) transactions for sensitive updates

Milestone: End-to-end booking lifecycle.

### Phase 4 — Payments (Medium)
- [ ] Minimal cash: mark as paid; update booking.payment, audit
- [ ] Abstraction for processors (Stripe/PayPal) behind feature flags
- [ ] `/api/payments/webhook` verification (if enabled) with signature + replay protection
- [ ] Outbox + retries for reliable dispatch
- [ ] Reconciliation scheduled job

Milestone: Payments reconciled; basic admin adjustments supported.

### Phase 5 — Reviews & Ratings (Medium)
- [ ] POST review on completed bookings (1 per party)
- [ ] GET my reviews; GET reviews for service
- [ ] Aggregate updates to `Service.rating` and `User.rating`

Milestone: Ratings flow live; surfacing on listings.

### Phase 6 — Reports & Disputes (Medium)
- [x] Admin: list/update via dedicated controllers
- [ ] Public: `routes/reports.js` + `controllers/reportsController.js` (create/list mine)
- [ ] Evidence upload with multer

Milestone: End-to-end reporting.

### Phase 7 — Real-time & Notifications (Low)
- [ ] Initialize Socket.io; broadcast booking status changes; optional admin channel
- [ ] Email/FCM behind feature flags

Milestone: Basic real-time updates.

### Phase 7.5 — Background Jobs (Medium)
- [ ] BullMQ/Agenda + Redis
- [ ] DLQ and retry policies

Milestone: Reliable async processing.

### Phase 8 — Deployment & Operations (High)
- [ ] Choose one runtime: PM2 or Docker/K8s
- [ ] If Docker: Dockerfile + docker-compose (dev)
- [ ] If PM2: ecosystem config (prod)
- [ ] GitHub Actions (lint/test/build; optional deploy)
- [ ] Metrics/health probes and log rotation

Milestone: One-command deploy; rollbacks and monitoring in place.

### Housekeeping & DX
- [x] Admin routes: routing-only; logic moved to controllers
- [ ] Split `dashboardController.js` into `usersAdminController.js`, `servicesAdminController.js`, `bookingsAdminController.js`
- [ ] Remove or implement `src/utils/seedDatabase.js` (script currently referenced)
- [ ] OpenAPI schema + generated Postman collection (moved to Phase 0.5)
- [ ] Consistent error codes/messages guide in docs
 - [ ] Unified response helper utility used across controllers
- [ ] Remove legacy `src/middleware/auth.js` and `src/middleware/adminAuth.js` re-export files after transition; update imports

Naming and folders:
- Use a single canonical auth middleware file: `src/middleware/authMiddleware.js` (avoid multiple auth files).
- Place request/response validators under `src/validators/` by route.
- Place RBAC/ABAC helpers and authorization checks in `src/policies/`.

AdminAction actor note: actor is `Admin` across admin endpoints; ensure middleware attaches `req.admin` and populate consistently.
 - [ ] Remove legacy `auth.js` and `adminAuth.js` re-export files after a short transition; update imports across codebase

AdminAction actor note: actor is `Admin` across admin endpoints; ensure middleware attaches `req.admin` and populate consistently.

How to use this list: check off items as you complete them, add any new tasks you discover under the relevant phase, and mark phases complete when milestones are achieved.

---

## 🧱 Data Model Notes

- User: roles [client, provider, admin]; isVerified; rating aggregate
- Service: provider ref; pricing; availability; location; search indexes
- Booking: bookingId; schedule; pricing; payment; status; notes; ratings (client/provider)
- AdminAction: audit log for admin updates
- Report: reporter vs reported; evidence; status; priority; resolution
- SystemSetting: key/value with type/category; edit guards

Indexes are present for query hot paths (services search, bookings by user/status/date, reports filters).

---

## 🚢 Deployment Strategy

- Environments: dev (local or Docker), staging (Atlas), production (Atlas)
- Windows dev: use `backend/setup-env.ps1` and `env.simple` to bootstrap `.env`
- Runtime choice: PM2 (VM) OR Docker/K8s; avoid running both in prod
- Docker (if chosen):
  - Dockerfile (multi-stage build)
  - docker-compose.yml (app; Mongo only for local dev)
- Process: enable graceful shutdown signals (already present)
- Security: set strong JWT secrets; configure CORS allowlist; enable helmet/compression/rate-limit; sanitize logs
- Backups: Atlas backups or mongodump in CI for staging
 - Storage: use S3/MinIO with signed URLs in prod; `/uploads` is dev-only

---

## 📈 Milestones & Tracking

1) Phase 0 complete — app boots with security middleware, logging, DB via config (ETA: 1–2 days)
2) Phase 1 tests green for Auth/Users (ETA: 1–2 days)
3) Services module live (ETA: 2–3 days)
4) Bookings module live (ETA: 3–4 days)
5) Payments minimal (cash) (ETA: 1–2 days)
6) Reviews live (ETA: 1–2 days)
7) Reports public endpoints + evidence (ETA: 2 days)
8) Deployment (Docker/PM2/CI) (ETA: 2 days)

Track with GitHub issues labeled by phase and a lightweight checklist per route.

---

## ✅ Quick Start (Dev)

1) Create `.env` from `backend/env.simple` and adjust values
2) Ensure MongoDB Atlas `MONGODB_URI` in `.env` (no local fallback). For dev-only Docker, point to local Mongo and adjust env.
3) Run dev server

Healthcheck: GET `/api/health`

Ops Probes:
- Liveness: GET `/api/livez`
- Readiness: GET `/api/readyz` (200 when DB is connected; 503 otherwise)

Basic testing (PowerShell):
```powershell
# Health
Invoke-RestMethod -Uri "http://localhost:3000/api/health" -Method Get

# Probes
Invoke-RestMethod -Uri "http://localhost:3000/api/livez" -Method Get
Invoke-RestMethod -Uri "http://localhost:3000/api/readyz" -Method Get

# Register
$body = @{ firstName='Test'; lastName='User'; email='test@example.com'; phone='+1234567890'; password='password123' } | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:3000/api/auth/register" -Method Post -Body $body -ContentType "application/json"

# Login
$login = @{ email='test@example.com'; password='password123' } | ConvertTo-Json
$resp = Invoke-RestMethod -Uri "http://localhost:3000/api/auth/login" -Method Post -Body $login -ContentType "application/json"
$token = $resp.token

# Update profile
$upd = @{ firstName='Updated' } | ConvertTo-Json
Invoke-RestMethod -Uri "http://localhost:3000/api/users/profile" -Method Put -Headers @{ Authorization = "Bearer $token" } -Body $upd -ContentType "application/json"
```
## 📦 CHANGELOG (Summary)

- 1.1.1 (2025-08): Implemented Phase 0 (helmet, compression, CORS, rate limits, logging, env validation), Phase 0.5 initial (celebrate/Joi validators, error format), Phase 0.9 (health/liveness/readiness probes, log sanitization, rotated access logs). Updated docs and added testing steps.
- 1.1.0 (2025-08): Planning refinement — added phases 0.5/1.5/2.1/2.2/2.3/7.5; clarified server/app roles; strengthened bookings/payments/jobs/observability; added log sanitization; deployment runtime choice; updated quick start and storage guidance.
- 1.0.0 (2024-12): Initial documentation and MVP plan.

---

**Maintained By**: PalHands Development Team