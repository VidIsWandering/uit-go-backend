package com.uitgo.tripservice.config;

import java.io.IOException;
import java.util.Collections;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.springframework.security.authentication.UsernamePasswordAuthenticationToken;
import org.springframework.security.core.context.SecurityContextHolder;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

import com.uitgo.tripservice.service.JwtService;

import io.jsonwebtoken.Jwts;

@Component
public class JwtAuthenticationFilter extends OncePerRequestFilter {

    private final JwtService jwtService;

    public JwtAuthenticationFilter(JwtService jwtService) {
        this.jwtService = jwtService;
    }

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String auth = request.getHeader("Authorization");
        if (auth != null && auth.startsWith("Bearer ")) {
            String token = auth.substring(7);
            try {
                var claims = Jwts.parserBuilder()
                        .setSigningKey(jwtService.getSigningKey())
                        .build()
                        .parseClaimsJws(token)
                        .getBody();
                String userId = claims.getSubject();
                if (userId != null) {
                    var authToken = new UsernamePasswordAuthenticationToken(userId, null, Collections.emptyList());
                    SecurityContextHolder.getContext().setAuthentication(authToken);
                }
            } catch (Exception e) {
                // invalid token -> no authentication set
            }
        }
        filterChain.doFilter(request, response);
    }
}
