// file: driver-service/index.js
const express = require("express");
const client = require("prom-client");

// --- Khởi tạo ---
const app = express();
const port = process.env.PORT ? parseInt(process.env.PORT, 10) : 8082;

// --- Prometheus Metrics Setup ---
// Collect default metrics (CPU, Memory, Event Loop Lag, etc.)
const collectDefaultMetrics = client.collectDefaultMetrics;
collectDefaultMetrics({ register: client.register });

// Custom metric: HTTP Request Duration
const httpRequestDurationMicroseconds = new client.Histogram({
  name: "http_request_duration_seconds",
  help: "Duration of HTTP requests in seconds",
  labelNames: ["method", "route", "code"],
  buckets: [0.1, 0.3, 0.5, 0.7, 1, 3, 5, 7, 10],
});

// Middleware to measure request duration
app.use((req, res, next) => {
  const end = httpRequestDurationMicroseconds.startTimer();
  res.on("finish", () => {
    end({
      method: req.method,
      route: req.route ? req.route.path : req.path,
      code: res.statusCode,
    });
  });
  next();
});

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
  console.log("SQS Consumer started");
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

// Metrics endpoint for Prometheus
app.get("/metrics", async (req, res) => {
  res.setHeader("Content-Type", client.register.contentType);
  res.send(await client.register.metrics());
});

// --- Khởi chạy Server ---
app.listen(port, () => {
  console.log(`DriverService (Node.js) đang lắng nghe trên port ${port}`);
});
