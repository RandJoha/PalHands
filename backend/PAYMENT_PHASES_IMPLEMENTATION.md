# Payment Phases Implementation

This document describes the implementation of all payment phases mentioned in the backend documentation.

## Overview

The payment system has been implemented with the following phases:

1. **Minimal Cash Payment** - Mark as paid, update booking.payment, audit
2. **Processor Abstraction** - Feature flags for Stripe/PayPal
3. **Webhook Verification** - Signature verification and replay protection
4. **Outbox System** - Reliable message dispatch with retries
5. **Reconciliation** - Scheduled job for financial reconciliation

## Phase 1: Minimal Cash Payment

### Implementation Details

- **Endpoint**: `POST /api/payments/cash/minimal`
- **Access**: Admin only
- **Purpose**: Create cash payments that are immediately marked as paid

### Features

- ✅ Immediate payment confirmation
- ✅ Booking payment status update
- ✅ Comprehensive audit trail
- ✅ Outbox integration for notifications
- ✅ Real-time updates

### Code Location

- Controller: `src/controllers/payments/index.js` - `createMinimalCashPayment()`
- Route: `src/routes/payments.js`
- Processor: `src/services/paymentProcessors/cashProcessor.js`

### Example Usage

```bash
curl -X POST http://localhost:3000/api/payments/cash/minimal \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "bookingId": "507f1f77bcf86cd799439011",
    "notes": "Cash payment received"
  }'
```

### Response

```json
{
  "success": true,
  "data": {
    "_id": "507f1f77bcf86cd799439012",
    "booking": "507f1f77bcf86cd799439011",
    "amount": 150,
    "currency": "ILS",
    "method": "cash",
    "status": "paid",
    "transactionId": "CASH_MIN_1640995200000_abc123",
    "metadata": {
      "paymentType": "minimal_cash",
      "createdBy": "admin_user_id",
      "notes": "Cash payment received",
      "immediateConfirmation": true,
      "requiresManualReconciliation": true
    }
  },
  "message": "Minimal cash payment created successfully"
}
```

## Phase 2: Processor Abstraction with Feature Flags

### Implementation Details

- **Location**: `src/services/paymentProcessors/processorManager.js`
- **Purpose**: Abstract payment processors behind feature flags

### Feature Flags

| Flag | Environment Variable | Default | Description |
|------|---------------------|---------|-------------|
| Cash | `PAYMENT_CASH_ENABLED` | `true` | Enable/disable cash payments |
| Stripe | `PAYMENT_STRIPE_ENABLED` | `false` | Enable/disable Stripe payments |
| PayPal | `PAYMENT_PAYPAL_ENABLED` | `false` | Enable/disable PayPal payments |
| Audit | `PAYMENT_AUDIT_ENABLED` | `true` | Enable/disable payment auditing |

### Configuration

```bash
# Enable all payment methods
PAYMENT_CASH_ENABLED=true
PAYMENT_STRIPE_ENABLED=true
PAYMENT_PAYPAL_ENABLED=true
PAYMENT_AUDIT_ENABLED=true

# Stripe configuration (if enabled)
STRIPE_SECRET_KEY=sk_test_your_key_here
STRIPE_PUBLISHABLE_KEY=pk_test_your_key_here
STRIPE_WEBHOOK_SECRET=whsec_your_webhook_secret

# PayPal configuration (if enabled)
PAYPAL_CLIENT_ID=your_paypal_client_id
PAYPAL_CLIENT_SECRET=your_paypal_client_secret
PAYPAL_WEBHOOK_SECRET=your_paypal_webhook_secret
```

### Health Check

```bash
curl -X GET http://localhost:3000/api/payments/health \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"
```

Response includes feature flag status and processor health.

## Phase 3: Webhook Verification and Replay Protection

### Implementation Details

- **Location**: `src/middleware/webhookAuth.js`
- **Purpose**: Secure webhook processing with signature verification

### Security Features

- ✅ HMAC signature verification
- ✅ Replay attack protection
- ✅ Timestamp validation
- ✅ Webhook ID tracking
- ✅ Comprehensive logging

### Supported Processors

