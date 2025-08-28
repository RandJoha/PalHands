const jwt = require('jsonwebtoken');
const User = require('../models/User');
const Provider = require('../models/Provider');
const asyncHandler = require('../utils/asyncHandler');
const { ok, created, error } = require('../utils/response');
const { sendEmail } = require('../services/mailer');

// Generate JWT token
const generateToken = (userId) => {
  return jwt.sign(
    { userId },
    process.env.JWT_SECRET,
    { expiresIn: process.env.JWT_EXPIRES_IN || '7d' }
  );
};

// Helper to create a verification token (dev-only flow)
const crypto = require('crypto');

// Helper: build public API base URL for links sent via email
const API_BASE = process.env.API_BASE_URL || `${process.env.APP_API_BASE_URL || 'http://localhost:3000'}/api`;

// Small HTML page that requires a real user click. It progressively enhances:
// - Without JavaScript or when inline scripts are blocked by CSP, the form submits normally to the API (still requiring a user click).
// - With JavaScript, we intercept submit, call the API via fetch, notify the app, and redirect smoothly.
function renderActionHtml({ title, heading, buttonText, actionPath, token, successText, redirectPath = '/user' }) {
  const appBase = process.env.APP_BASE_URL || 'http://localhost:8080';
  const redirectUrl = `${appBase}${redirectPath.startsWith('/') ? '' : '/'}${redirectPath}${redirectPath.includes('?') ? '&' : '?'}evt=email-updated`;
  // Use same-origin relative path to avoid CORS/env mismatches
  const actionUrl = `/api${actionPath}`;
  return `<!doctype html>
<html lang="en">
<head>
  <meta charset="utf-8" />
  <meta name="viewport" content="width=device-width, initial-scale=1" />
  <title>${title}</title>
  <style>
    body{font-family:system-ui,-apple-system,Segoe UI,Roboto,Ubuntu,Cantarell,Noto Sans,sans-serif;background:#faf7f5;color:#1f2937;margin:0;display:flex;align-items:center;justify-content:center;min-height:100vh}
    .card{background:#fff;border:1px solid #eee;border-radius:12px;box-shadow:0 6px 24px rgba(0,0,0,.08);padding:28px;max-width:520px;margin:16px}
    h1{font-size:20px;margin:0 0 10px}
    p{line-height:1.45}
    button{background:#CE1126;color:#fff;border:none;border-radius:10px;padding:12px 16px;font-weight:600;cursor:pointer}
    button:disabled{opacity:.7;cursor:not-allowed}
    .ok{color:#16a34a}
    .err{color:#dc2626}
    .muted{color:#6b7280;font-size:14px}
  </style>
  <script>
    function notifyAndClose(){
      try { localStorage.setItem('palhands:event', JSON.stringify({t: Date.now(), type: 'email:updated'})); } catch(e) {}
      try { window.opener && window.opener.postMessage({ source:'palhands', type:'email:updated' }, '*'); } catch(e) {}
      // Try closing if allowed; if not, we will redirect below
      try { window.close(); } catch(e) {}
    }
    function enhance(){
      const form = document.getElementById('frm');
      const btn = document.getElementById('cta');
      const status = document.getElementById('status');
      if (!form || !btn || !status) return;
      form.addEventListener('submit', async (ev) => {
        // Intercept for SPA-like UX. If fetch is blocked, the browser will still submit normally.
        ev.preventDefault();
        btn.disabled = true; status.textContent = 'Processing...'; status.className = 'muted';
        try {
          const res = await fetch('${actionUrl}', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify({ token: '${token}' })
          });
          const json = await res.json().catch(() => ({}));
          if (!res.ok) throw new Error(json?.message || 'Request failed');
          status.textContent = '${successText}'; status.className = 'ok';
          notifyAndClose();
          setTimeout(() => { window.location.replace('${redirectUrl}'); }, 450);
        } catch (e) {
          status.textContent = 'Error: ' + (e?.message || 'Something went wrong'); status.className = 'err';
          btn.disabled = false;
        }
      }, { once: false });
    }
    // Try to enhance after DOM is ready; if CSP blocks the script, the form still works and will POST.
    document.addEventListener('DOMContentLoaded', enhance);
  </script>
</head>
<body>
  <div class="card">
    <h1>${heading}</h1>
    <p>For your security, please confirm this action by clicking the button below.</p>
    <p id="status" class="muted">Waiting for your confirmation…</p>
    <form id="frm" method="POST" action="${actionUrl}">
      <input type="hidden" name="token" value="${token}" />
      <button id="cta" type="submit">${buttonText}</button>
    </form>
  </div>
</body>
</html>`;
}

