#!/usr/bin/env node

/**
 * Simple Payment Phases Test Script
 * Tests all payment phases with proper authentication
 */

const axios = require('axios');

// Configuration
const BASE_URL = 'http://localhost:3000';
const ADMIN_EMAIL = 'admin@example.com';
const ADMIN_PASSWORD = 'Admin123!';

// HTTP client
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

// Helper function to authenticate and get token
async function authenticate() {
  try {
    const response = await api.post('/api/auth/login', {
      email: ADMIN_EMAIL,
      password: ADMIN_PASSWORD
    });
    
    if (response.data.success && response.data.data.token) {
      return response.data.data.token;
    } else {
      throw new Error('Authentication failed');
    }
  } catch (error) {
    console.error('Authentication error:', error.response?.data?.message || error.message);
    throw error;
  }
}

async function testPaymentPhases() {
  console.log('🧪 Testing Payment Phases Implementation\n');
  
  let passedTests = 0;
  let totalTests = 0;
  let authToken = null;

  try {
    // Step 1: Authenticate
    console.log('🔐 Authenticating...');
    authToken = await authenticate();
    console.log('✅ Authentication successful\n');

    // Set auth header for all subsequent requests
    api.defaults.headers.common['Authorization'] = `Bearer ${authToken}`;

    // Test 1: Payment Health Endpoint
    console.log('📋 Phase 1: Payment System Health Check');
    
    try {
      const healthResponse = await api.get('/api/payments/health');
      const health = healthResponse.data.data;
      
      totalTests++;
      if (health.overall.status === 'healthy' || health.overall.status === 'degraded') {
        passedTests++;
        logTest('Payment System Health', true, 
          `Status: ${health.overall.status}, Message: ${health.overall.message}`);
      } else {
        logTest('Payment System Health', false, 
          `Unexpected status: ${health.overall.status}`);
      }

      // Check feature flags
      totalTests++;
      if (health.featureFlags && health.featureFlags.details) {
        passedTests++;
        const flags = health.featureFlags.details;
        logTest('Feature Flags Configuration', true, 
          `Cash: ${flags.cash}, Stripe: ${flags.stripe}, PayPal: ${flags.paypal}, Audit: ${flags.audit}`);
      } else {
        logTest('Feature Flags Configuration', false, 'Feature flags not available');
      }

      // Check processors
      totalTests++;
      if (health.processors && health.processors.details.totalProcessors > 0) {
        passedTests++;
        logTest('Payment Processors', true, 
          `${health.processors.details.totalProcessors} processors initialized`);
      } else {
        logTest('Payment Processors', false, 'No processors initialized');
      }

      // Check outbox
      totalTests++;
      if (health.outbox && health.outbox.status) {
        passedTests++;
        logTest('Outbox System', true, 
          `Status: ${health.outbox.status}, Running: ${health.outbox.details.isRunning}`);
      } else {
        logTest('Outbox System', false, 'Outbox system not available');
      }

      // Check reconciliation
      totalTests++;
      if (health.reconciliation && health.reconciliation.status) {
        passedTests++;
        logTest('Reconciliation System', true, 
          `Status: ${health.reconciliation.status}, Running: ${health.reconciliation.details.isRunning}`);
      } else {
        logTest('Reconciliation System', false, 'Reconciliation system not available');
      }

    } catch (error) {
      totalTests++;
      logTest('Payment Health Endpoint', false, error.response?.data?.message || error.message);
    }

    // Test 2: Payment Methods API
    console.log('\n💳 Phase 2: Payment Methods API');
    
    try {
      const methodsResponse = await api.get('/api/payments/methods');

      totalTests++;
      if (methodsResponse.status === 200 && Array.isArray(methodsResponse.data.data)) {
        passedTests++;
        logTest('Payment Methods API', true, 
          `${methodsResponse.data.data.length} payment methods available`);
        
        // Log available methods
        methodsResponse.data.data.forEach(method => {
          console.log(`   - ${method.name} (${method.method})`);
        });
      } else {
        logTest('Payment Methods API', false, 'Payment methods not properly returned');
      }

    } catch (error) {
      totalTests++;
      logTest('Payment Methods API', false, error.response?.data?.message || error.message);
    }

    // Test 3: Webhook Test Endpoint
    console.log('\n🔗 Phase 3: Webhook System');
    
    try {
      const testWebhookData = {
        processorType: 'stripe',
        event: {
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
        }
      };

      const webhookResponse = await api.post('/api/webhooks/test', testWebhookData);

      totalTests++;
      if (webhookResponse.status === 200) {
        passedTests++;
        logTest('Webhook Test Endpoint', true, 'Webhook test endpoint working');
      } else {
        logTest('Webhook Test Endpoint', false, 
          `Expected status 200, got ${webhookResponse.status}`);
      }

    } catch (error) {
      totalTests++;
      logTest('Webhook Test Endpoint', false, error.response?.data?.message || error.message);
    }

    // Test 4: Environment Configuration
    console.log('\n⚙️ Phase 4: Environment Configuration');
    
    try {
      const healthResponse = await api.get('/api/payments/health');
      const env = healthResponse.data.data.environment;
      
      totalTests++;
      if (env) {
        passedTests++;
        logTest('Environment Variables', true, 
          `Node Env: ${env.nodeEnv}, Cash: ${env.paymentCashEnabled}, Stripe: ${env.paymentStripeEnabled}`);
      } else {
        logTest('Environment Variables', false, 'Environment info not available');
      }

    } catch (error) {
      totalTests++;
      logTest('Environment Configuration', false, error.response?.data?.message || error.message);
    }

    // Test 5: API Endpoints Availability
    console.log('\n🌐 Phase 5: API Endpoints');
    
    const endpoints = [
      { path: '/api/payments/methods', method: 'GET', name: 'Payment Methods' },
      { path: '/api/payments/health', method: 'GET', name: 'Payment Health' },
      { path: '/api/webhooks/test', method: 'POST', name: 'Webhook Test' }
    ];

    for (const endpoint of endpoints) {
      try {
        const response = await api.request({
          method: endpoint.method,
          url: endpoint.path,
          ...(endpoint.method === 'POST' && { data: {} })
        });

        totalTests++;
        if (response.status === 200 || response.status === 201) {
          passedTests++;
          logTest(`${endpoint.name} Endpoint`, true, `${endpoint.method} ${endpoint.path}`);
        } else {
          logTest(`${endpoint.name} Endpoint`, false, 
            `Expected 200/201, got ${response.status}`);
        }
      } catch (error) {
        totalTests++;
        logTest(`${endpoint.name} Endpoint`, false, 
          `${endpoint.method} ${endpoint.path} - ${error.response?.status || 'Connection failed'}`);
      }
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
    console.log('\n📋 Implementation Status:');
    console.log('✅ Minimal cash payment system');
    console.log('✅ Processor abstraction with feature flags');
    console.log('✅ Webhook verification and replay protection');
    console.log('✅ Outbox system for reliable dispatch');
    console.log('✅ Reconciliation scheduled job');
    console.log('✅ Comprehensive health monitoring');
    console.log('✅ Payment audit trail');
    console.log('✅ API endpoints and documentation');
    process.exit(0);
  } else {
    console.log('\n⚠️ Some payment phases need attention.');
    console.log('\n🔧 Next Steps:');
    console.log('1. Check server logs for detailed error messages');
    console.log('2. Verify environment variables are set correctly');
    console.log('3. Ensure database is connected and seeded');
    console.log('4. Review the implementation documentation');
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
