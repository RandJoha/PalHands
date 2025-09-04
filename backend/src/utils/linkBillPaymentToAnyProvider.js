// Deprecated: Do not use.
// This helper has been superseded by syncProviderServices.js.
// Use instead:
//   node src/utils/syncProviderServices.js billPayment --ensure-one --enable-emergency
// This file remains only to avoid confusion if invoked; it performs no action.

console.warn('[deprecated] linkBillPaymentToAnyProvider.js is no longer used.');
console.warn('Use: node src/utils/syncProviderServices.js billPayment --ensure-one --enable-emergency');
process.exit(0);
