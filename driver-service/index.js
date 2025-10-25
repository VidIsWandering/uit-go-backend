// file: driver-service/index.js
const express = require('express');
const app = express();
const port = 8082; // Port đã thống nhất trong API Contract

app.use(express.json());

app.get('/', (req, res) => {
  res.send('Hello from Driver Service (Node.js)!');
});

// TODO: Implement PUT /drivers/:id/location
// TODO: Implement GET /drivers/search

app.listen(port, () => {
  console.log(`DriverService (Node.js) listening on port ${port}`);
});