# Start PalHands Servers Script
Write-Host "🚀 Starting PalHands servers..." -ForegroundColor Green

# Start Backend Server
Write-Host "📡 Starting Backend Server..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd backend; npm start" -WindowStyle Normal

# Wait a moment for backend to start
Start-Sleep -Seconds 3

# Start Frontend Server
Write-Host "🌐 Starting Frontend Server..." -ForegroundColor Yellow
Start-Process powershell -ArgumentList "-NoExit", "-Command", "cd frontend; flutter run -d chrome --web-port=8080" -WindowStyle Normal

Write-Host "✅ Both servers should now be starting!" -ForegroundColor Green
Write-Host "📡 Backend: http://localhost:3000" -ForegroundColor Cyan
Write-Host "🌐 Frontend: http://localhost:8080" -ForegroundColor Cyan
Write-Host "🔍 Debug: http://localhost:8080/debug-chat" -ForegroundColor Cyan
