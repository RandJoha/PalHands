# Authentication Credentials

## Provider Accounts (Provider Collection)

**Password for ALL providers**: `Provider123!`

## Sample Provider Accounts (for testing)

### English Names (pattern examples):
- `provider.rami.0@palhands.com` - Rami Services
- `provider.maya.1@palhands.com` - Maya Haddad  
- `provider.omar.2@palhands.com` - Omar Khalil
- `provider.sara.3@palhands.com` - Sara Nasser
- `provider.khaled.4@palhands.com` - Khaled Mansour
- `provider.yara.5@palhands.com` - Yara Saleh
- `provider.hadi.6@palhands.com` - Hadi Suleiman
- `provider.noor.7@palhands.com` - Noor Ali
- `provider.lina.8@palhands.com` - Lina Faris
- `provider.osama.9@palhands.com` - Osama T.

### Arabic Names:
- `provider15@palhands.com` - محمد العابد
- `provider16@palhands.com` - سارة يوسف
- `provider17@palhands.com` - ليلى حسن
- `provider18@palhands.com` - أحمد درويش
- `provider19@palhands.com` - نور الهدى

## Provider Features:
- ✅ All providers are **verified** and **active**
- 🌍 Distributed across: Ramallah, Nablus, Jerusalem, Hebron, Bethlehem, Gaza
- 🗣️ Languages: Arabic, English, Hebrew, Turkish (various combinations)
- 💰 Hourly rates: 45-150 ILS
- ⭐ Ratings: 3.8-5.0 stars with realistic review counts
- 🛠️ Services: Each provider offers 2-5 services from different categories

## Authentication:
- **Role**: `provider` (separate from User collection)
- **Login endpoint**: `POST /api/auth/login`
- **Response**: Includes provider profile, services, ratings, and JWT token

## User Accounts (User Collection)

### Client Account:
- `roro@palhands.com` - Password: `roro123` (Role: client)

### Admin Account:
- `admin@example.com` - Password: `Admin123!` (Role: admin)

## Database Collections:
- **Users Collection**: Contains clients and admins
- **Providers Collection**: Contains service providers (separate from users)

## Usage:
Use any of these credentials to test the respective dashboards, booking flow, or authentication system.
