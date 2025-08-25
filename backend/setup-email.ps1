# PalHands Email Setup Script
# This script helps you configure email settings for password reset functionality

Write-Host "=== PalHands Email Setup ===" -ForegroundColor Green
Write-Host ""

# Check if .env file exists
if (Test-Path ".env") {
    Write-Host "✅ .env file found" -ForegroundColor Green
} else {
    Write-Host "❌ .env file not found. Creating from template..." -ForegroundColor Yellow
    Copy-Item "env.example" ".env"
    Write-Host "✅ .env file created from template" -ForegroundColor Green
}

Write-Host ""
Write-Host "Choose your email provider:" -ForegroundColor Cyan
Write-Host "1. Gmail (Recommended for development)"
Write-Host "2. Outlook/Hotmail"
Write-Host "3. Custom SMTP Server"
Write-Host "4. Skip email setup (use console logging)"
Write-Host ""

$choice = Read-Host "Enter your choice (1-4)"

switch ($choice) {
    "1" {
        Write-Host ""
        Write-Host "=== Gmail SMTP Setup ===" -ForegroundColor Green
        Write-Host "Note: You need to enable 2-Factor Authentication and generate an App Password"
        Write-Host "1. Go to Google Account settings"
        Write-Host "2. Security → 2-Step Verification → App passwords"
        Write-Host "3. Generate password for 'Mail'"
        Write-Host ""
        
        $email = Read-Host "Enter your Gmail address"
        $appPassword = Read-Host "Enter your 16-digit App Password"
        
        # Update .env file
        $envContent = Get-Content ".env" -Raw
        $envContent = $envContent -replace "EMAIL_HOST=.*", "EMAIL_HOST=smtp.gmail.com"
        $envContent = $envContent -replace "EMAIL_PORT=.*", "EMAIL_PORT=587"
        $envContent = $envContent -replace "EMAIL_USER=.*", "EMAIL_USER=$email"
        $envContent = $envContent -replace "EMAIL_PASS=.*", "EMAIL_PASS=$appPassword"
        $envContent = $envContent -replace "EMAIL_FROM=.*", "EMAIL_FROM=PalHands <$email>"
        
        Set-Content ".env" $envContent
        Write-Host "✅ Gmail SMTP configured in .env file" -ForegroundColor Green
    }
    
    "2" {
        Write-Host ""
        Write-Host "=== Outlook/Hotmail SMTP Setup ===" -ForegroundColor Green
        
        $email = Read-Host "Enter your Outlook/Hotmail address"
        $password = Read-Host "Enter your password" -AsSecureString
        $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
        
        # Update .env file
        $envContent = Get-Content ".env" -Raw
        $envContent = $envContent -replace "EMAIL_HOST=.*", "EMAIL_HOST=smtp-mail.outlook.com"
        $envContent = $envContent -replace "EMAIL_PORT=.*", "EMAIL_PORT=587"
        $envContent = $envContent -replace "EMAIL_USER=.*", "EMAIL_USER=$email"
        $envContent = $envContent -replace "EMAIL_PASS=.*", "EMAIL_PASS=$passwordPlain"
        $envContent = $envContent -replace "EMAIL_FROM=.*", "EMAIL_FROM=PalHands <$email>"
        
        Set-Content ".env" $envContent
        Write-Host "✅ Outlook SMTP configured in .env file" -ForegroundColor Green
    }
    
    "3" {
        Write-Host ""
        Write-Host "=== Custom SMTP Setup ===" -ForegroundColor Green
        
        $host = Read-Host "Enter SMTP host (e.g., smtp.yourdomain.com)"
        $port = Read-Host "Enter SMTP port (e.g., 587)"
        $user = Read-Host "Enter SMTP username"
        $password = Read-Host "Enter SMTP password" -AsSecureString
        $passwordPlain = [Runtime.InteropServices.Marshal]::PtrToStringAuto([Runtime.InteropServices.Marshal]::SecureStringToBSTR($password))
        $from = Read-Host "Enter from email address"
        
        # Update .env file
        $envContent = Get-Content ".env" -Raw
        $envContent = $envContent -replace "EMAIL_HOST=.*", "EMAIL_HOST=$host"
        $envContent = $envContent -replace "EMAIL_PORT=.*", "EMAIL_PORT=$port"
        $envContent = $envContent -replace "EMAIL_USER=.*", "EMAIL_USER=$user"
        $envContent = $envContent -replace "EMAIL_PASS=.*", "EMAIL_PASS=$passwordPlain"
        $envContent = $envContent -replace "EMAIL_FROM=.*", "EMAIL_FROM=PalHands <$from>"
        
        Set-Content ".env" $envContent
        Write-Host "✅ Custom SMTP configured in .env file" -ForegroundColor Green
    }
    
    "4" {
        Write-Host ""
        Write-Host "=== Skipping Email Setup ===" -ForegroundColor Yellow
        Write-Host "Password reset tokens will be logged to console in development mode"
        Write-Host "See GET_PASSWORD_RESET_TOKEN.md for instructions"
    }
    
    default {
        Write-Host "❌ Invalid choice. Please run the script again." -ForegroundColor Red
        exit 1
    }
}

Write-Host ""
Write-Host "=== Next Steps ===" -ForegroundColor Green
Write-Host "1. Restart your server (Ctrl+C then npm run dev)"
Write-Host "2. Test password reset functionality"
Write-Host "3. Check if emails are being sent"
Write-Host ""

if ($choice -ne "4") {
    Write-Host "✅ Email configuration updated! Restart your server to apply changes." -ForegroundColor Green
} else {
    Write-Host "ℹ️  Using console logging mode. Check server console for password reset tokens." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "For more help, see:" -ForegroundColor Cyan
Write-Host "- EMAIL_SETUP.md (detailed email setup guide)"
Write-Host "- GET_PASSWORD_RESET_TOKEN.md (console token guide)"
Write-Host ""
