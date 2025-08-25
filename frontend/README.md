# PalHands Frontend (Flutter)

Flutter app for PalHands with web support.

## Quick start (Windows PowerShell)

1. Install deps
- flutter pub get

2. Run (Web)
- flutter run -d chrome --web-port 8000

3. Backend URL
- Point API base URL to http://127.0.0.1:3000 (see backend server.js IPv4 bind)

## Notes

- Ensure CORS_ORIGIN in backend .env includes http://127.0.0.1:8000 and/or http://localhost:8000
- For password reset in dev without SMTP, see backend/GET_PASSWORD_RESET_TOKEN.md
