package com.uitgo.tripservice.service;

import java.util.UUID;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

import com.uitgo.tripservice.dto.LocationDTO;

@Service
public class DriverService {
    private final RestTemplate restTemplate;

    @Value("${driver.service.url:http://localhost:8082}")
    private String driverServiceUrl;

    public DriverService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    /**
     * Lấy vị trí hiện tại của tài xế từ driver-service
     * Endpoint: GET /drivers/{driverId}/location
     */
    public LocationDTO getDriverLocation(UUID driverId) {
        String url = driverServiceUrl + "/drivers/" + driverId + "/location";
        try {
            return restTemplate.getForObject(url, LocationDTO.class);
        } catch (Exception e) {
            // Nếu không lấy được, trả về vị trí mặc định (TP.HCM)
            return new LocationDTO(10.8231, 106.6297);
        }
    }
}
