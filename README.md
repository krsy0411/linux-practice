# Linux & Cloud Infrastructure 학습 저장소

Linux 기초부터 클라우드 인프라, 컨테이너화까지 실습한 내용을 정리한 저장소입니다.

## 개요

이 저장소는 다음을 포함합니다:
- **Linux 기초**: 명령어, 쉘 스크립트, 프로세스 및 권한 관리
- **클라우드 인프라**: Azure VM, AWS/Azure 인프라 코드 (Terraform)
- **컨테이너화**: Docker, Docker Compose를 활용한 멀티스테이지 빌드
- **웹 서버**: Apache 및 Nginx 설정 및 배포

---

## 리포지토리 구조

### Apache Web Server (Azure VM)

Azure Virtual Machine에서 Apache 웹 서버 설치 및 설정 실습

| 경로 | 설명 |
|------|------|
| `apache/CREATE_AZURE_VM.md` | Azure VM 생성 및 Apache 설치 가이드 |
| `apache/DOMAIN.md` | 도메인 설정 및 DNS 학습 |
| `apache/RSYNC_SSH.md` | rsync와 SSH를 이용한 파일 동기화 |
| `apache/etc-apache2/` | Apache 설정 파일 (ports.conf, 가상 호스트) |
| `apache/site1/`, `apache/var-www-html/` | 웹 사이트 콘텐츠 예제 |

### Docker

**Dockerfile 기초**

| 경로 | 설명 |
|------|------|
| `docker/dockerfile-basic/springboot-demo/` | Spring Boot (Java 17, Gradle) 멀티스테이지 빌드 |
| `docker/dockerfile-basic/nestjs-demo/` | NestJS (Node 18) 멀티스테이지 빌드 |
| `docker/dockerfile-basic/nginx-demo/` | Nginx로 정적 사이트 서빙 |

**Docker Compose (멀티 컨테이너)**

| 경로 | 설명 |
|------|------|
| `docker/docker-compose/nestjs-mysql-demo/` | NestJS + MySQL 데이터베이스 연동 |
| `docker/docker-compose/nginx-demo/` | Nginx 역프록시 설정 |

### Linux

리눅스 명령어, 쉘 스크립트, 시스템 관리 실습

| 경로 | 설명 |
|------|------|
| `linux/section3-basic-and-io/` | 기본 명령어, 파일 I/O, 리다이렉션, 파이프 |
| `linux/section4-shell-practice/` | 쉘 스크립트 작성, 변수, 제어 흐름 |
| `linux/section6-process/` | 프로세스 관리, 백그라운드 작업 |
| `linux/section7-user/` | 사용자 및 그룹 관리 |
| `linux/section8-permission/` | 파일 및 디렉토리 권한 (chmod, chown) |

### Terraform - AWS (ap-northeast-2)

AWS에서 Infrastructure as Code 실습

| 경로 | 설명 |
|------|------|
| `terraform/terraform-basic/` | S3 버킷 생성 예제 |
| `terraform/vpc-practice/` | VPC, 퍼블릭/프라이빗 서브넷, IGW, NAT Gateway, 라우트 테이블 |
| `terraform/iam-practice/` | IAM 역할 및 정책 관리 |
| `terraform/s3-pratice/` | S3 버킷 및 객체 관리 |
| `terraform/ec2-bootstrap/` | EC2 인스턴스 부트스트랩 실습 |

### Terraform - Azure

Azure에서 Infrastructure as Code 실습 (단계별 학습 구조)

| 경로 | 설명 |
|------|------|
| `terraform/terraform-with-azure/1-basic-resource-creation-test/` | Terraform 기초: 철학, 핵심 개념, 실무 워크플로우 |
| `terraform/terraform-with-azure/2-basic-vnet-design/` | Azure VNet과 Subnet 기초, 리소스 간 의존성 관리 |
| `terraform/terraform-with-azure/3-vnet-with-nsg/` | Azure NSG(Network Security Group) 및 네트워크 보안 규칙 |
| `terraform/terraform-with-azure/4-3tier-architecture/` | 3-Tier 아키텍처 구현 및 Variables 활용 |
| `terraform/terraform-with-azure/5-3tier-service/` | Terraform 파일 기능별 분리 및 실제 애플리케이션 자동 배포 |
| `terraform/terraform-with-azure/6-vmss-lb/` | VMSS + Load Balancer를 이용한 확장 가능한 인프라 구축 |

---

## 실습 환경

- **클라우드**: Microsoft Azure, AWS (ap-northeast-2 리전)
- **OS**: Linux (Ubuntu 24.04)
- **로컬 환경**: macOS + Terminal
- **필수 도구**: Docker, Docker Compose, Terraform, Git