- **Stripe**: `/api/webhooks/stripe`
- **PayPal**: `/api/webhooks/paypal` (when implemented)
- **Test**: `/api/webhooks/test` (admin only)

### Configuration

```bash
# Webhook security
WEBHOOK_MAX_AGE_MINUTES=5
WEBHOOK_REPLAY_PROTECTION_ENABLED=true

# Processor-specific webhook secrets
STRIPE_WEBHOOK_SECRET=whsec_your_stripe_webhook_secret
PAYPAL_WEBHOOK_SECRET=your_paypal_webhook_secret
```

### Example Webhook Processing

```javascript
// Stripe webhook
POST /api/webhooks/stripe
Headers:
  stripe-signature: t=1640995200,v1=abc123...
  stripe-webhook-id: evt_1234567890
  stripe-timestamp: 1640995200

Body:
{
  "id": "evt_1234567890",
  "type": "payment_intent.succeeded",
  "data": {
    "object": {
      "id": "pi_1234567890",
      "amount": 1000,
      "currency": "ils",
      "status": "succeeded"
    }
  }
}
```

## Phase 4: Outbox System for Reliable Dispatch

### Implementation Details

- **Location**: `src/services/outbox.js` and `src/services/outboxScheduler.js`
- **Purpose**: Ensure reliable message delivery with retry mechanisms

### Features

- ✅ Message persistence
- ✅ Automatic retries
- ✅ Dead letter queue
- ✅ Priority handling
- ✅ Cleanup of old messages

### Configuration

```bash
# Outbox settings
OUTBOX_PENDING_INTERVAL_MS=5000
OUTBOX_RETRY_INTERVAL_MS=30000
OUTBOX_CLEANUP_INTERVAL_MS=3600000
OUTBOX_BATCH_SIZE=50
OUTBOX_MAX_ATTEMPTS=3
OUTBOX_CLEANUP_DAYS=30
```

### Message Types

- `payment_webhook` - Payment processor webhooks
- `email_notification` - Email notifications
- `sms_notification` - SMS notifications
- `booking_update` - Booking status updates
- `payment_status_change` - Payment status notifications

### Example Usage

```javascript
// Add message to outbox
await OutboxService.addMessage({
  type: 'payment_status_change',
  payload: {
    paymentId: '507f1f77bcf86cd799439012',
    oldStatus: 'pending',
    newStatus: 'paid',
    notificationData: {
      booking: '507f1f77bcf86cd799439011',
      method: 'cash',
      amount: 150,
      currency: 'ILS'
    }
  },
  destination: 'payment_notifications',
  correlationId: '507f1f77bcf86cd799439012',
  priority: 'high'
});
```

## Phase 5: Reconciliation Scheduled Job

### Implementation Details

- **Location**: `src/services/reconciliation.js` and `src/services/reconciliationScheduler.js`
- **Purpose**: Financial reconciliation between internal records and payment processors

### Features

- ✅ Daily, weekly, and monthly reconciliation
- ✅ Discrepancy detection
- ✅ Variance calculation
- ✅ Comprehensive reporting
- ✅ Manual resolution support

### Configuration

```bash
# Reconciliation intervals
RECONCILIATION_DAILY_INTERVAL_MS=86400000
RECONCILIATION_WEEKLY_INTERVAL_MS=604800000
RECONCILIATION_MONTHLY_INTERVAL_MS=2592000000
RECONCILIATION_BATCH_SIZE=5
RECONCILIATION_MAX_RETRIES=3
RECONCILIATION_DISCREPANCY_THRESHOLD=0.01
```

### Reconciliation Types

1. **Daily Reconciliation**: Runs every 24 hours
2. **Weekly Reconciliation**: Runs every 7 days
3. **Monthly Reconciliation**: Runs every 30 days

### Discrepancy Detection

- Missing payments in processor
- Duplicate payments in processor
- Amount mismatches
- Status mismatches

### Example Reconciliation Report

