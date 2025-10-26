// file: driver-service/services/driver.service.js
const Redis = require("ioredis");

const redisUrl = process.env.REDIS_URL || "redis://localhost:6379";
const redis = new Redis(redisUrl);

const DRIVER_LOCATION_KEY = "driver_locations";
const DRIVER_STATUS_KEY = "driver_status";

redis.on("connect", () => {
  console.log("DriverService (Service) đã kết nối thành công tới Redis! 🎉");
});
redis.on("error", (err) => {
  console.error("Không thể kết nối tới Redis:", err);
});

/**
 * Logic cập nhật vị trí
 */
const updateLocation = async (driverId, longitude, latitude) => {
  try {
    await redis.geoadd(DRIVER_LOCATION_KEY, longitude, latitude, driverId);
    return { status: "updated", driver_id: driverId };
  } catch (error) {
    console.error("Lỗi service (updateLocation):", error);
    throw new Error("Lỗi máy chủ khi cập nhật vị trí");
  }
};

/**
 * Logic tìm tài xế gần (ĐÃ NÂNG CẤP)
 * (Hỗ trợ Driver US2: Chỉ tìm tài xế ONLINE)
 */
const findNearby = async (lng, lat, radius) => {
  try {
    // Bước 1: Tìm tất cả tài xế gần (như cũ)
    const results = await redis.geosearch(
      DRIVER_LOCATION_KEY,
      "FROMLONLAT",
      lng,
      lat,
      "BYRADIUS",
      radius,
      "km",
      "WITHDIST",
      "ASC"
    );

    const nearbyDrivers = results.map((result) => ({
      driver_id: result[0],
      distance_km: parseFloat(result[1]),
    }));

    if (nearbyDrivers.length === 0) {
      return { drivers: [] };
    }

    // --- LOGIC MỚI: LỌC TRẠNG THÁI "ONLINE" ---

    // Bước 2: Lấy trạng thái của TẤT CẢ tài xế tìm được
    // HMGET cho phép lấy nhiều 'field' (driver_id) từ một 'key' (DRIVER_STATUS_KEY)
    const driverIds = nearbyDrivers.map((d) => d.driver_id);
    const statuses = await redis.hmget(DRIVER_STATUS_KEY, ...driverIds);

    // Bước 3: Lọc và kết hợp kết quả
    const onlineDrivers = [];
    for (let i = 0; i < nearbyDrivers.length; i++) {
      const driver = nearbyDrivers[i];
      const status = statuses[i]; // Lấy trạng thái tương ứng

      // Chỉ thêm vào kết quả nếu trạng thái là "ONLINE"
      if (status === "ONLINE") {
        onlineDrivers.push({
          driver_id: driver.driver_id,
          distance_km: driver.distance_km,
        });
      }
    }

    return { drivers: onlineDrivers };
  } catch (error) {
    console.error("Lỗi service (findNearby):", error);
    throw new Error("Lỗi máy chủ khi tìm tài xế");
  }
};

/**
 * Logic cập nhật trạng thái (Hỗ trợ Driver US2)
 */
const updateStatus = async (driverId, status) => {
  try {
    await redis.hset(DRIVER_STATUS_KEY, driverId, status);
    return { driver_id: driverId, status: status };
  } catch (error) {
    console.error("Lỗi service (updateStatus):", error);
    throw new Error("Lỗi máy chủ khi cập nhật trạng thái");
  }
};

/**
 * Logic lấy vị trí của 1 tài xế (Hỗ trợ Passenger US3)
 */
const getLocation = async (driverId) => {
  try {
    // GEOPOS trả về một mảng các tọa độ [ [longitude, latitude] ]
    const locationArray = await redis.geopos(DRIVER_LOCATION_KEY, driverId);

    if (!locationArray || !locationArray[0]) {
      return null; // Không tìm thấy vị trí
    }

    const location = {
      longitude: parseFloat(locationArray[0][0]),
      latitude: parseFloat(locationArray[0][1]),
    };

    return { driver_id: driverId, location: location };
  } catch (error) {
    console.error("Lỗi service (getLocation):", error);
    throw new Error("Lỗi máy chủ khi lấy vị trí");
  }
};

// Xuất các hàm logic này ra
module.exports = {
  updateLocation,
  findNearby,
  updateStatus,
  getLocation,
};
