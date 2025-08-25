# PalHands Environment Setup Script
# This script helps you set up your environment file

Write-Host "🚀 PalHands Environment Setup" -ForegroundColor Green
Write-Host "================================" -ForegroundColor Green

# Check if .env already exists
if (Test-Path ".env") {
    Write-Host "⚠️  .env file already exists!" -ForegroundColor Yellow
    $overwrite = Read-Host "Do you want to overwrite it? (y/N)"
    if ($overwrite -ne "y" -and $overwrite -ne "Y") {
        Write-Host "Setup cancelled." -ForegroundColor Red
        exit
    }
}

# Copy the simple environment file
Write-Host "📋 Copying environment template..." -ForegroundColor Cyan
Copy-Item "env.simple" ".env"

Write-Host "✅ Environment file created successfully!" -ForegroundColor Green
Write-Host ""
Write-Host "📝 Next steps:" -ForegroundColor Yellow
Write-Host "1. Edit the .env file with your specific values" -ForegroundColor White
Write-Host "2. Set up MongoDB (see MONGODB_SETUP.md)" -ForegroundColor White
Write-Host "3. Run 'npm install' to install dependencies" -ForegroundColor White
Write-Host "4. Run 'npm run dev' to start the server" -ForegroundColor White
Write-Host ""
Write-Host "📚 For detailed setup instructions, see:" -ForegroundColor Cyan
Write-Host "   - ENVIRONMENT_SETUP.md" -ForegroundColor White
Write-Host "   - MONGODB_SETUP.md" -ForegroundColor White 