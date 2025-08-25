# Email Setup Guide for PalHands

## Problem
Password reset emails are not being sent because SMTP is not configured. This affects ALL users (clients, providers, and admins).

## Current Behavior
- Password reset requests work correctly
- Tokens are generated and stored in database
- Emails fail to send due to missing SMTP configuration
- System falls back to dev mode and logs tokens to console

## Solution Options

### Option 1: Configure SMTP (Recommended for Production)

#### Gmail SMTP Setup
1. Enable 2-Factor Authentication on your Gmail account
2. Generate an App Password:
   - Go to Google Account settings
   - Security → 2-Step Verification → App passwords
   - Generate password for "Mail"
3. Update your `.env` file:

```env
# Email Configuration
EMAIL_HOST=smtp.gmail.com
EMAIL_PORT=587
EMAIL_USER=your-email@gmail.com
EMAIL_PASS=your-16-digit-app-password
EMAIL_FROM=PalHands <your-email@gmail.com>
```

#### Outlook/Hotmail SMTP Setup
```env
EMAIL_HOST=smtp-mail.outlook.com
EMAIL_PORT=587
EMAIL_USER=your-email@outlook.com
EMAIL_PASS=your-password
EMAIL_FROM=PalHands <your-email@outlook.com>
```

#### Custom SMTP Server
```env
EMAIL_HOST=your-smtp-server.com
EMAIL_PORT=587
EMAIL_USER=your-username
EMAIL_PASS=your-password
EMAIL_FROM=PalHands <noreply@yourdomain.com>
```

### Option 2: Development Mode (Current Setup)
If you prefer to keep the current dev setup:

1. **Check Server Console**: Password reset tokens are logged to the console
2. **Look for these log messages**:
   ```
   [DEV MAILER] No SMTP configured. Logging email to console.
   [DEV MAILER] To: admin@example.com
   [DEV MAILER] Subject: Reset your PalHands password
   [DEV MAILER] Text: Use this token to reset your password: [TOKEN]
   [DEV MAILER] HTML: [HTML content with reset link]
   ```

3. **Copy the token** from the console and use it to reset the password

### Option 3: Use a Free Email Service

#### SendGrid (Free tier: 100 emails/day)
1. Sign up at sendgrid.com
2. Create an API key
3. Update `.env`:

```env
EMAIL_HOST=smtp.sendgrid.net
EMAIL_PORT=587
EMAIL_USER=apikey
EMAIL_PASS=your-sendgrid-api-key
EMAIL_FROM=PalHands <noreply@yourdomain.com>
```

#### Mailgun (Free tier: 5,000 emails/month)
1. Sign up at mailgun.com
2. Get your SMTP credentials
3. Update `.env`:

```env
EMAIL_HOST=smtp.mailgun.org
EMAIL_PORT=587
EMAIL_USER=postmaster@yourdomain.mailgun.org
EMAIL_PASS=your-mailgun-password
EMAIL_FROM=PalHands <noreply@yourdomain.com>
```

## Testing Email Configuration

1. **Restart the server** after updating `.env`
2. **Test password reset** for any account
3. **Check server logs** for email sending status
4. **Verify email delivery** in your inbox

## Troubleshooting

### Common Issues

1. **"Authentication failed"**
   - Check username/password
   - Ensure 2FA is enabled for Gmail
   - Use App Password, not regular password

2. **"Connection timeout"**
   - Check firewall settings
   - Verify SMTP host and port
   - Try different ports (587, 465, 25)

3. **"Relay not permitted"**
   - Check SMTP provider settings
   - Verify sender email domain
   - Contact SMTP provider support

### Debug Mode
Enable debug logging by adding to `.env`:
```env
LOG_LEVEL=debug
ENABLE_DEBUG_MODE=true
```

## Security Notes

1. **Never commit `.env` files** to version control
2. **Use App Passwords** instead of regular passwords
3. **Restrict SMTP access** to your application only
4. **Monitor email sending** for abuse detection

## Next Steps

1. Choose an email setup option
2. Update your `.env` file
3. Restart the server
4. Test password reset functionality
5. Verify emails are being sent

## Support

If you continue to have issues:
1. Check server console for error messages
2. Verify SMTP credentials
3. Test with a simple email client
4. Check firewall/network restrictions
