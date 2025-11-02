package com.uitgo.userservice.config;

import java.io.IOException;

import javax.servlet.FilterChain;
import javax.servlet.ServletException;
import javax.servlet.http.HttpServletRequest;
import javax.servlet.http.HttpServletResponse;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.stereotype.Component;
import org.springframework.web.filter.OncePerRequestFilter;

@Component
public class RequestLoggingFilter extends OncePerRequestFilter {

    private static final Logger log = LoggerFactory.getLogger("http.server.user-service");

    @Override
    protected void doFilterInternal(HttpServletRequest request, HttpServletResponse response, FilterChain filterChain)
            throws ServletException, IOException {
        String method = request.getMethod();
        String uri = request.getRequestURI();
        String auth = request.getHeader("Authorization");
        String authPreview = (auth == null || auth.isEmpty()) ? "<none>"
                : (auth.length() > 32 ? auth.substring(0, 32) + "..." : auth);
        log.info("Inbound HTTP {} {} Authorization={}", method, uri, authPreview);
        filterChain.doFilter(request, response);
    }
}
