# Quick Fix: Get Password Reset Token from Console

## Immediate Solution (Development Mode)

Since SMTP is not configured, password reset tokens are logged to the server console. Here's how to get them:

### Step 1: Check Server Console
1. Look at the terminal where you ran `npm run dev`
2. After requesting a password reset, you should see logs like:

```
[DEV MAILER] No SMTP configured. Logging email to console.
[DEV MAILER] To: admin@example.com
[DEV MAILER] Subject: Reset your PalHands password
[DEV MAILER] Text: Use this token to reset your password: abc123def456...
[DEV MAILER] HTML: <p>Use this token to reset your password:</p><p><b>abc123def456...</b></p>...
```

### Step 2: Copy the Token
Copy the token from the console output (it's a long string of random characters)

### Step 3: Use the Token
1. Go to your password reset page
2. Enter the token you copied
3. Set your new password

### Step 4: Test the Reset
Try logging in with the new password

## For Admin Account Specifically

1. **Request password reset** for `admin@example.com`
2. **Check console** for the token
3. **Use the token** to reset the password
4. **Login** with the new password

## Why This Happens

- ✅ **Password reset system works correctly**
- ✅ **Tokens are generated and stored**
- ❌ **Emails can't be sent (no SMTP)**
- ✅ **System logs tokens to console as fallback**

## Long-term Solution

Configure SMTP in your `.env` file to actually send emails. See `EMAIL_SETUP.md` for detailed instructions.

## Quick Test

1. Request password reset for admin@example.com
2. Check server console for token
3. Use token to reset password
4. Login with new password

This should work for ALL accounts (admin, client, provider) since they all use the same password reset system.
