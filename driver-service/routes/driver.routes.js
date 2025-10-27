// file: driver-service/routes/driver.routes.js
const express = require("express");
const router = express.Router();
const driverController = require("../controllers/driver.controller");

// API 1: Cập nhật vị trí
router.put("/:id/location", driverController.updateDriverLocation);

// API 2: Tìm tài xế gần
router.get("/search", driverController.searchDrivers);

// API 3: Cập nhật trạng thái (Online/Offline)
router.put("/:id/status", driverController.updateDriverStatus);

// API 4: Lấy vị trí của 1 tài xế
router.get("/:id/location", driverController.getDriverLocation);

module.exports = router;
