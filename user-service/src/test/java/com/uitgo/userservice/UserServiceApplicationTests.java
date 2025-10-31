package com.uitgo.userservice;

import static org.assertj.core.api.Assertions.assertThat;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.web.client.TestRestTemplate;
import org.springframework.boot.web.server.LocalServerPort;
import org.springframework.http.HttpEntity;
import org.springframework.http.HttpHeaders;
import org.springframework.http.HttpMethod;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.uitgo.userservice.dto.AuthRequest;
import com.uitgo.userservice.dto.RegisterRequest;

@SpringBootTest(webEnvironment = SpringBootTest.WebEnvironment.RANDOM_PORT)
public class UserServiceApplicationTests {

    @LocalServerPort
    private int port;

    @Autowired
    private TestRestTemplate rest;

    private ObjectMapper mapper = new ObjectMapper();

    @Test
    public void fullRegisterLoginFlow() throws Exception {
        String base = "http://localhost:" + port;
        RegisterRequest r = new RegisterRequest();
        r.setEmail("test@example.com");
        r.setPassword("pass1234");
        r.setFull_name("Nguyen Van Test");
        r.setPhone("0909000000");
        r.setRole("PASSENGER");

        ResponseEntity<String> reg = rest.postForEntity(base + "/users", r, String.class);
        assertThat(reg.getStatusCode()).isEqualTo(HttpStatus.CREATED);

        AuthRequest a = new AuthRequest();
        a.setEmail("test@example.com");
        a.setPassword("pass1234");

        ResponseEntity<String> login = rest.postForEntity(base + "/sessions", a, String.class);
        assertThat(login.getStatusCode()).isEqualTo(HttpStatus.OK);
        var node = mapper.readTree(login.getBody());
        String token = node.get("access_token").asText();
        assertThat(token).isNotEmpty();

        HttpHeaders hdr = new HttpHeaders();
        hdr.setBearerAuth(token);
        HttpEntity<Void> ent = new HttpEntity<>(hdr);
        ResponseEntity<String> me = rest.exchange(base + "/users/me", HttpMethod.GET, ent, String.class);
        assertThat(me.getStatusCode()).isEqualTo(HttpStatus.OK);
        var meNode = mapper.readTree(me.getBody());
        assertThat(meNode.get("email").asText()).isEqualTo("test@example.com");
    }
}