// Register new user
const register = asyncHandler(async (req, res) => {
  const { firstName, lastName = '', email, phone, password, role = 'client', age, address } = req.body;
  console.log('Registration attempt:', { firstName, lastName, email, phone, password: password ? '[HIDDEN]' : 'MISSING', role });
  


    // Validate required fields and provide specific error messages
    const missingFields = [];
    if (!firstName) missingFields.push('firstName');
    if (!email) missingFields.push('email');
    if (!phone) missingFields.push('phone');
    if (!password) missingFields.push('password');
    
    if (missingFields.length > 0) {
      console.log('Missing fields:', missingFields);
      return error(res, 400, `Missing required fields: ${missingFields.join(', ')}`, [], 'VALIDATION_ERROR');
    }

    // Validate role
    const validRoles = ['client', 'provider', 'admin'];
    if (!validRoles.includes(role)) {
      return error(res, 400, 'Invalid role. Must be client, provider, or admin', [], 'VALIDATION_ERROR');
    }

    // Check if user already exists
    const existingUser = await User.findOne({
      $or: [{ email: email.toLowerCase() }, { phone }]
    });

    if (existingUser) {
      console.log('User already exists:', existingUser.email === email.toLowerCase() ? 'Email conflict' : 'Phone conflict');
      return error(res, 400, existingUser.email === email.toLowerCase() ? 'Email already registered' : 'Phone number already registered', [], 'CONFLICT');
    }

    // Create new user
    const user = new User({
      firstName,
      lastName,
      email: email.toLowerCase(),
      phone,
      password,
      role,
      age,
      // Initialize addresses array - only use this, no standalone address field
      addresses: (address && address.city && address.street) ? [{
        type: 'home',
        street: address.street.trim(),
        city: address.city.trim(),
        area: address.area?.trim() || '',
        coordinates: {
          latitude: null,
          longitude: null
        },
        isDefault: true
      }] : []
    });

    // If email verification enabled, set token (email sending can be added later)
    if (process.env.ENABLE_EMAIL_VERIFICATION === 'true') {
      user.emailVerificationToken = crypto.randomBytes(20).toString('hex');
      user.emailVerificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000); // 24h
    }

    await user.save();

    // Generate token
    const token = generateToken(user._id);

    // Return user data (without password) with clean structure
    const userResponse = {
      _id: user._id,
      // Personal info
      firstName: user.firstName,
      lastName: user.lastName,
      email: user.email,
      phone: user.phone,
      age: user.age,
      profileImage: user.profileImage,
      // Account info
      role: user.role,
      isVerified: user.isVerified,
      isActive: user.isActive,
      rating: user.rating,
      // Addresses
      addresses: user.addresses,
      // Metadata
      createdAt: user.createdAt
    };

  return created(res, { token, user: userResponse }, 'User registered successfully');
});

