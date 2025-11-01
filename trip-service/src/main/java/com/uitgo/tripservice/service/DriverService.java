package com.uitgo.tripservice.service;

import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Service;
import org.springframework.web.client.RestTemplate;

@Service
public class DriverService {
    private final RestTemplate restTemplate;

    @Value("${driver.service.url:http://localhost:8082}")
    private String driverServiceUrl;

    public DriverService(RestTemplate restTemplate) {
        this.restTemplate = restTemplate;
    }

    // Placeholder for future integration
}
