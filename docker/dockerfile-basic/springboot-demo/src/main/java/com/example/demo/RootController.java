package com.example.demo;

import org.springframework.http.MediaType;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class RootController {
    @GetMapping(value = "/", produces = MediaType.TEXT_HTML_VALUE)
    public String root() {
        return "<!doctype html><html><head><meta charset=\"utf-8\"><title>Spring Boot Demo</title></head><body><h1>Welcome to Spring Boot Demo</h1><p>Running in Docker on port 8080</p></body></html>";
    }
}
