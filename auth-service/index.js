const express = require('express');
const jwt = require('jsonwebtoken');
const bodyParser = require('body-parser');

const app = express();

const JWT_SECRET = process.env.JWT_SECRET || 'test-jwt-secret-only-for-local';

// Endpoint used by nginx auth_request to validate token
// nginx will send the same Authorization header; we respond 200 if valid, 401 if invalid
// Note: nginx sends this as subrequest with proxy_pass_request_body off, so don't read req.body
// CRITICAL: Do NOT use bodyParser on this route - nginx subrequest has no body
app.get('/validate', (req, res) => {
    const auth = req.headers['authorization'] || '';
    if (!auth || !auth.startsWith('Bearer ')) return res.status(401).send('missing');
    const token = auth.substring(7);
    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        // Optionally return user info as header to upstream via nginx
        res.setHeader('X-Auth-User', decoded.sub || '');
        res.status(200).send('ok');
    } catch (err) {
        res.status(401).send('invalid');
    }
});

// Simple health
app.get('/health', (req, res) => res.json({ status: 'ok' }));

// Example: Future endpoints that need JSON body can use bodyParser per-route
// app.post('/refresh-token', bodyParser.json(), (req, res) => {
//     const { refreshToken } = req.body;
//     // ... handle token refresh
// });

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`auth-service listening on ${port}`));
