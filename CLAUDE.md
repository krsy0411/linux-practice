# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Repository Overview

This is a learning repository for Linux fundamentals, cloud infrastructure, and containerization. It contains hands-on practice materials organized by topic.

## Repository Structure

- `apache/` - Apache web server configuration examples and Azure VM setup guides
- `docker/dockerfile-basic/` - Dockerfile examples for different frameworks:
  - `springboot-demo/` - Spring Boot multi-stage build (Java 17, Gradle)
  - `nestjs-demo/` - NestJS multi-stage build (Node 18)
  - `nginx-demo/` - Static site with custom nginx config
- `linux/` - Shell scripting and Linux command practice by topic
- `terraform/` - AWS infrastructure as code:
  - `terraform-basic/` - S3 bucket example
  - `vpc-practice/` - VPC with public/private subnets, NAT Gateway, route tables

## Common Commands

### Terraform (AWS ap-northeast-2)
```bash
cd terraform/vpc-practice  # or terraform-basic
terraform init
terraform plan
terraform apply
terraform destroy
```

### Docker Builds
```bash
# Spring Boot (multi-stage, linux/amd64)
cd docker/dockerfile-basic/springboot-demo
docker build -t springboot-demo .
docker run -p 8080:8080 springboot-demo

# NestJS
cd docker/dockerfile-basic/nestjs-demo
docker build -t nestjs-demo .
docker run -p 3000:3000 nestjs-demo

# Nginx static site
cd docker/dockerfile-basic/nginx-demo
docker build -t nginx-demo .
docker run -p 80:80 nginx-demo
```

### NestJS Demo
```bash
cd docker/dockerfile-basic/nestjs-demo
npm install
npm run start:dev     # Development with hot reload
npm run build         # Build for production
npm run lint          # ESLint
npm run test          # Jest unit tests
npm run test:e2e      # End-to-end tests
```

### Spring Boot Demo
```bash
cd docker/dockerfile-basic/springboot-demo
./gradlew bootJar     # Build JAR
./gradlew test        # Run tests
```

## Architecture Notes

- Terraform uses AWS provider with Seoul region (ap-northeast-2)
- VPC practice implements a standard AWS VPC pattern: public subnet with IGW, private subnet with NAT Gateway for outbound-only internet access
- Docker builds use multi-stage patterns to minimize image size
- Spring Boot Dockerfile forces linux/amd64 platform for Apple Silicon compatibility
