# PalHands Frontend (Flutter)

Flutter app for PalHands with web and mobile support.

## Quick start (Windows PowerShell)

### Web Development

1. Install deps
```bash
flutter pub get
```

2. Run (Web)
```bash
flutter run -d chrome --web-port 8000
```

3. Backend URL
- Point API base URL to http://127.0.0.1:3000 (see backend server.js IPv4 bind)

### Mobile Development (Android)

1. Prerequisites
- Android Studio installed
- Android emulator configured
- Backend server running

2. Start backend server
```bash
cd ../backend && npm start
```

3. Run mobile app (Release mode - recommended)
```bash
flutter run --release
```

4. Run mobile app (Debug mode - has floating sidebar)
```bash
flutter run
```

## Mobile Development Setup

### Android Configuration
The Android configuration is fully set up with:
- Complete Gradle build configuration
- AndroidManifest.xml with proper permissions
- MainActivity.kt implementation
- Android resources (styles, themes, launch background)

### API Configuration
The app automatically detects the platform and uses the correct API URL:
- **Web**: Uses `http://127.0.0.1:3000` (localhost)
- **Mobile**: Uses `http://192.168.56.1:3000` (computer's IP address)

### Mobile Development Commands

#### Essential Commands
```bash
# Check Flutter doctor
flutter doctor

# Accept Android licenses
flutter doctor --android-licenses

# List available emulators
flutter emulators

# Launch specific emulator
flutter emulators --launch <emulator_name>

# Clean Flutter build
flutter clean && flutter pub get
```

#### Troubleshooting Commands
```bash
# Check Android connectivity
powershell -Command "Invoke-WebRequest -Uri 'http://192.168.56.1:3000/api/health' -Method GET"

# Check computer's IP address
ipconfig | findstr "IPv4"
```

## Mobile Development Best Practices

### 1. Always Use Release Mode for Testing
- **Debug Mode**: Includes floating sidebar that interferes with touch input
- **Release Mode**: Clean interface without debug overlays
- **Command**: `flutter run --release`

### 2. Proper API Configuration
- **Web Development**: Use `127.0.0.1:3000` (localhost)
- **Mobile Development**: Use computer's IP address (e.g., `192.168.56.1:3000`)
- **Automatic Detection**: API config automatically detects platform and uses correct URL

### 3. Android Emulator Setup
- **IP Address**: Ensure emulator can reach computer's IP address
- **Network**: Both computer and emulator should be on same network
- **Backend**: Backend server must be running and accessible

### 4. Text Input Optimization
- **Focus Management**: Use `FocusNode` for proper focus handling
- **Keyboard Behavior**: Set appropriate `windowSoftInputMode` in AndroidManifest
- **Touch Events**: Ensure no overlays are blocking touch input

## Known Issues & Solutions

### Mobile Text Input Issues ✅ RESOLVED
- **Problem**: Users couldn't type in text fields despite cursor appearing
- **Root Cause**: Flutter debug overlay intercepting touch events
- **Solution**: Run app in release mode (`flutter run --release`)

### Mobile API Connectivity Issues ✅ RESOLVED
- **Problem**: Mobile app couldn't connect to backend server
- **Root Cause**: Android emulator using `127.0.0.1` (emulator's localhost) instead of computer's IP
- **Solution**: Updated API configuration to use computer's IP address

### Android Build Issues ✅ RESOLVED
- **Problem**: Missing Android configuration files preventing mobile build
- **Solution**: Created complete Android configuration structure with proper Gradle setup

## Notes

- Ensure CORS_ORIGIN in backend .env includes http://127.0.0.1:8000 and/or http://localhost:8000
- For password reset in dev without SMTP, see backend/GET_PASSWORD_RESET_TOKEN.md
- For mobile development, ensure backend server is accessible from Android emulator
- Use release mode for mobile testing to avoid debug overlay interference
