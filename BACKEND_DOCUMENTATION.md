# PalHands Backend Documentation

## 📋 **Backend Overview**

**PalHands Backend** is a Node.js/Express.js API server that provides authentication, user management, and service coordination for the PalHands platform. The backend is built with MongoDB Atlas as the cloud database and implements secure JWT-based authentication.

## 🏗️ **Architecture Overview**

```
backend/
├── src/
│   ├── app.js                 # Main Express application
│   ├── config/
│   │   └── database.js        # Database configuration
│   ├── controllers/
│   │   ├── authController.js  # Authentication logic
│   │   ├── userController.js  # User management
│   │   └── admin/
│   │       └── dashboardController.js  # Admin dashboard
│   ├── middleware/
│   │   ├── auth.js           # General authentication middleware
│   │   └── adminAuth.js      # Admin-specific middleware
│   ├── models/
│   │   ├── User.js           # User schema
│   │   ├── Admin.js          # Admin schema
│   │   ├── AdminAction.js    # Audit logging
│   │   ├── Report.js         # User reports
│   │   └── SystemSetting.js  # Platform settings
│   ├── routes/
│   │   ├── auth.js           # Authentication routes
│   │   ├── users.js          # User management routes
│   │   └── admin.js          # Admin routes
│   ├── services/             # External services
│   └── utils/                # Utility functions
├── uploads/                  # File uploads
├── logs/                     # Application logs
├── server.js                 # Server startup
├── package.json              # Dependencies
└── env.example               # Environment variables template
```

## 🔧 **Technology Stack**

### **Core Technologies**
- **Runtime**: Node.js (>=16.0.0)
- **Framework**: Express.js
- **Database**: MongoDB Atlas (Cloud)
- **ODM**: Mongoose
- **Authentication**: JWT (JSON Web Tokens)
- **Password Hashing**: bcryptjs
- **File Upload**: Multer
- **Email**: Nodemailer
- **Real-time**: Socket.io

### **Development Dependencies**
- **nodemon**: Development server with auto-restart
- **dotenv**: Environment variable management
- **cors**: Cross-Origin Resource Sharing
- **helmet**: Security headers
- **express-rate-limit**: Rate limiting
- **compression**: Response compression

## 🗄️ **Database Configuration**

### **MongoDB Atlas Setup**
- **Cluster**: PalHands (palhands.rtxny5x.mongodb.net)
- **Database**: palhands
- **Connection**: MongoDB Atlas cloud service
- **Authentication**: Username/password with IP whitelist

### **Connection String Format**
```
mongodb+srv://<username>:<password>@palhands.rtxny5x.mongodb.net/palhands?retryWrites=true&w=majority&appName=PalHands
```

### **Environment Variables**
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

## 📊 **Database Models**

### **User Model** (`src/models/User.js`)

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

**Key Features:**
- **Password Hashing**: Pre-save middleware using bcryptjs
- **Password Comparison**: Instance method for secure password verification
- **Validation**: Comprehensive input validation with custom error messages
- **Indexing**: Email and phone fields are indexed for performance
- **Timestamps**: Automatic createdAt and updatedAt fields

### **Admin Model** (`src/models/Admin.js`)

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

### **AdminAction Model** (`src/models/AdminAction.js`)

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

### **Report Model** (`src/models/Report.js`)

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

### **SystemSetting Model** (`src/models/SystemSetting.js`)

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

## 🔐 **Authentication System**

### **JWT Configuration**
- **Secret**: Environment variable `JWT_SECRET`
- **Expiration**: 7 days (configurable via `JWT_EXPIRES_IN`)
- **Algorithm**: HS256
- **Payload**: Contains userId and role information

### **Password Security**
- **Hashing**: bcryptjs with salt rounds of 12
- **Comparison**: Secure password comparison method
- **Validation**: Minimum 6 characters for users, 8 for admins

### **Authentication Flow**

#### **1. User Registration**
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

#### **2. User Login**
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

#### **3. Token Validation**
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

#### **4. User Logout**
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

## 🛡️ **Middleware System**

### **Authentication Middleware** (`src/middleware/auth.js`)

#### **auth Middleware**
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

#### **checkRole Middleware**
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

#### **requireVerification Middleware**
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

#### **checkOwnership Middleware**
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

### **Admin Authentication Middleware** (`src/middleware/adminAuth.js`)

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

## 🎯 **API Endpoints**

### **Authentication Routes** (`/api/auth`)

| Method | Endpoint | Description | Auth Required |
|--------|----------|-------------|---------------|
| POST | `/register` | Register new user | No |
| POST | `/login` | User login | No |
| POST | `/logout` | User logout | Yes |
| GET | `/validate` | Validate token | Yes |
| GET | `/profile` | Get user profile | Yes |

### **User Management Routes** (`/api/users`)

