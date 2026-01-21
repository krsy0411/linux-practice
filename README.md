# Linux & Cloud Infrastructure 학습 저장소

Linux 기초부터 클라우드 인프라, 컨테이너화까지 실습한 내용을 정리한 저장소입니다.

## 프로젝트 구조

### Apache Web Server (Azure VM)
Apache 웹 서버 설치 및 설정 실습
- [Azure VM 생성 및 아파치 설치](./apache/CREATE_AZURE_VM.md)
- [도메인 학습](./apache/DOMAIN.md)
- [rsync 및 SSH](./apache/RSYNC_SSH.md)

### Docker
Dockerfile 작성 및 멀티스테이지 빌드 실습
- `dockerfile-basic/springboot-demo/` - Spring Boot (Java 17, Gradle)
- `dockerfile-basic/nestjs-demo/` - NestJS (Node 18)
- `dockerfile-basic/nginx-demo/` - Nginx 정적 사이트

### Terraform (AWS)
AWS 인프라 코드화 실습 (ap-northeast-2 리전)
- `terraform-basic/` - S3 버킷 생성
- `vpc-practice/` - VPC, 서브넷(public/private), IGW, NAT Gateway, 라우트 테이블

### Linux
리눅스 기초 명령어 및 쉘 스크립트 실습
- `section3-basic-and-io/` - 기본 명령어와 I/O
- `section4-shell-practice/` - 쉘 스크립트 작성
- `section6-process/` - 프로세스 관리
- `section7-user/` - 사용자 관리
- `section8-permission/` - 파일 권한

## 실습 환경
- Cloud: Microsoft Azure, AWS
- OS: Linux (Ubuntu 24.04)
- 로컬: macOS + Terminal
