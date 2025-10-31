const express = require('express');
const jwt = require('jsonwebtoken');
const bodyParser = require('body-parser');

const app = express();
app.use(bodyParser.json());

const JWT_SECRET = process.env.JWT_SECRET || 'test-jwt-secret-only-for-local';

// Endpoint used by nginx auth_request to validate token
// nginx will send the same Authorization header; we respond 200 if valid, 401 if invalid
app.post('/validate', (req, res) => {
    const auth = req.headers['authorization'] || req.body.authorization || '';
    if (!auth || !auth.startsWith('Bearer ')) return res.status(401).send('missing');
    const token = auth.substring(7);
    try {
        const decoded = jwt.verify(token, JWT_SECRET);
        // Optionally return user info as header to upstream via nginx
        res.status(200).json({ ok: true, sub: decoded.sub || decoded.sub });
    } catch (err) {
        res.status(401).send('invalid');
    }
});

// Simple health
app.get('/health', (req, res) => res.json({ status: 'ok' }));

const port = process.env.PORT || 3000;
app.listen(port, () => console.log(`auth-service listening on ${port}`));