| Method | Endpoint | Description | Auth Required | Role Required |
|--------|----------|-------------|---------------|---------------|
| PUT | `/profile` | Update user profile | Yes | Any |
| PUT | `/change-password` | Change password | Yes | Any |
| GET | `/` | Get all users | Yes | Admin |
| GET | `/:id` | Get user by ID | Yes | Admin |
| PUT | `/:id/status` | Update user status | Yes | Admin |
| DELETE | `/:id` | Delete user | Yes | Admin |

### **Admin Routes** (`/api/admin`)

| Method | Endpoint | Description | Auth Required | Role Required |
|--------|----------|-------------|---------------|---------------|
| GET | `/dashboard` | Admin dashboard data | Yes | Admin |
| GET | `/users` | Get all users | Yes | Admin |
| GET | `/reports` | Get user reports | Yes | Admin |
| PUT | `/reports/:id` | Update report status | Yes | Admin |
| GET | `/settings` | Get system settings | Yes | Admin |
| PUT | `/settings/:key` | Update system setting | Yes | Admin |

## 🔧 **Controllers**

### **AuthController** (`src/controllers/authController.js`)

#### **register Function**
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

#### **login Function**
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

### **UserController** (`src/controllers/userController.js`)

#### **updateProfile Function**
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

### **Admin Dashboard Controller** (`src/controllers/admin/dashboardController.js`)

#### **getDashboardData Function**
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

## 🚀 **Server Configuration**

### **Main Application** (`src/app.js`)

```javascript
const express = require('express');
const cors = require('cors');
const helmet = require('helmet');
const compression = require('compression');
const rateLimit = require('express-rate-limit');

const app = express();

// Security middleware
app.use(helmet());
app.use(compression());

// CORS configuration
app.use(cors({
  origin: process.env.CORS_ORIGIN?.split(',') || ['http://localhost:8080'],
  credentials: true
}));

// Rate limiting
const limiter = rateLimit({
  windowMs: 15 * 60 * 1000, // 15 minutes
  max: 100 // limit each IP to 100 requests per windowMs
});
app.use('/api/', limiter);

// Body parsing middleware
app.use(express.json({ limit: '10mb' }));
app.use(express.urlencoded({ extended: true, limit: '10mb' }));

// Routes
app.use('/api/auth', require('./routes/auth'));
app.use('/api/users', require('./routes/users'));
app.use('/api/admin', require('./routes/admin'));

// Health check endpoint
app.get('/api/health', (req, res) => {
  res.json({
    status: 'OK',
    timestamp: new Date().toISOString(),
    uptime: process.uptime()
  });
});

// Error handling middleware
app.use((err, req, res, next) => {
  console.error(err.stack);
  res.status(500).json({
    success: false,
    message: 'Internal server error'
  });
});

// 404 handler
app.use('*', (req, res) => {
  res.status(404).json({
    success: false,
    message: 'Route not found'
  });
});

module.exports = app;
```

### **Server Startup** (`server.js`)

```javascript
const mongoose = require('mongoose');
const app = require('./src/app');

const PORT = process.env.PORT || 3000;

// Connect to MongoDB
mongoose.connect(process.env.MONGODB_URI)
  .then(() => {
    console.log('✅ Connected to MongoDB Atlas');
    console.log(`📊 Database: ${mongoose.connection.name}`);
    console.log(`🌐 Host: ${mongoose.connection.host}`);
  })
  .catch((error) => {
    console.error('❌ MongoDB connection error:', error);
    console.log('\n🔧 Troubleshooting Tips:');
    console.log('1. Check if MongoDB Atlas is accessible');
    console.log('2. Verify your MONGODB_URI in .env file');
    console.log('3. Ensure your IP is whitelisted in Atlas');
    console.log('4. Check your username and password');
    process.exit(1);
  });

// Start server
app.listen(PORT, () => {
  console.log(`🚀 Server running on port ${PORT}`);
  console.log(`📱 Frontend URL: http://localhost:8080`);
  console.log(`🔧 Backend API: http://localhost:${PORT}/api`);
  console.log(`🏥 Health Check: http://localhost:${PORT}/api/health`);
});
```

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

### **Rate Limiting**
- **API Protection**: 100 requests per 15 minutes per IP
- **Login Protection**: Stricter limits on auth endpoints
- **Configurable**: Environment-based configuration

### **CORS Protection**
- **Origin Whitelist**: Configured allowed origins
- **Credentials**: Support for authenticated requests
- **Security**: Prevents unauthorized cross-origin requests

## 📊 **Error Handling**

### **Standard Error Response Format**
```javascript
{
  "success": false,
  "message": "Error description",
  "errors": [
    {
      "field": "email",
      "message": "Email is required"
    }
  ]
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

### **Validation Error Handling**
```javascript
const handleValidationError = (error) => {
  const errors = Object.values(error.errors).map(err => ({
    field: err.path,
    message: err.message
  }));

  return {
    success: false,
    message: 'Validation failed',
    errors
  };
};
```

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

**Last Updated**: December 2024
**Version**: 1.0.0
**Maintained By**: PalHands Development Team 