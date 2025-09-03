const http = require('http');

console.log('🔍 Testing backend connection...');

const options = {
  hostname: 'localhost',
  port: 3000,
  path: '/api/chat/test',
  method: 'GET'
};

const req = http.request(options, (res) => {
  console.log(`✅ Backend is running! Status: ${res.statusCode}`);
  
  let data = '';
  res.on('data', (chunk) => {
    data += chunk;
  });
  
  res.on('end', () => {
    try {
      const response = JSON.parse(data);
      console.log('📡 Response:', response);
    } catch (e) {
      console.log('📡 Raw response:', data);
    }
  });
});

req.on('error', (e) => {
  console.log(`❌ Backend connection failed: ${e.message}`);
});

req.end();
