# MongoDB Setup Script for PalHands
# This script helps you set up MongoDB connection

Write-Host "=== PalHands MongoDB Setup ===" -ForegroundColor Green
Write-Host ""

# Check if .env file exists
$envFile = ".env"
if (Test-Path $envFile) {
    Write-Host "✅ .env file already exists" -ForegroundColor Green
    $choice = Read-Host "Do you want to update the MongoDB URI? (y/n)"
    if ($choice -ne "y" -and $choice -ne "Y") {
        Write-Host "Setup cancelled." -ForegroundColor Yellow
        exit
    }
} else {
    Write-Host "📝 Creating .env file..." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Choose your MongoDB setup option:" -ForegroundColor Cyan
Write-Host "1. MongoDB Atlas (Cloud - Recommended)"
Write-Host "2. Local MongoDB (requires installation)"
Write-Host "3. Skip setup (manual configuration)"
Write-Host ""

$option = Read-Host "Enter your choice (1-3)"

switch ($option) {
    "1" {
        Write-Host ""
        Write-Host "=== MongoDB Atlas Setup ===" -ForegroundColor Green
        Write-Host "1. Go to https://www.mongodb.com/atlas"
        Write-Host "2. Create a free account and cluster"
        Write-Host "3. Get your connection string"
        Write-Host ""
        
        $atlasUri = Read-Host "Enter your MongoDB Atlas connection string"
        
        if ($atlasUri -match "mongodb\+srv://") {
            $envContent = @"
# ========================================
# PalHands Backend Environment Variables
# ========================================

# ========================================
# Server Configuration
# ========================================
NODE_ENV=development
PORT=3000
HOST=localhost

# ========================================
# Database Configuration
# ========================================
MONGODB_URI=$atlasUri

# ========================================
# JWT Configuration
# ========================================
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=your-refresh-token-secret-key
JWT_REFRESH_EXPIRES_IN=30d

# ========================================
# Email Configuration (Nodemailer)
# ========================================
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
EMAIL_FROM=PalHands <support@palhands.com>

# Frontend Base URL used for building password reset links
APP_BASE_URL=http://localhost:8080

# ========================================
# File Upload Configuration
# ========================================
MAX_FILE_SIZE=5242880
UPLOAD_PATH=./uploads
ALLOWED_IMAGE_TYPES=image/jpeg,image/png,image/webp
ALLOWED_DOCUMENT_TYPES=application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document

# ========================================
# Security Configuration
# ========================================
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
CORS_ORIGIN=http://localhost:3000,http://localhost:8080
SERVER_ORIGIN=http://localhost:3000

# ========================================
# Payment Configuration (Sample)
# ========================================
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key_here
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_CLIENT_SECRET=your_paypal_client_secret

# ========================================
# SMS Configuration (Sample)
# ========================================
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=+1234567890

# ========================================
# Maps & Location Configuration
# ========================================
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
GEOCODING_API_KEY=your_geocoding_api_key_here

# ========================================
# Notification Configuration
# ========================================
PUSH_NOTIFICATION_KEY=your_push_notification_key
FCM_SERVER_KEY=your_fcm_server_key

# ========================================
# Logging Configuration
# ========================================
LOG_LEVEL=debug
LOG_FILE_PATH=./logs/app.log
LOG_MAX_SIZE=10485760
LOG_MAX_FILES=5

# ========================================
# Redis Configuration (Optional)
# ========================================
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=
REDIS_DB=0

# ========================================
# External APIs (Sample)
# ========================================
WEATHER_API_KEY=your_weather_api_key
CURRENCY_API_KEY=your_currency_api_key

# ========================================
# Feature Flags
# ========================================
ENABLE_EMAIL_VERIFICATION=true
ENABLE_SMS_VERIFICATION=false
ENABLE_PUSH_NOTIFICATIONS=true
ENABLE_ANALYTICS=false
ENABLE_DEBUG_MODE=true

# ========================================
# Business Logic Configuration
# ========================================
MAX_BOOKINGS_PER_USER=10
MIN_BOOKING_DURATION=30
MAX_BOOKING_DURATION=480
COMMISSION_PERCENTAGE=10
MINIMUM_WITHDRAWAL_AMOUNT=50
BOOKING_MIN_LEAD_MINUTES=2880
CANCELLATION_MIN_LEAD_MINUTES=2880

# ========================================
# Development/Testing
# ========================================
SEED_DATABASE=false
CLEAR_DATABASE_ON_START=false
MOCK_PAYMENTS=true
SKIP_EMAIL_SENDING=false
"@
            
            $envContent | Out-File -FilePath $envFile -Encoding UTF8
            Write-Host "✅ .env file created with Atlas connection!" -ForegroundColor Green
        } else {
            Write-Host "❌ Invalid Atlas connection string format" -ForegroundColor Red
            Write-Host "Expected format: mongodb+srv://username:password@cluster.mongodb.net/database"
        }
    }
    "2" {
        Write-Host ""
        Write-Host "=== Local MongoDB Setup ===" -ForegroundColor Green
        Write-Host "For local MongoDB, you need to:"
        Write-Host "1. Install MongoDB Community Server from https://www.mongodb.com/try/download/community"
        Write-Host "2. Start the MongoDB service"
        Write-Host ""
        
        $envContent = @"
# ========================================
# PalHands Backend Environment Variables
# ========================================

# ========================================
# Server Configuration
# ========================================
NODE_ENV=development
PORT=3000
HOST=localhost

# ========================================
# Database Configuration
# ========================================
MONGODB_URI=mongodb://127.0.0.1:27017/palhands-dev

# ========================================
# JWT Configuration
# ========================================
JWT_SECRET=your-super-secret-jwt-key-change-this-in-production
JWT_EXPIRES_IN=7d
JWT_REFRESH_SECRET=your-refresh-token-secret-key
JWT_REFRESH_EXPIRES_IN=30d

# ========================================
# Email Configuration (Nodemailer)
# ========================================
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-app-password
EMAIL_FROM=PalHands <support@palhands.com>

# Frontend Base URL used for building password reset links
APP_BASE_URL=http://localhost:8080

# ========================================
# File Upload Configuration
# ========================================
MAX_FILE_SIZE=5242880
UPLOAD_PATH=./uploads
ALLOWED_IMAGE_TYPES=image/jpeg,image/png,image/webp
ALLOWED_DOCUMENT_TYPES=application/pdf,application/msword,application/vnd.openxmlformats-officedocument.wordprocessingml.document

# ========================================
# Security Configuration
# ========================================
BCRYPT_ROUNDS=12
RATE_LIMIT_WINDOW_MS=900000
RATE_LIMIT_MAX_REQUESTS=100
CORS_ORIGIN=http://localhost:3000,http://localhost:8080
SERVER_ORIGIN=http://localhost:3000

# ========================================
# Payment Configuration (Sample)
# ========================================
STRIPE_SECRET_KEY=sk_test_your_stripe_secret_key_here
STRIPE_PUBLISHABLE_KEY=pk_test_your_stripe_publishable_key_here
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_CLIENT_SECRET=your_paypal_client_secret

# ========================================
# SMS Configuration (Sample)
# ========================================
TWILIO_ACCOUNT_SID=your_twilio_account_sid
TWILIO_AUTH_TOKEN=your_twilio_auth_token
TWILIO_PHONE_NUMBER=+1234567890

# ========================================
# Maps & Location Configuration
# ========================================
GOOGLE_MAPS_API_KEY=your_google_maps_api_key_here
GEOCODING_API_KEY=your_geocoding_api_key_here

# ========================================
# Notification Configuration
# ========================================
PUSH_NOTIFICATION_KEY=your_push_notification_key
FCM_SERVER_KEY=your_fcm_server_key

# ========================================
# Logging Configuration
# ========================================
LOG_LEVEL=debug
LOG_FILE_PATH=./logs/app.log
LOG_MAX_SIZE=10485760
LOG_MAX_FILES=5

# ========================================
# Redis Configuration (Optional)
# ========================================
REDIS_URL=redis://localhost:6379
REDIS_PASSWORD=
REDIS_DB=0

# ========================================
# External APIs (Sample)
# ========================================
WEATHER_API_KEY=your_weather_api_key
CURRENCY_API_KEY=your_currency_api_key

# ========================================
# Feature Flags
# ========================================
ENABLE_EMAIL_VERIFICATION=true
ENABLE_SMS_VERIFICATION=false
ENABLE_PUSH_NOTIFICATIONS=true
ENABLE_ANALYTICS=false
ENABLE_DEBUG_MODE=true

# ========================================
# Business Logic Configuration
# ========================================
MAX_BOOKINGS_PER_USER=10
MIN_BOOKING_DURATION=30
MAX_BOOKING_DURATION=480
COMMISSION_PERCENTAGE=10
MINIMUM_WITHDRAWAL_AMOUNT=50
BOOKING_MIN_LEAD_MINUTES=2880
CANCELLATION_MIN_LEAD_MINUTES=2880

# ========================================
# Development/Testing
# ========================================
SEED_DATABASE=false
CLEAR_DATABASE_ON_START=false
MOCK_PAYMENTS=true
SKIP_EMAIL_SENDING=false
"@
            
            $envContent | Out-File -FilePath $envFile -Encoding UTF8
            Write-Host "✅ .env file created with local MongoDB connection!" -ForegroundColor Green
            Write-Host "⚠️  Make sure to install and start MongoDB locally" -ForegroundColor Yellow
        }
    }
    "3" {
        Write-Host "Setup skipped. You can manually create the .env file." -ForegroundColor Yellow
    }
    default {
        Write-Host "Invalid option. Setup cancelled." -ForegroundColor Red
    }
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Make sure your MongoDB is running (Atlas or local)"
Write-Host "2. Run: npm run dev"
Write-Host "3. You should see: ✅ Connected to MongoDB"
Write-Host ""
Write-Host "For detailed setup instructions, see: MONGODB_SETUP.md" -ForegroundColor Cyan