```json
{
  "reconciliationId": "rec_1234567890",
  "period": "daily",
  "processorType": "all",
  "startDate": "2024-01-01T00:00:00.000Z",
  "endDate": "2024-01-02T00:00:00.000Z",
  "expectedAmount": 1500,
  "actualAmount": 1500,
  "expectedTransactions": 10,
  "actualTransactions": 10,
  "discrepancies": [],
  "variance": 0,
  "status": "completed"
}
```

## Testing

### Test Script

A comprehensive test script is available at `test-payment-phases.js` that verifies all payment phases.

```bash
# Run the test script
node test-payment-phases.js

# With custom configuration
TEST_BASE_URL=http://localhost:3000 \
ADMIN_TOKEN=your_admin_token \
CLIENT_TOKEN=your_client_token \
node test-payment-phases.js
```

### Test Coverage

The test script covers:

1. ✅ Feature flags and processor abstraction
2. ✅ Minimal cash payment creation
3. ✅ Webhook verification and replay protection
4. ✅ Outbox system functionality
5. ✅ Reconciliation scheduler
6. ✅ Payment audit trail
7. ✅ Payment methods API

## API Endpoints Summary

| Method | Endpoint | Description | Access |
|--------|----------|-------------|--------|
| GET | `/api/payments/health` | Payment system health check | Admin |
| GET | `/api/payments/methods` | Available payment methods | Public |
| POST | `/api/payments/cash/minimal` | Create minimal cash payment | Admin |
| POST | `/api/payments` | Create payment | Client, Admin |
| PUT | `/api/payments/:id/status` | Update payment status | Admin |
| POST | `/api/payments/:id/confirm` | Confirm payment | Client, Admin |
| POST | `/api/payments/:id/refund` | Refund payment | Admin |
| GET | `/api/payments/:id/audit` | Payment audit trail | Client, Provider, Admin |
| GET | `/api/payments/audit/booking/:bookingId` | Booking payment audit | Client, Provider, Admin |
| GET | `/api/payments/webhook/stats` | Webhook statistics | Admin |
| POST | `/api/webhooks/stripe` | Stripe webhook | Public |
| POST | `/api/webhooks/paypal` | PayPal webhook | Public |
| POST | `/api/webhooks/test` | Test webhook | Admin |

## Monitoring and Observability

### Health Checks

- Payment processor status
- Feature flag configuration
- Outbox scheduler status
- Reconciliation scheduler status
- Webhook processing statistics

### Logging

- Payment creation and updates
- Webhook processing
- Reconciliation runs
- Outbox message processing
- Error tracking

### Metrics

- Payment success/failure rates
- Webhook processing times
- Reconciliation discrepancies
- Outbox message delivery rates

## Security Considerations

1. **Authentication**: All sensitive endpoints require proper authentication
2. **Authorization**: Role-based access control for different operations
3. **Webhook Security**: HMAC signature verification and replay protection
4. **Audit Trail**: Comprehensive logging of all payment operations
5. **Feature Flags**: Safe rollout of new payment methods

## Deployment Notes

1. Ensure all environment variables are properly configured
2. Start the outbox and reconciliation schedulers
3. Configure webhook endpoints with payment processors
4. Set up monitoring and alerting
5. Test all payment flows before going live

## Troubleshooting

### Common Issues

1. **Payment processors not initializing**: Check feature flags and API keys
2. **Webhook failures**: Verify signature secrets and replay protection
3. **Outbox messages not processing**: Check scheduler status and database connectivity
4. **Reconciliation discrepancies**: Review processor integration and data consistency

### Debug Commands

```bash
# Check payment system health
curl -X GET http://localhost:3000/api/payments/health \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN"

# Test webhook processing
curl -X POST http://localhost:3000/api/webhooks/test \
  -H "Authorization: Bearer YOUR_ADMIN_TOKEN" \
  -H "Content-Type: application/json" \
  -d '{"processorType": "stripe", "event": {...}}'
```

## Future Enhancements

1. **PayPal Integration**: Complete PayPal processor implementation
2. **Advanced Analytics**: Enhanced payment analytics and reporting
3. **Multi-currency Support**: Better handling of multiple currencies
4. **Fraud Detection**: Integration with fraud detection services
5. **Mobile Payments**: Support for mobile payment methods
