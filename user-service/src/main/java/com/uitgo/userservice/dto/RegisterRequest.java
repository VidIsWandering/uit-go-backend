package com.uitgo.userservice.dto;

public class RegisterRequest {
    private String email;
    private String password;
    private String full_name;
    private String phone;
    private String role; // PASSENGER or DRIVER
    private Object vehicle_info; // optional

    public String getEmail() { return email; }
    public void setEmail(String email) { this.email = email; }
    public String getPassword() { return password; }
    public void setPassword(String password) { this.password = password; }
    public String getFull_name() { return full_name; }
    public void setFull_name(String full_name) { this.full_name = full_name; }
    public String getPhone() { return phone; }
    public void setPhone(String phone) { this.phone = phone; }
    public String getRole() { return role; }
    public void setRole(String role) { this.role = role; }
    public Object getVehicle_info() { return vehicle_info; }
    public void setVehicle_info(Object vehicle_info) { this.vehicle_info = vehicle_info; }
}
