# Server-Side Verification Example

This document provides an example of how a server might implement verification of HMAC-SHA256 signed requests from clients. This is intended as a reference for backend developers who need to implement the server-side component of the request signing system.

## Node.js Example

```javascript
const express = require('express');
const crypto = require('crypto');
const app = express();

// Parse JSON request bodies
app.use(express.json());

// Mock database of device signing keys
const deviceSigningKeys = {
  'device-123': 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6',
  'device-456': 'p6o5n4m3l2k1j0i9h8g7f6e5d4c3b2a1',
  // In a real implementation, this would be stored in a secure database
};

// Middleware to verify signed requests
function verifySignature(req, res, next) {
  try {
    // Get headers
    const signature = req.headers['x-signature'];
    const timestamp = req.headers['x-timestamp'];
    const deviceId = req.headers['x-device-id'];
    
    // Check if all required headers are present
    if (!signature || !timestamp || !deviceId) {
      return res.status(401).json({ error: 'Missing authentication headers' });
    }
    
    // Get the device's signing key
    const signingKey = deviceSigningKeys[deviceId];
    if (!signingKey) {
      return res.status(401).json({ error: 'Unknown device' });
    }
    
    // Check timestamp freshness (prevent replay attacks)
    const requestTime = parseInt(timestamp, 10);
    const currentTime = Date.now();
    const fiveMinutes = 5 * 60 * 1000; // 5 minutes in milliseconds
    
    if (currentTime - requestTime > fiveMinutes) {
      return res.status(401).json({ error: 'Request expired' });
    }
    
    // Recreate the signature
    const path = req.path;
    const body = JSON.stringify(req.body) || '';
    
    // Use pipe delimiter between components for better security
    const payload = `${path}|${body}|${timestamp}`;
    
    const hmac = crypto.createHmac('sha256', signingKey);
    hmac.update(payload);
    const expectedSignature = hmac.digest('base64');
    
    // Compare signatures
    if (signature !== expectedSignature) {
      return res.status(401).json({ error: 'Invalid signature' });
    }
    
    // If we get here, the signature is valid
    next();
  } catch (error) {
    console.error('Signature verification error:', error);
    return res.status(500).json({ error: 'Internal server error' });
  }
}

// Apply the middleware to protected routes
app.use('/api/protected', verifySignature);

// Example protected endpoint
app.get('/api/protected/resource', (req, res) => {
  res.json({ message: 'This is a protected resource', data: 'Sensitive information' });
});

// Device registration endpoint (would normally require other authentication)
app.post('/api/register-device', (req, res) => {
  const { deviceId } = req.body;
  
  if (!deviceId) {
    return res.status(400).json({ error: 'Device ID is required' });
  }
  
  // Generate a new signing key for the device
  const signingKey = crypto.randomBytes(32).toString('hex');
  
  // Store it in our database
  deviceSigningKeys[deviceId] = signingKey;
  
  // Return the key to the client (only done during secure registration)
  res.json({ signingKey });
});

app.listen(3000, () => {
  console.log('Server running on port 3000');
});
```

## Python (Flask) Example

```python
from flask import Flask, request, jsonify
import hmac
import hashlib
import time
import os

app = Flask(__name__)

# Mock database of device signing keys
device_signing_keys = {
    'device-123': 'a1b2c3d4e5f6g7h8i9j0k1l2m3n4o5p6',
    'device-456': 'p6o5n4m3l2k1j0i9h8g7f6e5d4c3b2a1',
    # In a real implementation, this would be stored in a secure database
}

def verify_signature():
    try:
        # Get headers
        signature = request.headers.get('X-Signature')
        timestamp = request.headers.get('X-Timestamp')
        device_id = request.headers.get('X-Device-Id')
        
        # Check if all required headers are present
        if not signature or not timestamp or not device_id:
            return jsonify({'error': 'Missing authentication headers'}), 401
        
        # Get the device's signing key
        signing_key = device_signing_keys.get(device_id)
        if not signing_key:
            return jsonify({'error': 'Unknown device'}), 401
        
        # Check timestamp freshness (prevent replay attacks)
        request_time = int(timestamp)
        current_time = int(time.time() * 1000)  # Current time in milliseconds
        five_minutes = 5 * 60 * 1000  # 5 minutes in milliseconds
        
        if current_time - request_time > five_minutes:
            return jsonify({'error': 'Request expired'}), 401
        
        # Recreate the signature
        path = request.path
        body = request.get_data(as_text=True) or ''
        
        # Use pipe delimiter between components for better security
        payload = f"{path}|{body}|{timestamp}"
        
        # Create HMAC-SHA256 signature and encode as base64
        digest = hmac.new(
            signing_key.encode('utf-8'),
            payload.encode('utf-8'),
            hashlib.sha256
        ).digest()
        
        # Convert to base64 to match client implementation
        import base64
        expected_signature = base64.b64encode(digest).decode('utf-8')
        
        # Compare signatures
        if signature != expected_signature:
            return jsonify({'error': 'Invalid signature'}), 401
        
        # If we get here, the signature is valid
        return None
    except Exception as e:
        print(f'Signature verification error: {e}')
        return jsonify({'error': 'Internal server error'}), 500

# Example protected endpoint
@app.route('/api/protected/resource', methods=['GET'])
def protected_resource():
    # Verify the signature
    verification_result = verify_signature()
    if verification_result:
        return verification_result
    
    # If verification passed, return the protected resource
    return jsonify({
        'message': 'This is a protected resource',
        'data': 'Sensitive information'
    })

# Device registration endpoint (would normally require other authentication)
@app.route('/api/register-device', methods=['POST'])
def register_device():
    data = request.get_json()
    device_id = data.get('deviceId')
    
    if not device_id:
        return jsonify({'error': 'Device ID is required'}), 400
    
    # Generate a new signing key for the device
    signing_key = os.urandom(32).hex()
    
    # Store it in our database
    device_signing_keys[device_id] = signing_key
    
    # Return the key to the client (only done during secure registration)
    return jsonify({'signingKey': signing_key})

if __name__ == '__main__':
    app.run(debug=True, port=3000)
```

## Security Considerations

1. **Key Storage**: In a production environment, device signing keys should be stored in a secure database with appropriate encryption.

2. **Device Registration**: The device registration process should be secured with strong authentication to ensure that only legitimate devices receive signing keys.

3. **Key Rotation**: Implement a mechanism to periodically rotate signing keys to limit the impact of key compromise.

4. **Rate Limiting**: Apply rate limiting to prevent brute force attacks against the signature verification system.

5. **Logging and Monitoring**: Log all signature verification failures and implement alerts for suspicious patterns that might indicate an attack.

6. **Timestamp Precision**: Consider the precision of timestamps and potential clock skew between clients and servers when implementing timestamp validation.

7. **Content Encoding**: Ensure consistent encoding of request bodies between client and server to avoid signature mismatches.