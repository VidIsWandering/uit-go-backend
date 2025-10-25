// file: driver-service/index.js
const express = require("express");
const Redis = require("ioredis");

// --- Khởi tạo ---
const app = express();
const port = 8082;
app.use(express.json());

// --- 1. Kết nối Redis ---
const redisUrl = process.env.REDIS_URL || "redis://localhost:6379";
const redis = new Redis(redisUrl);

// --- Tên của Key trong Redis ---
// Chúng ta sẽ lưu tất cả vị trí tài xế trong một Geospatial Set tên là 'driver_locations'
const DRIVER_LOCATION_KEY = "driver_locations";

redis.on("connect", () => {
  console.log("DriverService đã kết nối thành công tới Redis! 🎉");
});
redis.on("error", (err) => {
  console.error("Không thể kết nối tới Redis:", err);
});

// --- 2. API Hoàn thiện ---

app.get("/", (req, res) => {
  res.status(200).json({
    message: "Hello from Driver Service (Node.js)!",
    redis_status: redis.status,
  });
});

/**
 * [API 1] Cập nhật vị trí tài xế
 * PUT /drivers/:id/location
 *
 */
app.put("/drivers/:id/location", async (req, res) => {
  try {
    const { id } = req.params;
    const { latitude, longitude } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({
        error: "Vĩ độ (latitude) và kinh độ (longitude) là bắt buộc.",
      });
    }

    // --- LOGIC MỚI: Dùng GEOADD ---
    // Lệnh GEOADD sẽ thêm (hoặc cập nhật nếu đã tồn tại) một thành viên (member)
    // vào một Geospatial key.
    // Cú pháp: GEOADD key longitude latitude member_name
    await redis.geoadd(DRIVER_LOCATION_KEY, longitude, latitude, id);

    console.log(
      `Đã cập nhật vị trí cho tài xế ${id}: [${longitude}, ${latitude}]`
    );

    // Phản hồi thành công (đúng theo API Contract)
    res.status(200).json({
      status: "updated",
      driver_id: id,
    });
  } catch (error) {
    console.error("Lỗi khi cập nhật vị trí:", error);
    res.status(500).json({ error: "Lỗi máy chủ nội bộ" });
  }
});

/**
 * [API 2] Tìm tài xế gần (ĐÃ SỬA LỖI LOGIC LẶP)
 * GET /drivers/search
 *
 */
app.get("/drivers/search", async (req, res) => {
  try {
    const { lat, lng } = req.query;
    const radius = 5; // Tìm trong bán kính 5km

    if (!lat || !lng) {
      return res
        .status(400)
        .json({ error: "Query params `lat` và `lng` là bắt buộc." });
    }

    // Lệnh này đã ĐÚNG (FROMLONLAT)
    const results = await redis.geosearch(
      DRIVER_LOCATION_KEY,
      "FROMLONLAT",
      lng,
      lat,
      "BYRADIUS",
      radius,
      "km",
      "WITHDIST", // Trả về khoảng cách
      "ASC" // Sắp xếp từ gần nhất
    );

    // Log (ĐÚNG): [ [ 'driver_A', '0.0154' ] ]
    console.log(`Redis trả về:`, results);

    // --- LOGIC ĐÃ SỬA (Dùng .map()) ---
    // 'results' là một mảng lồng nhau, nên chúng ta dùng .map()
    const drivers = results.map((result) => {
      // 'result' LÀ mảng con [ 'driver_A', '0.0154' ]
      return {
        driver_id: result[0], // Lấy phần tử 0
        distance_km: parseFloat(result[1]), // Lấy phần tử 1
      };
    });

    console.log(`Tìm thấy ${drivers.length} tài xế.`);

    res.status(200).json({
      drivers: drivers,
    });
  } catch (error) {
    console.error("Lỗi khi tìm tài xế:", error);
    res.status(500).json({ error: "Lỗi máy chủ nội bộ" });
  }
});

// --- Khởi chạy Server ---
app.listen(port, () => {
  console.log(`DriverService (Node.js) đang lắng nghe trên port ${port}`);
});
