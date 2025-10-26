// file: driver-service/controllers/driver.controller.js
const driverService = require("../services/driver.service");

/**
 * Controller cho: PUT /drivers/:id/location
 */
const updateDriverLocation = async (req, res) => {
  try {
    const { id } = req.params;
    const { latitude, longitude } = req.body;

    if (!latitude || !longitude) {
      return res.status(400).json({
        error: "Vĩ độ (latitude) và kinh độ (longitude) là bắt buộc.",
      });
    }

    const result = await driverService.updateLocation(id, longitude, latitude);
    console.log(
      `Đã cập nhật vị trí cho tài xế ${id}: [${longitude}, ${latitude}]`
    );
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ error: "Lỗi máy chủ nội bộ" });
  }
};

/**
 * Controller cho: GET /drivers/search
 */
const searchDrivers = async (req, res) => {
  try {
    const { lat, lng } = req.query;

    // --- LOGIC MỚI: Đọc 'radius' từ query, mặc định là 5km ---
    const radius = parseFloat(req.query.radius) || 5.0; // Mặc định là 5km

    if (!lat || !lng) {
      return res
        .status(400)
        .json({ error: "Query params `lat` và `lng` là bắt buộc." });
    }

    // Truyền 'radius' vào service
    const results = await driverService.findNearby(lng, lat, radius);

    console.log(
      `Tìm thấy ${results.drivers.length} tài xế gần [${lng}, ${lat}] trong bán kính ${radius}km`
    );
    res.status(200).json(results);
  } catch (error) {
    res.status(500).json({ error: "Lỗi máy chủ nội bộ" });
  }
};

/**
 * Controller cho: PUT /drivers/:id/status
 */
const updateDriverStatus = async (req, res) => {
  try {
    const { id } = req.params;
    const { status } = req.body;

    if (!status || (status !== "ONLINE" && status !== "OFFLINE")) {
      return res.status(400).json({
        error:
          'Trạng thái (status) là bắt buộc và phải là "ONLINE" hoặc "OFFLINE".',
      });
    }

    const result = await driverService.updateStatus(id, status);
    console.log(`Đã cập nhật trạng thái cho tài xế ${id}: ${status}`);
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ error: "Lỗi máy chủ nội bộ" });
  }
};

/**
 * Controller cho: GET /drivers/:id/location
 */
const getDriverLocation = async (req, res) => {
  try {
    const { id } = req.params;
    const result = await driverService.getLocation(id);

    if (!result) {
      return res
        .status(404)
        .json({ error: "Không tìm thấy vị trí cho tài xế này." });
    }

    console.log(`Lấy vị trí cho tài xế ${id}`);
    res.status(200).json(result);
  } catch (error) {
    res.status(500).json({ error: "Lỗi máy chủ nội bộ" });
  }
};

module.exports = {
  updateDriverLocation,
  searchDrivers,
  updateDriverStatus,
  getDriverLocation,
};
