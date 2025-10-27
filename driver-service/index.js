// file: driver-service/index.js
const express = require('express');

// --- Khởi tạo ---
const app = express();
const port = 8082;
app.use(express.json()); // Middleware để đọc JSON body

// --- Import Routes ---
const driverRoutes = require('./routes/driver.routes');

// --- Sử dụng Routes ---
// Tất cả các route trong 'driver.routes.js' sẽ có tiền tố là '/drivers'
app.use('/drivers', driverRoutes);

// API "Hello World" để kiểm tra service
app.get('/', (req, res) => {
  res.status(200).json({ 
    message: 'Hello from Driver Service (Node.js)!'
  });
});

// --- Khởi chạy Server ---
app.listen(port, () => {
  console.log(`DriverService (Node.js) đang lắng nghe trên port ${port}`);
});