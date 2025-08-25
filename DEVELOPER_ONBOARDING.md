# PalHands — Developer Onboarding (Windows)

This guide gets you running the PalHands backend (Node/Express) and frontend (Flutter) fast on Windows (PowerShell).

## TL;DR

- Backend
  - cd backend; npm ci
  - Copy-Item env.example .env; notepad .env
  - Fill MONGODB_URI and JWT_SECRET; set CORS_ORIGIN to your frontend URL(s)
  - npm run dev → http://127.0.0.1:3000/api/health
- Frontend
  - cd frontend; flutter pub get
  - flutter run -d chrome --web-port 8000
  - Ensure API base URL points to http://127.0.0.1:3000

## Prerequisites

- Node.js 18+ and npm
- Flutter 3+ and Dart SDK; Chrome for web dev
- A MongoDB connection (Atlas recommended). See BACKEND_DOCUMENTATION.md and backend/ENVIRONMENT_SETUP.md

## Backend (Node/Express)

1) Install deps
- cd backend
- npm ci

2) Configure env
- Copy-Item env.example .env
- Or run: .\setup-env.ps1 (guided on Windows)
- Edit .env and set at minimum:
  - MONGODB_URI=mongodb+srv://...
  - JWT_SECRET=your-strong-secret
  - CORS_ORIGIN=http://localhost:8000,http://127.0.0.1:8000

3) Run
- npm run dev
- Health: http://127.0.0.1:3000/api/health

Notes
- Server binds to 127.0.0.1 (IPv4) by default (see server.js). Prefer 127.0.0.1 over localhost in the frontend.
- Postman collection: backend/postman_collection.json

## Frontend (Flutter)

1) Install deps
- cd frontend
- flutter pub get

2) Configure API base URL
- Ensure your HTTP client targets http://127.0.0.1:3000 (dev)
- If you use a .env/config file in Flutter, align it accordingly.

3) Run
- Web (Chrome): flutter run -d chrome --web-port 8000
- Mobile: connect a device/emulator and run flutter run

## Testing

- Backend: npm test (Jest); e2e: npm run test:api
- Frontend: flutter test

## Common issues

- CORS blocked: Update CORS_ORIGIN in backend .env to include your frontend origin (e.g., http://localhost:8000)
- Cannot connect to API: Confirm backend is on 127.0.0.1:3000 and the frontend uses that exact host
- Mongo errors: Verify MONGODB_URI; allow your IP in Atlas
- Email reset links: In dev without SMTP, password reset tokens/links are logged; see backend/GET_PASSWORD_RESET_TOKEN.md

## Key docs

- BACKEND_DOCUMENTATION.md — API, models, security
- BACKEND_FRONTEND_INTEGRATION_TODO.md — integration tracker
- PROJECT_DOCUMENTATION.md — project overview
- TECH_MEMORY.md — reports module notes
- backend/ENVIRONMENT_SETUP.md — env reference and SMTP notes
