// file: driver-service/index.js
const express = require("express");

// --- Khởi tạo ---
const app = express();
const port = process.env.PORT ? parseInt(process.env.PORT, 10) : 8082;
app.use(express.json()); // Middleware để đọc JSON body

// --- Import Routes ---
const driverRoutes = require("./routes/driver.routes");
const sqsConsumer = require("./services/sqsConsumer");

// --- Sử dụng Routes ---
// Tất cả các route trong 'driver.routes.js' sẽ có tiền tố là '/drivers'
app.use("/drivers", driverRoutes);

// Start SQS Consumer
if (process.env.SQS_QUEUE_URL) {
  sqsConsumer.start();
  console.log('SQS Consumer started');
}

// API "Hello World" để kiểm tra service
app.get("/", (req, res) => {
  res.status(200).json({
    message: "Hello from Driver Service (Node.js)!",
  });
});

// Health endpoint chuẩn để orchestrators/checks sử dụng
app.get("/health", (req, res) => {
  res.status(200).json({ status: "ok" });
});

// --- Khởi chạy Server ---
app.listen(port, () => {
  console.log(`DriverService (Node.js) đang lắng nghe trên port ${port}`);
});
