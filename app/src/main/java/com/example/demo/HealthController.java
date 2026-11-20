package com.example.demo;

import java.util.Map;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class HealthController {
    @Value("${spring.application.name:k8s-demo-app}")
    private String appName;

    @Value("${app.environment:local}")
    private String environment;

    @GetMapping("/api/health")
    public Map<String, String> health() {
        return Map.of("status", "UP", "message", "Application is running");
    }

    @GetMapping("/api/info")
    public Map<String, String> info() {
        return Map.of("application", appName, "environment", environment);
    }
}
