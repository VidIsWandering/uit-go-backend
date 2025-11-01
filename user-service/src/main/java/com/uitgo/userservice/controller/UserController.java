package com.uitgo.userservice.controller;

import java.util.HashMap;
import java.util.Map;
import java.util.Optional;

import javax.servlet.http.HttpServletRequest;

import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.http.ResponseEntity;
import org.springframework.security.crypto.bcrypt.BCryptPasswordEncoder;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RestController;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.uitgo.userservice.dto.AuthRequest;
import com.uitgo.userservice.dto.RegisterRequest;
import com.uitgo.userservice.model.User;
import com.uitgo.userservice.repository.UserRepository;
import com.uitgo.userservice.service.JwtService;

@RestController
public class UserController {

    @Autowired
    private UserRepository userRepository;

    @Autowired
    private JwtService jwtService;

    private BCryptPasswordEncoder passwordEncoder = new BCryptPasswordEncoder();

    private final ObjectMapper mapper = new ObjectMapper();
    
    @PostMapping("/users")
    public ResponseEntity<?> register(@RequestBody RegisterRequest req) {
        if (userRepository.findByEmail(req.getEmail()).isPresent()) {
            return ResponseEntity.status(400).body(Map.of("error", "email_exists"));
        }
        User u = new User();
        u.setEmail(req.getEmail());
        u.setPassword(passwordEncoder.encode(req.getPassword()));
    u.setFullName(req.getFullName());
        u.setPhone(req.getPhone());
        u.setRole(req.getRole());
        try {
            if (req.getVehicleInfo() != null) {
                u.setVehicleInfo(mapper.writeValueAsString(req.getVehicleInfo()));
            }
        } catch (Exception e) {
            // ignore
        }
        userRepository.save(u);
        Map<String, Object> resp = new HashMap<>();
        resp.put("id", u.getId());
        resp.put("email", u.getEmail());
    resp.put("fullName", u.getFullName());
        resp.put("role", u.getRole());
        // include created_at to match API contract (ISO-8601)
        if (u.getCreatedAt() != null) {
            resp.put("createdAt", u.getCreatedAt().toString());
        }
        return ResponseEntity.status(201).body(resp);
    }

    @PostMapping("/sessions")
    public ResponseEntity<?> login(@RequestBody AuthRequest req) {
        Optional<User> uo = userRepository.findByEmail(req.getEmail());
        if (uo.isEmpty()) return ResponseEntity.status(401).body(Map.of("error", "invalid_credentials"));
        User u = uo.get();
        if (!passwordEncoder.matches(req.getPassword(), u.getPassword())) {
            return ResponseEntity.status(401).body(Map.of("error", "invalid_credentials"));
        }
        String token = jwtService.generateToken(u.getId(), u.getEmail());
        return ResponseEntity.ok(Map.of("access_token", token));
    }

    @GetMapping("/users/me")
    public ResponseEntity<?> me(HttpServletRequest request) {
        // Very small JWT parsing for demo (no validation)
        String auth = request.getHeader("Authorization");
        if (auth == null || !auth.startsWith("Bearer ")) return ResponseEntity.status(401).build();
        String token = auth.substring(7);
        // parse subject using jjwt
    try {
        var claims = io.jsonwebtoken.Jwts.parserBuilder()
            .setSigningKey(jwtService.getSigningKey())
            .build()
            .parseClaimsJws(token)
            .getBody();
        String userId = claims.getSubject();
            Optional<User> uo = userRepository.findById(userId);
            if (uo.isEmpty()) return ResponseEntity.status(401).build();
            User u = uo.get();
            Map<String, Object> resp = new HashMap<>();
            resp.put("id", u.getId());
            resp.put("email", u.getEmail());
            resp.put("fullName", u.getFullName());
            resp.put("phone", u.getPhone());
            resp.put("role", u.getRole());
            return ResponseEntity.ok(resp);
        } catch (Exception e) {
            return ResponseEntity.status(401).build();
        }
    }
}
