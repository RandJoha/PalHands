# PalHands Project Documentation

## 📋 **Project Overview**

**PalHands** is a comprehensive platform connecting people with home-based service providers in Palestine. The project consists of:

- **Backend**: Node.js/Express API with MongoDB
- **Frontend**: Flutter mobile application with web support
- **Architecture**: Clean Architecture with BLoC state management

## 🏗️ **Project Structure**

```
PalHands/
├── backend/                 # Node.js API Server
│   ├── src/
│   │   ├── models/         # MongoDB Schemas
│   │   ├── routes/         # API Routes
│   │   ├── controllers/    # Business Logic
│   │   ├── middleware/     # Custom Middleware
│   │   ├── services/       # External Services
│   │   └── utils/          # Utility Functions
│   ├── uploads/            # File Uploads
│   └── logs/               # Application Logs
└── frontend/               # Flutter Application
    ├── lib/
    │   ├── core/           # Core Utilities
    │   ├── features/       # Feature Modules
    │   └── shared/         # Shared Components
    └── assets/             # Static Assets
```

## 🎨 **Design System & Branding**

### **Color Palette**
- **Primary**: Palestinian Red (#C43F20) - Represents Palestinian identity
- **Secondary**: Golden (#D4AC0D) - Represents prosperity and quality
- **Background**: Warm Beige (#FDF5EC) - Creates welcoming atmosphere
- **Text**: Dark Gray (#111827) - High readability

### **Typography**
- **Font Family**: Cairo (Arabic-friendly)
- **Weights**: Complete range (Light to Black)
- **Responsive**: ScreenUtil integration for scaling

### **Cultural Elements**
- **Palestinian Red**: Primary brand color
- **Arabic Support**: RTL layout and Arabic fonts
- **Local Context**: Palestine-specific locations and services

## 🔧 **Backend Implementation**

### **Technology Stack**
- **Runtime**: Node.js (>=16.0.0)
- **Framework**: Express.js
- **Database**: MongoDB with Mongoose ODM
- **Authentication**: JWT with bcrypt
- **File Upload**: Multer
- **Email**: Nodemailer
- **Real-time**: Socket.io

### **Environment Configuration**
```bash
# Essential Variables
NODE_ENV=development
PORT=3000
MONGODB_URI=mongodb://localhost:27017/palhands
JWT_SECRET=your-secret-key

# Optional Variables
EMAIL_HOST=smtp.gmail.com
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
CORS_ORIGIN=http://localhost:3000,http://localhost:8080
```

### **Database Models**

#### **User Model**
```javascript
{
  firstName: String (required),
  lastName: String (required),
  email: String (required, unique),
  phone: String (required, unique),
  password: String (required, hashed),
  role: ['client', 'provider', 'admin'],
  profileImage: String,
  address: {
    street: String,
    city: String,
    area: String,
    coordinates: { latitude: Number, longitude: Number }
  },
  isVerified: Boolean (default: false),
  isActive: Boolean (default: true),
  rating: { average: Number, count: Number }
}
```

#### **Service Model**
```javascript
{
  provider: ObjectId (ref: User),
  title: String (required),
  description: String,
  category: String (required),
  subCategory: String,
  price: { amount: Number, currency: String },
  location: { city: String, area: String, coordinates: Object },
  images: [String],
  isActive: Boolean (default: true),
  rating: { average: Number, count: Number }
}
```

#### **Booking Model**
```javascript
{
  client: ObjectId (ref: User),
  provider: ObjectId (ref: User),
  service: ObjectId (ref: Service),
  status: ['pending', 'confirmed', 'in-progress', 'completed', 'cancelled'],
  scheduledDate: Date,
  scheduledTime: String,
  address: { street: String, city: String, area: String },
  totalAmount: Number,
  paymentStatus: ['pending', 'paid', 'refunded'],
  notes: String
}
```

### **API Endpoints Structure**
```
/api/health              # Health check
/api/auth               # Authentication routes
/api/users              # User management
/api/services            # Service management
/api/bookings            # Booking management
/api/payments            # Payment processing
/api/reviews             # Review system
/api/admin               # Admin panel
```

## 📱 **Frontend Implementation**

### **Technology Stack**
- **Framework**: Flutter (>=3.0.0)
- **State Management**: BLoC Pattern with flutter_bloc
- **Navigation**: GoRouter
- **HTTP Client**: Dio with interceptors
- **Local Storage**: Hive + SharedPreferences
- **UI**: Material 3 with custom theming
- **Responsive**: ScreenUtil for scaling

### **Architecture Pattern**
```
lib/
├── core/                    # Core utilities
│   ├── constants/          # App constants
│   ├── errors/             # Error handling
│   ├── network/            # Network layer
│   └── utils/              # Utility functions
├── features/               # Feature modules
│   ├── auth/              # Authentication
│   ├── home/              # Home screen
│   ├── services/          # Service management
│   ├── bookings/          # Booking system
│   ├── profile/           # User profile
│   ├── messaging/         # Chat system
│   └── reviews/           # Review system
└── shared/                # Shared components
    ├── models/            # Data models
    ├── services/          # Shared services
    └── widgets/           # Reusable widgets
```

### **Key Dependencies**
```yaml
# State Management
flutter_bloc: ^8.1.3
bloc: ^8.1.2
equatable: ^2.0.5

# Network & HTTP
dio: ^5.4.0
http: ^1.1.2
connectivity_plus: ^5.0.2

# Local Storage
shared_preferences: ^2.2.2
hive: ^2.2.3
hive_flutter: ^1.1.0

# UI Components
google_fonts: ^6.1.0
flutter_svg: ^2.0.9
cached_network_image: ^3.3.0
flutter_rating_bar: ^4.0.1

# Navigation
go_router: ^12.1.3

# Maps & Location
google_maps_flutter: ^2.5.0
location: ^5.0.3
geocoding: ^2.1.1

# Utilities
flutter_screenutil: ^5.9.0
intl: ^0.19.0
permission_handler: ^11.1.0
```

### **Implemented Screens**

#### **Splash Screen** ✅
- Beautiful Palestinian-inspired design
- Sea Green color scheme (#2E8B57)
- Cairo font with Arabic support
- Handshake icon representing community
- Loading animation with branding

#### **Login Screen** ✅
- Clean, modern design
- Email/phone authentication
- Password validation
- Social login options (Google, Phone)
- Responsive layout (mobile/web)

#### **Signup Screen** ✅
- Dual registration flow (Client/Provider)
- Service category selection for providers
- Form validation
- Profile image upload
- Address selection with maps

#### **Home Screen** ✅
- Service categories display
- Featured services carousel
- Search functionality
- Location-based filtering
- Responsive design

#### **Category Screen** ✅
- Service category listing
- Sub-category navigation
- Provider profiles
- Rating and review display
- Booking integration

#### **About Screen** ✅
- Company information
- Mission and vision
- Team details
- Contact information
- Palestinian cultural context

#### **FAQs Screen** ✅
- Comprehensive FAQ system
- Search functionality
- Categorized questions
- Arabic/English support
- User-friendly interface

### **Design Components**

#### **Animated Handshake** ✅
- Custom animation widget
- Palestinian cultural symbol
- Smooth transitions
- Responsive scaling

#### **Tatreez Pattern** ✅
- Traditional Palestinian embroidery
- Custom SVG patterns
- Cultural authenticity
- Scalable design elements

## 🔐 **Authentication System**

### **User Roles**
1. **Client**: Service consumers
2. **Provider**: Service providers
3. **Admin**: Platform administrators

### **Authentication Flow**
1. **Registration**: Email/phone + password
2. **Verification**: Email/SMS verification
3. **Login**: JWT token generation
4. **Session**: Token-based authentication
5. **Refresh**: Automatic token renewal

### **Security Features**
- Password hashing with bcrypt
- JWT token authentication
- Role-based access control
- Input validation and sanitization
- Rate limiting protection

## 📊 **Data Management**

### **Local Storage Strategy**
- **Hive**: NoSQL database for complex data
- **SharedPreferences**: Simple key-value storage
- **Cache**: Image and API response caching

### **State Management**
- **BLoC Pattern**: Predictable state management
- **Event-Driven**: User actions trigger events
- **Immutable State**: State changes through events
- **Side Effects**: API calls and local storage

### **API Integration**
- **Dio Client**: HTTP requests with interceptors
- **Error Handling**: Comprehensive error management
- **Retry Logic**: Automatic retry on failure
- **Offline Support**: Local data persistence

## 🌍 **Localization & Internationalization**

### **Supported Languages**
- **English**: Primary language
- **Arabic**: RTL support with cultural context

### **Localization Features**
- **Dynamic Language Switching**
- **RTL Layout Support**
- **Cultural Date/Time Formatting**
- **Currency Display (ILS - Israeli Shekel)**
- **Palestine-Specific Content**

### **String Management**
- **Centralized String Constants**
- **Category-Based Organization**
- **Context-Aware Translations**
- **Cultural Sensitivity**

## 📍 **Location & Maps**

### **Location Services**
- **GPS Integration**: Current location detection
- **Address Geocoding**: Convert coordinates to addresses
- **Reverse Geocoding**: Convert addresses to coordinates
- **Location Permissions**: Proper permission handling

### **Maps Integration**
- **Google Maps**: Primary mapping service
- **Custom Markers**: Service provider locations
- **Route Planning**: Navigation to service locations
- **Area Selection**: Service area boundaries

## 💳 **Payment System**

### **Payment Methods**
- **Cash**: Traditional payment method
- **Digital Wallets**: Modern payment options
- **Bank Transfer**: Direct bank payments
- **Credit Cards**: International payment support

### **Payment Flow**
1. **Booking Creation**: Service selection and scheduling
2. **Price Calculation**: Service cost + fees
3. **Payment Processing**: Secure payment gateway
4. **Confirmation**: Payment verification
5. **Service Execution**: Provider notification

## 📱 **Platform Support**

### **Mobile Platforms**
- **Android**: API level 21+ (Android 5.0+)
- **iOS**: iOS 11.0+
- **Responsive Design**: Adaptive layouts

### **Web Platform**
- **Progressive Web App**: PWA capabilities
- **Responsive Web**: Desktop and tablet support
- **Cross-Browser**: Modern browser compatibility

## 🔧 **Development Rules & Standards**

### **Code Organization**
1. **Feature-Based Structure**: Each feature is self-contained
2. **Clean Architecture**: Separation of concerns
3. **Dependency Injection**: Loose coupling
4. **Single Responsibility**: Each class has one purpose

### **Naming Conventions**
- **Files**: snake_case.dart
- **Classes**: PascalCase
- **Variables**: camelCase
- **Constants**: UPPER_SNAKE_CASE
- **Private Members**: _privateMember

### **State Management Rules**
1. **Immutable State**: Never modify state directly
2. **Event-Driven**: All state changes through events
3. **Predictable**: Same input always produces same output
4. **Testable**: Easy to unit test

### **API Design Rules**
1. **RESTful**: Standard HTTP methods
2. **Consistent**: Uniform response format
3. **Versioned**: API versioning support
4. **Documented**: Clear API documentation

### **Security Rules**
1. **Input Validation**: Validate all user inputs
2. **Authentication**: JWT token validation
3. **Authorization**: Role-based access control
4. **Data Encryption**: Sensitive data encryption
5. **HTTPS Only**: Secure communication

## 🚀 **Deployment & Environment**

### **Development Environment**
- **Local MongoDB**: Docker or local installation
- **Hot Reload**: Automatic code reloading
- **Debug Mode**: Detailed error logging
- **Mock Data**: Sample data for testing

### **Production Environment**
- **MongoDB Atlas**: Cloud database
- **Environment Variables**: Secure configuration
- **Logging**: Production logging setup
- **Monitoring**: Application monitoring
- **Backup**: Regular data backups

### **CI/CD Pipeline**
- **Code Quality**: Linting and formatting
- **Testing**: Unit and integration tests
- **Build**: Automated build process
- **Deployment**: Automated deployment

## 📈 **Performance Optimization**

### **Frontend Optimization**
- **Image Optimization**: Compressed images
- **Lazy Loading**: On-demand content loading
- **Caching**: API response caching
- **Code Splitting**: Reduced bundle size

### **Backend Optimization**
- **Database Indexing**: Optimized queries
- **Connection Pooling**: Efficient database connections
- **Caching**: Redis caching layer
- **Compression**: Response compression

## 🧪 **Testing Strategy**

### **Frontend Testing**
- **Unit Tests**: Individual component testing
- **Widget Tests**: UI component testing
- **Integration Tests**: Feature testing
- **E2E Tests**: End-to-end testing

### **Backend Testing**
- **Unit Tests**: Function testing
- **Integration Tests**: API endpoint testing
- **Database Tests**: Data layer testing
- **Load Testing**: Performance testing

## 📚 **Documentation Standards**

### **Code Documentation**
- **Inline Comments**: Complex logic explanation
- **API Documentation**: Endpoint documentation
- **README Files**: Setup and usage instructions
- **Architecture Docs**: System design documentation

### **User Documentation**
- **User Guides**: Feature usage instructions
- **FAQ System**: Common questions and answers
- **Help Center**: Comprehensive help documentation
- **Video Tutorials**: Visual learning resources

## 🔄 **Version Control & Git**

### **Branch Strategy**
- **main**: Production-ready code
- **develop**: Development integration
- **feature/***: New feature development
- **hotfix/***: Critical bug fixes

### **Commit Standards**
- **Conventional Commits**: Standardized commit messages
- **Feature Commits**: Descriptive commit messages
- **Atomic Commits**: Single responsibility commits
- **Branch Protection**: Code review requirements

## 🎯 **Future Roadmap**

### **Phase 1: Core Features** ✅
- [x] User authentication
- [x] Service management
- [x] Booking system
- [x] Basic UI/UX

### **Phase 2: Advanced Features**
- [ ] Real-time messaging
- [ ] Payment integration
- [ ] Push notifications
- [ ] Advanced search

### **Phase 3: Platform Enhancement**
- [ ] AI-powered recommendations
- [ ] Advanced analytics
- [ ] Multi-language support
- [ ] Offline capabilities

### **Phase 4: Scale & Optimize**
- [ ] Performance optimization
- [ ] Advanced security
- [ ] Enterprise features
- [ ] API marketplace

## 📞 **Support & Maintenance**

### **Bug Reporting**
- **Issue Tracking**: GitHub issues
- **Priority Levels**: Critical, High, Medium, Low
- **Reproduction Steps**: Clear bug documentation
- **Environment Details**: System information

### **Feature Requests**
- **User Feedback**: User-driven feature requests
- **Market Research**: Industry trend analysis
- **Technical Feasibility**: Development assessment
- **Priority Ranking**: Impact vs effort analysis

---

## 📝 **Documentation Notes**

This documentation serves as the **single source of truth** for the PalHands project. It should be updated whenever:

1. **New features are implemented**
2. **Architecture changes occur**
3. **Development rules are modified**
4. **New team members join**

**Last Updated**: [Current Date]
**Version**: 1.0.0
**Maintained By**: PalHands Development Team 