/**
 * Raw Body Middleware
 * Captures raw request body for webhook signature verification
 */
const rawBodyMiddleware = (req, res, next) => {
  let data = '';
  
  req.setEncoding('utf8');
  
  req.on('data', (chunk) => {
    data += chunk;
  });
  
  req.on('end', () => {
    req.rawBody = data;
    
    // Parse JSON if content-type is application/json
    if (req.headers['content-type'] && req.headers['content-type'].includes('application/json')) {
      try {
        req.body = JSON.parse(data);
      } catch (error) {
        console.error('Failed to parse JSON body:', error);
        req.body = {};
      }
    } else {
      req.body = data;
    }
    
    next();
  });
  
  req.on('error', (error) => {
    console.error('Error reading request body:', error);
    next(error);
  });
};

module.exports = rawBodyMiddleware;
