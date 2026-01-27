# Linux & Cloud Infrastructure 학습 저장소

Linux 기초부터 클라우드 인프라, 컨테이너화까지 실습한 내용을 정리한 저장소입니다.

## 📋 개요

이 저장소는 다음을 포함합니다:
- **Linux 기초**: 명령어, 쉘 스크립트, 프로세스 및 권한 관리
- **클라우드 인프라**: Azure VM, AWS 인프라 코드 (Terraform)
- **컨테이너화**: Docker, Docker Compose를 활용한 멀티스테이지 빌드
- **웹 서버**: Apache 및 Nginx 설정 및 배포

---

## 🚀 빠른 시작

### 1. Linux 실습
```bash
cd linux/section3-basic-and-io
# 기본 명령어 및 I/O 리다이렉션 실습
```

### 2. Docker 빌드 및 실행
```bash
# Spring Boot 예제
cd docker/dockerfile-basic/springboot-demo
docker build -t springboot-demo .
docker run -p 8080:8080 springboot-demo

# NestJS 예제
cd docker/dockerfile-basic/nestjs-demo
docker build -t nestjs-demo .
docker run -p 3000:3000 nestjs-demo
```

### 3. Terraform으로 AWS 인프라 배포 (ap-northeast-2)
```bash
cd terraform/vpc-practice
terraform init
terraform plan
terraform apply
```

---

## 📁 프로젝트 구조

### Apache Web Server (Azure VM)
Azure Virtual Machine에서 Apache 웹 서버 설치 및 설정 실습

| 경로 | 설명 |
|------|------|
| [CREATE_AZURE_VM.md](./apache/CREATE_AZURE_VM.md) | Azure VM 생성 및 Apache 설치 가이드 |
| [DOMAIN.md](./apache/DOMAIN.md) | 도메인 설정 및 DNS 학습 |
| [RSYNC_SSH.md](./apache/RSYNC_SSH.md) | rsync와 SSH를 이용한 파일 동기화 |
| `etc-apache2/` | Apache 설정 파일 |
| `site1/`, `var-www-html/` | 웹 사이트 컨텐츠 예제 |

### Docker
**Dockerfile 기초**
- `dockerfile-basic/springboot-demo/` - Spring Boot (Java 17, Gradle) 멀티스테이지 빌드
- `dockerfile-basic/nestjs-demo/` - NestJS (Node 18) 멀티스테이지 빌드
- `dockerfile-basic/nginx-demo/` - Nginx로 정적 사이트 서빙

**Docker Compose (멀티 컨테이너)**
- `docker-compose/nestjs-mysql-demo/` - NestJS + MySQL 데이터베이스 연동
- `docker-compose/nginx-demo/` - Nginx 역프록시 설정

### Terraform (AWS - ap-northeast-2)
AWS에서 Infrastructure as Code 실습

| 경로 | 설명 |
|------|------|
| `terraform-basic/` | S3 버킷 생성 예제 |
| `vpc-practice/` | VPC, 퍼블릭/프라이빗 서브넷, IGW, NAT Gateway, 라우트 테이블 |
| `iam-practice/` | IAM 역할 및 정책 관리 |
| `s3-pratice/` | S3 버킷 및 객체 관리 |

### Linux
리눅스 명령어, 쉘 스크립트, 시스템 관리 실습

| 섹션 | 내용 |
|------|------|
| `section3-basic-and-io/` | 기본 명령어, 파일 I/O, 리다이렉션, 파이프 |
| `section4-shell-practice/` | 쉘 스크립트 작성, 변수, 제어 흐름 |
| `section6-process/` | 프로세스 관리, 백그라운드 작업 |
| `section7-user/` | 사용자 및 그룹 관리 |
| `section8-permission/` | 파일 및 디렉토리 권한 (chmod, chown) |

---

## 🛠️ 실습 환경

- **클라우드**: Microsoft Azure, AWS (ap-northeast-2 리전)
- **OS**: Linux (Ubuntu 24.04)
- **로컬 환경**: macOS + Terminal
- **필수 도구**: Docker, Docker Compose, Terraform, Git

---

## 📚 주요 학습 주제

### Cloud & Infrastructure
- Azure Virtual Machines 설정 및 관리
- AWS 네트워크 아키텍처 (VPC, 서브넷, 라우팅)
- Infrastructure as Code (Terraform)
- 웹 서버 설정 및 도메인 관리

### Containerization
- Dockerfile 작성 및 멀티스테이지 빌드
- Docker Compose로 멀티 컨테이너 오케스트레이션
- 프레임워크별 최적화 (Spring Boot, NestJS, Nginx)
- 데이터베이스 연동 (MySQL)

### Linux & System Administration
- Linux 기본 명령어 및 쉘 스크립트
- 파일 시스템 및 권한 관리
- 프로세스 및 리소스 모니터링
- 사용자 및 그룹 관리

---

## 📖 문서

자세한 내용은 각 섹션의 README.md 또는 가이드 문서를 참고하세요:
- [Apache 설정 가이드](./apache/CREATE_AZURE_VM.md)
- [Docker Compose NestJS+MySQL](./docker/docker-compose/nestjs-mysql-demo/README.md)
- [Linux 기초](./linux/section3-basic-and-io/README.md)
- [Terraform VPC 실습](./terraform/vpc-practice/provider.tf)

---

## 📝 라이선스

이 저장소는 학습 목적으로 작성되었습니다.
