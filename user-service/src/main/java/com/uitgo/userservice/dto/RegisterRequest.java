package com.uitgo.userservice.dto;

import com.fasterxml.jackson.annotation.JsonProperty;

public class RegisterRequest {
    @JsonProperty("email")
    private String email;
    @JsonProperty("password")
    private String password;
    @JsonProperty("fullName")
    private String fullName;
    @JsonProperty("phone")
    private String phone;
    @JsonProperty("role")
    private String role; // PASSENGER or DRIVER
    @JsonProperty("vehicleInfo")
    private Object vehicleInfo; // optional

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getFullName() { return fullName; }
    public void setFullName(String fullName) { this.fullName = fullName; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    public Object getVehicleInfo() { return vehicleInfo; }
    public void setVehicleInfo(Object vehicleInfo) { this.vehicleInfo = vehicleInfo; }
}