// Login user (now checks both User and Provider collections)
const login = asyncHandler(async (req, res) => {
    const { email, password } = req.body;

    // Validate required fields
    if (!email || !password) {
      return error(res, 400, 'Email and password are required', [], 'VALIDATION_ERROR');
    }

    // First, try to find user in the users collection
    let user = await User.findOne({ email: email.toLowerCase() }).select('+password');
    
    // If not found in users, check the providers collection
    if (!user) {
      const provider = await Provider.findOne({ email: email.toLowerCase() }).select('+password');
      if (provider) {
        // Check if provider is active
        if (!provider.isActive) {
          const message = provider.deactivationReason 
            ? `Your account has been deactivated by an administrator. Reason: ${provider.deactivationReason}`
            : 'Your account has been deactivated by an administrator. Please contact support for more information.';
          return error(res, 401, message, [], 'UNAUTHORIZED');
        }

        // Verify password
        const isPasswordValid = await provider.comparePassword(password);
        if (!isPasswordValid) {
          return error(res, 401, 'Invalid email or password', [], 'UNAUTHORIZED');
        }

        // Generate token (use provider._id but mark as provider role)
        const token = generateToken(provider._id);

        // Return provider data (without password) with clean structure
        const providerResponse = {
          _id: provider._id,
          // Personal info
          firstName: provider.firstName,
          lastName: provider.lastName,
          email: provider.email,
          phone: provider.phone,
          age: provider.age,
          profileImage: provider.profileImage,
          // Account info
          role: provider.role,
          isVerified: provider.isVerified,
          isActive: provider.isActive,
          rating: provider.rating,
          // Provider-specific fields
          experienceYears: provider.experienceYears,
          languages: provider.languages,
          hourlyRate: provider.hourlyRate,
          services: provider.services,
          location: provider.location,
          totalBookings: provider.totalBookings,
          completedBookings: provider.completedBookings,
          // Addresses
          addresses: provider.addresses,
          // Metadata
          createdAt: provider.createdAt
        };

        return ok(res, { token, user: providerResponse }, 'Login successful');
      }
    }

    // If we found a user in the users collection
    if (user) {
      // Check if user is active
      if (!user.isActive) {
        const message = user.deactivationReason 
          ? `Your account has been deactivated by an administrator. Reason: ${user.deactivationReason}`
          : 'Your account has been deactivated by an administrator. Please contact support for more information.';
        return error(res, 401, message, [], 'UNAUTHORIZED');
      }

      // Verify password
      const isPasswordValid = await user.comparePassword(password);
      if (!isPasswordValid) {
        return error(res, 401, 'Invalid email or password', [], 'UNAUTHORIZED');
      }

      // Generate token
      const token = generateToken(user._id);

      // Return user data (without password) with clean structure
      const userResponse = {
        _id: user._id,
        // Personal info
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        phone: user.phone,
        age: user.age,
        profileImage: user.profileImage,
        // Account info
        role: user.role,
        isVerified: user.isVerified,
        isActive: user.isActive,
        rating: user.rating,
        // Addresses
        addresses: user.addresses,
        // Metadata
        createdAt: user.createdAt
      };

      return ok(res, { token, user: userResponse }, 'Login successful');
    }

    // If we reach here, no user or provider was found
    return error(res, 401, 'Invalid email or password', [], 'UNAUTHORIZED');
});

// Validate token
const validateToken = asyncHandler(async (req, res) => {
    // User is already verified by auth middleware
    const user = req.user;

    // Check if this is a provider (from providers collection) or regular user
    if (user.role === 'provider' && user.experienceYears !== undefined) {
      // This is a provider from the providers collection
      return ok(res, {
        valid: true,
        user: {
          _id: user._id,
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          phone: user.phone,
          role: user.role,
          profileImage: user.profileImage,
          age: user.age,
          isVerified: user.isVerified,
          isActive: user.isActive,
          rating: user.rating,
          // Provider-specific fields
          experienceYears: user.experienceYears,
          languages: user.languages,
          hourlyRate: user.hourlyRate,
          services: user.services,
          location: user.location,
          totalBookings: user.totalBookings,
          completedBookings: user.completedBookings,
          // Addresses
          addresses: user.addresses,
          createdAt: user.createdAt
        }
      }, 'Token valid');
    } else {
      // This is a regular user from the users collection
      return ok(res, {
        valid: true,
        user: {
          _id: user._id,
          firstName: user.firstName,
          lastName: user.lastName,
          email: user.email,
          phone: user.phone,
          role: user.role,
          profileImage: user.profileImage,
          address: user.address,
          addresses: user.addresses,
          age: user.age,
          isVerified: user.isVerified,
          isActive: user.isActive,
          rating: user.rating,
          createdAt: user.createdAt
        }
      }, 'Token valid');
    }
});

