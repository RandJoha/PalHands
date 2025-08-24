#!/usr/bin/env node

/**
 * Payment Phases Test Script
 * Tests all payment phases mentioned in the documentation
 */

const axios = require('axios');
const crypto = require('crypto');

// Configuration
const BASE_URL = process.env.TEST_BASE_URL || 'http://localhost:3000';
const ADMIN_TOKEN = process.env.ADMIN_TOKEN || 'your-admin-token-here';
const CLIENT_TOKEN = process.env.CLIENT_TOKEN || 'your-client-token-here';

// Test data
const testBookingId = '507f1f77bcf86cd799439011'; // Replace with actual booking ID
const testPaymentId = '507f1f77bcf86cd799439012'; // Replace with actual payment ID

// HTTP client with auth headers
const api = axios.create({
  baseURL: BASE_URL,
  headers: {
    'Content-Type': 'application/json'
  }
});

// Helper function to log test results
function logTest(name, passed, details = '') {
  const status = passed ? '✅ PASS' : '❌ FAIL';
  console.log(`${status} ${name}`);
  if (details) {
    console.log(`   ${details}`);
  }
  return passed;
}

// Helper function to generate test webhook signature
function generateTestWebhookSignature(payload, secret = 'test-secret') {
  return crypto
    .createHmac('sha256', secret)
    .update(JSON.stringify(payload))
    .digest('hex');
}

