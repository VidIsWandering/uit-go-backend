// file: driver-service/__tests__/driver.service.test.js

// 1. Giả lập 'ioredis' trước khi import service
// Jest sẽ tự động thay thế 'ioredis' bằng bản mock này
const mockRedis = {
  geoadd: jest.fn(),
  geosearch: jest.fn(),
  hmget: jest.fn(),
  hset: jest.fn(),
  geopos: jest.fn(),
  on: jest.fn(),
};
jest.mock("ioredis", () => jest.fn(() => mockRedis));

// 2. Import service (giờ đã dùng redis mock)
const driverService = require("../services/driver.service");

// 3. Bắt đầu viết Test
describe("Driver Service Logic", () => {
  // Xóa các lần gọi mock trước mỗi test
  beforeEach(() => {
    mockRedis.geosearch.mockClear();
    mockRedis.hmget.mockClear();
  });

  it('API "findNearby" phải tìm và lọc đúng tài xế ONLINE', async () => {
    // --- Dàn dựng (Arrange) ---

    // Giả lập GEOSEARCH trả về 2 tài xế gần
    const mockGeoResults = [
      ["driver_A", "1.2"], // Gần
      ["driver_B", "2.5"], // Cũng gần
    ];
    mockRedis.geosearch.mockReturnValue(Promise.resolve(mockGeoResults));

    // Giả lập HMGET (kiểm tra trạng thái)
    // QUAN TRỌNG: 'driver_A' là ONLINE, 'driver_B' là OFFLINE
    const mockStatusResults = ["ONLINE", "OFFLINE"];
    mockRedis.hmget.mockReturnValue(Promise.resolve(mockStatusResults));

    // --- Hành động (Act) ---
    const result = await driverService.findNearby("106.0", "10.0", 5.0);

    // --- Khẳng định (Assert) ---

    // 1. Phải gọi GEOSEARCH
    expect(mockRedis.geosearch).toHaveBeenCalledTimes(1);

    // 2. Phải gọi HMGET với ĐÚNG 2 IDs
    expect(mockRedis.hmget).toHaveBeenCalledWith(
      "driver_status",
      "driver_A",
      "driver_B"
    );

    // 3. Kết quả cuối cùng CHỈ được chứa 'driver_A'
    expect(result.drivers.length).toBe(1);
    expect(result.drivers[0].driver_id).toBe("driver_A");
    expect(result.drivers[0].distance_km).toBe(1.2);
  });

  it('API "findNearby" phải trả về mảng rỗng nếu không có ai ONLINE', async () => {
    // --- Dàn dựng (Arrange) ---
    const mockGeoResults = [["driver_C", "3.0"]];
    mockRedis.geosearch.mockReturnValue(Promise.resolve(mockGeoResults));

    const mockStatusResults = ["OFFLINE"]; // Tài xế C đang OFFLINE
    mockRedis.hmget.mockReturnValue(Promise.resolve(mockStatusResults));

    // --- Hành động (Act) ---
    const result = await driverService.findNearby("106.0", "10.0", 5.0);

    // --- Khẳng định (Assert) ---
    // Kết quả cuối cùng phải là mảng rỗng
    expect(result.drivers.length).toBe(0);
  });
});