// Logout user (client-side token removal)
const logout = asyncHandler(async (req, res) => {
    // In a stateless JWT system, logout is handled client-side
    // You could implement a blacklist here if needed
  return ok(res, {}, 'Logout successful');
});

// Get current user profile
const getProfile = asyncHandler(async (req, res) => {
    const user = req.user;

    // Check if this is a provider (from providers collection) or regular user
    if (user.role === 'provider' && user.experienceYears !== undefined) {
      // This is a provider from the providers collection
      const providerResponse = {
        _id: user._id,
        // Personal info
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        pendingEmail: user.pendingEmail,
        phone: user.phone,
        age: user.age,
        profileImage: user.profileImage,
        // Account info
        role: user.role,
        isVerified: user.isVerified,
        isActive: user.isActive,
        rating: user.rating,
        // Provider-specific fields
        experienceYears: user.experienceYears,
        languages: user.languages,
        hourlyRate: user.hourlyRate,
        services: user.services,
        location: user.location,
        totalBookings: user.totalBookings,
        completedBookings: user.completedBookings,
        // Addresses
        addresses: user.addresses,
        // Metadata
        createdAt: user.createdAt
      };
      return ok(res, providerResponse, 'Profile fetched');
    } else {
      // This is a regular user from the users collection
      const userResponse = {
        _id: user._id,
        // Personal info
        firstName: user.firstName,
        lastName: user.lastName,
        email: user.email,
        pendingEmail: user.pendingEmail,
        phone: user.phone,
        age: user.age,
        profileImage: user.profileImage,
        // Account info
        role: user.role,
        isVerified: user.isVerified,
        isActive: user.isActive,
        rating: user.rating,
        // Addresses
        addresses: user.addresses,
        // Metadata
        createdAt: user.createdAt
      };
      return ok(res, userResponse, 'Profile fetched');
    }
});

// Delete account (user can delete their own account)
const deleteAccount = asyncHandler(async (req, res) => {
  const userId = req.user._id;

  try {
    // Find the user
    const user = await User.findById(userId);
    if (!user) {
      return error(res, 404, 'User not found', [], 'NOT_FOUND');
    }

    // Delete the user
    await User.findByIdAndDelete(userId);

    // Return success response
    return ok(res, {}, 'Account deleted successfully');
  } catch (error) {
    console.error('Error deleting account:', error);
    return error(res, 500, 'Failed to delete account', [], 'INTERNAL_ERROR');
  }
});