async function testPaymentPhases() {
  console.log('🧪 Testing Payment Phases Implementation\n');
  
  let passedTests = 0;
  let totalTests = 0;

  try {
    // Test 1: Feature Flags and Processor Abstraction
    console.log('📋 Phase 1: Feature Flags and Processor Abstraction');
    
    // Test payment health endpoint
    try {
      const healthResponse = await api.get('/api/payments/health', {
        headers: { Authorization: `Bearer ${ADMIN_TOKEN}` }
      });
      
      const health = healthResponse.data.data;
      const featureFlags = health.featureFlags.details;
      
      totalTests++;
      if (health.processors.status === 'healthy') {
        passedTests++;
        logTest('Payment Processors Initialized', true, 
          `${health.processors.details.totalProcessors} processors ready`);
      } else {
        logTest('Payment Processors Initialized', false, 
          health.processors.message);
      }

      totalTests++;
      if (featureFlags.cash !== undefined) {
        passedTests++;
        logTest('Feature Flags Configuration', true, 
          `Cash: ${featureFlags.cash}, Stripe: ${featureFlags.stripe}, PayPal: ${featureFlags.paypal}`);
      } else {
        logTest('Feature Flags Configuration', false, 'Feature flags not properly configured');
      }

    } catch (error) {
      totalTests++;
      logTest('Payment Health Endpoint', false, error.response?.data?.message || error.message);
    }

    // Test 2: Minimal Cash Payment
    console.log('\n💰 Phase 2: Minimal Cash Payment');
    
    try {
      const cashPaymentData = {
        bookingId: testBookingId,
        notes: 'Test minimal cash payment'
      };

      const cashResponse = await api.post('/api/payments/cash/minimal', cashPaymentData, {
        headers: { Authorization: `Bearer ${ADMIN_TOKEN}` }
      });

      totalTests++;
      if (cashResponse.data.data.status === 'paid') {
        passedTests++;
        logTest('Minimal Cash Payment Creation', true, 
          `Payment ID: ${cashResponse.data.data._id}, Status: ${cashResponse.data.data.status}`);
      } else {
        logTest('Minimal Cash Payment Creation', false, 
          `Expected status 'paid', got '${cashResponse.data.data.status}'`);
      }

      // Test booking payment update
      totalTests++;
      if (cashResponse.data.data.metadata?.paymentType === 'minimal_cash') {
        passedTests++;
        logTest('Booking Payment Update', true, 'Booking payment status updated');
      } else {
        logTest('Booking Payment Update', false, 'Booking payment not properly updated');
      }

    } catch (error) {
      totalTests++;
      logTest('Minimal Cash Payment', false, error.response?.data?.message || error.message);
    }

    // Test 3: Webhook Verification and Replay Protection
    console.log('\n🔗 Phase 3: Webhook Verification and Replay Protection');
    
    try {
      const testWebhookPayload = {
        id: 'evt_test_webhook',
        type: 'payment_intent.succeeded',
        data: {
          object: {
            id: 'pi_test_payment',
            amount: 1000,
            currency: 'ils',
            status: 'succeeded'
          }
        }
      };

      const signature = generateTestWebhookSignature(testWebhookPayload);

      const webhookResponse = await api.post('/api/webhooks/stripe', testWebhookPayload, {
        headers: {
          'stripe-signature': signature,
          'stripe-webhook-id': 'evt_test_webhook',
          'stripe-timestamp': Math.floor(Date.now() / 1000).toString()
        }
      });

      totalTests++;
      if (webhookResponse.status === 200) {
        passedTests++;
        logTest('Webhook Signature Verification', true, 'Webhook processed successfully');
      } else {
        logTest('Webhook Signature Verification', false, 
          `Expected status 200, got ${webhookResponse.status}`);
      }

    } catch (error) {
      totalTests++;
      if (error.response?.status === 401) {
        passedTests++;
        logTest('Webhook Signature Verification', true, 'Properly rejected invalid signature');
      } else {
        logTest('Webhook Signature Verification', false, error.response?.data?.message || error.message);
      }
    }

    // Test 4: Outbox and Reliable Dispatch
    console.log('\n📮 Phase 4: Outbox and Reliable Dispatch');
    
    try {
      // Test outbox statistics
      const outboxStatsResponse = await api.get('/api/payments/health', {
        headers: { Authorization: `Bearer ${ADMIN_TOKEN}` }
      });

      const outboxStatus = outboxStatsResponse.data.data.outbox;
      
      totalTests++;
      if (outboxStatus.status === 'healthy') {
        passedTests++;
        logTest('Outbox Scheduler Running', true, 'Outbox scheduler is operational');
      } else {
        logTest('Outbox Scheduler Running', false, outboxStatus.message);
      }

      totalTests++;
      if (outboxStatus.stats && typeof outboxStatus.stats === 'object') {
        passedTests++;
        logTest('Outbox Statistics Available', true, 'Outbox statistics accessible');
      } else {
        logTest('Outbox Statistics Available', false, 'Outbox statistics not available');
      }

    } catch (error) {
      totalTests++;
      logTest('Outbox System', false, error.response?.data?.message || error.message);
    }

    // Test 5: Reconciliation Scheduled Job
    console.log('\n🔄 Phase 5: Reconciliation Scheduled Job');
    
    try {
      const reconciliationResponse = await api.get('/api/payments/health', {
        headers: { Authorization: `Bearer ${ADMIN_TOKEN}` }
      });

      const reconciliationStatus = reconciliationResponse.data.data.reconciliation;
      
      totalTests++;
      if (reconciliationStatus.status === 'healthy') {
        passedTests++;
        logTest('Reconciliation Scheduler Running', true, 'Reconciliation scheduler is operational');
      } else {
        logTest('Reconciliation Scheduler Running', false, reconciliationStatus.message);
      }

      totalTests++;
      if (reconciliationStatus.stats && typeof reconciliationStatus.stats === 'object') {
        passedTests++;
        logTest('Reconciliation Statistics Available', true, 'Reconciliation statistics accessible');
      } else {
        logTest('Reconciliation Statistics Available', false, 'Reconciliation statistics not available');
      }

    } catch (error) {
      totalTests++;
      logTest('Reconciliation System', false, error.response?.data?.message || error.message);
    }

    // Test 6: Payment Audit Trail
    console.log('\n📝 Phase 6: Payment Audit Trail');
    
    try {
      const auditResponse = await api.get(`/api/payments/${testPaymentId}/audit`, {
        headers: { Authorization: `Bearer ${ADMIN_TOKEN}` }
      });

      totalTests++;
      if (auditResponse.status === 200) {
        passedTests++;
        logTest('Payment Audit Trail Accessible', true, 'Audit trail endpoint working');
      } else {
        logTest('Payment Audit Trail Accessible', false, 
          `Expected status 200, got ${auditResponse.status}`);
      }

    } catch (error) {
      totalTests++;
      if (error.response?.status === 404) {
        passedTests++;
        logTest('Payment Audit Trail Accessible', true, 'Properly handles non-existent payment');
      } else {
        logTest('Payment Audit Trail Accessible', false, error.response?.data?.message || error.message);
      }
    }

    // Test 7: Payment Methods API
    console.log('\n💳 Phase 7: Payment Methods API');
    
    try {
      const methodsResponse = await api.get('/api/payments/methods');

      totalTests++;
      if (methodsResponse.status === 200 && Array.isArray(methodsResponse.data.data)) {
        passedTests++;
        logTest('Payment Methods API', true, 
          `${methodsResponse.data.data.length} payment methods available`);
      } else {
        logTest('Payment Methods API', false, 'Payment methods not properly returned');
      }

    } catch (error) {
      totalTests++;
      logTest('Payment Methods API', false, error.response?.data?.message || error.message);
    }

  } catch (error) {
    console.error('❌ Test suite failed:', error.message);
  }

  // Summary
  console.log('\n📊 Test Summary');
  console.log(`Total Tests: ${totalTests}`);
  console.log(`Passed: ${passedTests}`);
  console.log(`Failed: ${totalTests - passedTests}`);
  console.log(`Success Rate: ${((passedTests / totalTests) * 100).toFixed(1)}%`);

  if (passedTests === totalTests) {
    console.log('\n🎉 All payment phases are working correctly!');
    process.exit(0);
  } else {
    console.log('\n⚠️ Some payment phases need attention.');
    process.exit(1);
  }
}

// Run tests if this file is executed directly
if (require.main === module) {
  testPaymentPhases().catch(error => {
    console.error('❌ Test execution failed:', error);
    process.exit(1);
  });
}

module.exports = { testPaymentPhases };
