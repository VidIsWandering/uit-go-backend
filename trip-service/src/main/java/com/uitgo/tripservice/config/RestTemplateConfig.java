package com.uitgo.tripservice.config;

import org.slf4j.Logger;
import org.slf4j.LoggerFactory;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.client.ClientHttpRequestExecution;
import org.springframework.http.client.ClientHttpRequestInterceptor;
import org.springframework.http.client.ClientHttpResponse;
import org.springframework.web.client.RestTemplate;

import java.io.IOException;

@Configuration
public class RestTemplateConfig {

    private static final Logger httpLog = LoggerFactory.getLogger("http.client.trip-service");

    @Bean
    public RestTemplate restTemplate() {
        RestTemplate rt = new RestTemplate();
        rt.getInterceptors().add(new ClientHttpRequestInterceptor() {
            @Override
            public ClientHttpResponse intercept(org.springframework.http.HttpRequest request, byte[] body,
                                                 ClientHttpRequestExecution execution) throws IOException {
                try {
                    httpLog.info("Outbound HTTP {} {}", request.getMethod(), request.getURI());
                    if (httpLog.isDebugEnabled()) {
                        httpLog.debug("Headers: {}", request.getHeaders());
                    }
                } catch (Exception ignore) { }
                return execution.execute(request, body);
            }
        });
        return rt;
    }
}