module.exports = {
  register,
  login,
  validateToken,
  logout,
  getProfile,
  // Change password without auth by verifying email + current password
  changePasswordDirect: asyncHandler(async (req, res) => {
    const { email, currentPassword, newPassword } = req.body;
    if (!email || !currentPassword || !newPassword) {
      return error(res, 400, 'Email, currentPassword and newPassword are required', [], 'VALIDATION_ERROR');
    }

    const user = await User.findOne({ email: (email || '').toLowerCase() });
    // Use a generic error to avoid hinting which field was wrong
    if (!user) return error(res, 401, 'Invalid email or password', [], 'UNAUTHORIZED');

    const valid = await user.comparePassword(currentPassword);
    if (!valid) return error(res, 401, 'Invalid email or password', [], 'UNAUTHORIZED');

    user.password = newPassword; // will be hashed by pre-save hook
    await user.save();

    return ok(res, {}, 'Password changed successfully');
  }),
  // Forgot password: issue reset token and email it
  forgotPassword: asyncHandler(async (req, res) => {
    const { email } = req.body;
    if (!email) return error(res, 400, 'Email is required');
    const user = await User.findOne({ email: email.toLowerCase() });
    // Do not reveal whether the email exists
    if (!user) return ok(res, {}, 'If the email exists, a reset link has been sent');
    const rawToken = require('crypto').randomBytes(32).toString('hex');
    const crypto = require('crypto');
    // Store only hashed token in DB
    user.passwordResetTokenHash = crypto.createHash('sha256').update(rawToken).digest('hex');
    // Keep legacy field null for new requests
    user.passwordResetToken = null;
    user.passwordResetExpires = new Date(Date.now() + 60 * 60 * 1000); // 1h
    await user.save();
    const resetUrl = `${process.env.APP_BASE_URL || 'http://localhost:3000'}/reset-password?token=${rawToken}`;
    try {
      await sendEmail({
        to: user.email,
        subject: 'Reset your PalHands password',
        text: `Use this token to reset your password: ${rawToken}. Or open ${resetUrl}`,
        html: `<p>Use this token to reset your password:</p><p><b>${rawToken}</b></p><p>Or open <a href="${resetUrl}">${resetUrl}</a></p>`
      });
    } catch (e) {
      // Never leak SMTP credentials/transport issues to the client
      console.error('[FORGOT_PASSWORD] Email send failed:', e?.message || e);
      // As a dev fallback, log the reset link so QA can proceed
      console.log('[FORGOT_PASSWORD][DEV] Reset URL:', resetUrl);
      console.log('[FORGOT_PASSWORD][DEV] Token:', rawToken);
    }
    return ok(res, {}, 'If the email exists, a reset link has been sent');
  }),
  // Reset password with token
  resetPassword: asyncHandler(async (req, res) => {
    const { token, newPassword } = req.body;
    if (!token || !newPassword) return error(res, 400, 'Token and newPassword are required');
    const crypto = require('crypto');
    const tokenHash = crypto.createHash('sha256').update(token).digest('hex');
    // Support both new hashed storage and legacy plain storage during transition
    const user = await User.findOne({
      $and: [
        { passwordResetExpires: { $gt: new Date() } },
        { $or: [
          { passwordResetTokenHash: tokenHash },
          { passwordResetToken: token }
        ]}
      ]
    });
    if (!user) return error(res, 400, 'Invalid or expired token');
    user.password = newPassword;
    user.passwordResetToken = null;
    user.passwordResetTokenHash = null;
    user.passwordResetExpires = null;
    await user.save();
    return ok(res, {}, 'Password has been reset');
  }),
  // Issue a verification token (dev/simple flow)
  requestVerification: asyncHandler(async (req, res) => {
    if (process.env.ENABLE_EMAIL_VERIFICATION !== 'true') {
      return error(res, 400, 'Email verification is disabled');
    }
    const user = await User.findById(req.user._id);
    if (!user) return error(res, 404, 'User not found');
    if (user.isVerified) return ok(res, {}, 'Already verified');
    user.emailVerificationToken = require('crypto').randomBytes(20).toString('hex');
    user.emailVerificationExpires = new Date(Date.now() + 24 * 60 * 60 * 1000);
    await user.save();
    // Send verification email (dev-friendly; falls back to console log when SMTP missing)
    try {
      // Use backend landing page that requires explicit click; safer vs email scanners
      const verifyUrl = `${API_BASE}/auth/verify/start?token=${user.emailVerificationToken}&redirect=%2Fuser`;
      await sendEmail({
        to: user.email,
        subject: 'Verify your PalHands account',
        text: `Click to verify your account: ${verifyUrl}`,
        html: `<p>To verify your account, click the button below:</p>
               <p><a href="${verifyUrl}" style="background:#CE1126;color:#fff;padding:10px 14px;border-radius:8px;text-decoration:none;display:inline-block">Verify my email</a></p>
               <p>If the button doesn't work, copy and paste this link into your browser:<br/><a href="${verifyUrl}">${verifyUrl}</a></p>`
      });
    } catch (e) {
      console.log('[VERIFY_EMAIL][DEV] Token:', user.emailVerificationToken);
    }
    return ok(res, {}, 'Verification email sent');
  }),
  // Verify email with token
  verifyEmail: asyncHandler(async (req, res) => {
    if (process.env.ENABLE_EMAIL_VERIFICATION !== 'true') {
      return error(res, 400, 'Email verification is disabled');
    }
    const token = req.body.token || req.query.token;
    if (!token) return error(res, 400, 'Missing token');
    const user = await User.findOne({
      emailVerificationToken: token,
      emailVerificationExpires: { $gt: new Date() }
    });
    if (!user) return error(res, 400, 'Invalid or expired token');
    user.isVerified = true;
    user.emailVerificationToken = null;
    user.emailVerificationExpires = null;
    await user.save();
    return ok(res, {}, 'Email verified');
  }),
  // GET landing page that requires real user click to complete email verification
  verifyEmailStartPage: asyncHandler(async (req, res) => {
    if (process.env.ENABLE_EMAIL_VERIFICATION !== 'true') {
      return error(res, 400, 'Email verification is disabled');
    }
  const { token, redirect = '/user' } = req.query || {};
    if (!token) return error(res, 400, 'Missing token');
    // Do not verify here; render a page that requires an explicit click to POST the token
    res.set('Content-Type', 'text/html; charset=utf-8');
    return res.send(renderActionHtml({
      title: 'Verify your PalHands email',
      heading: 'Confirm email verification',
      buttonText: 'Verify my email',
      actionPath: '/auth/verify',
      token,
  successText: 'Your email is now verified. Redirecting…',
  redirectPath: redirect
    }));
  }),
  // Confirm email change via emailChangeToken; moves pendingEmail -> email
  confirmEmailChange: asyncHandler(async (req, res) => {
    if (process.env.ENABLE_EMAIL_VERIFICATION !== 'true') {
      return error(res, 400, 'Email verification is disabled');
    }
    const token = req.body.token || req.query.token;
    if (!token) return error(res, 400, 'Missing token');
    const user = await User.findOne({
      emailChangeToken: token,
      emailChangeExpires: { $gt: new Date() },
    });
    if (!user || !user.pendingEmail) return error(res, 400, 'Invalid or expired token');
    // Ensure the pending email is still unique at application time
    const nextEmail = user.pendingEmail.toLowerCase();
    const conflict = await User.findOne({ _id: { $ne: user._id }, $or: [ { email: nextEmail }, { pendingEmail: nextEmail } ] });
    if (conflict) return error(res, 400, 'Email already registered', [], 'CONFLICT');
    user.email = nextEmail;
    user.pendingEmail = null;
    user.emailChangeToken = null;
    user.emailChangeExpires = null;
    await user.save();
    return ok(res, {}, 'Email updated');
  }),
  // GET landing page for email change confirmation (requires user click)
  confirmEmailChangeStartPage: asyncHandler(async (req, res) => {
    if (process.env.ENABLE_EMAIL_VERIFICATION !== 'true') {
      return error(res, 400, 'Email verification is disabled');
    }
  const { token, redirect = '/user' } = req.query || {};
    if (!token) return error(res, 400, 'Missing token');
    res.set('Content-Type', 'text/html; charset=utf-8');
    return res.send(renderActionHtml({
      title: 'Confirm new PalHands email',
      heading: 'Confirm email change',
      buttonText: 'Confirm my new email',
      actionPath: '/auth/confirm-email-change',
      token,
  successText: 'Your email has been updated. Redirecting…',
  redirectPath: redirect
    }));
  }),
  deleteAccount
}; 