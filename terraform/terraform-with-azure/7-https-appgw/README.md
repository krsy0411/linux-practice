# 7-https-appgw: Azure 3-Tier Architecture with HTTPS

## 📋 프로젝트 개요

Azure Application Gateway를 이용한 **HTTPS 기반 3-Tier 아키텍처** 실습 프로젝트입니다.

### 학습 목표
- ✅ Application Gateway를 통한 HTTPS 트래픽 처리
- ✅ SSL/TLS 종단 (TLS Termination)
- ✅ 3-Tier 아키텍처 설계 및 구현
- ✅ NAT Gateway를 통한 아웃바운드 인터넷 연결
- ✅ Azure Database for MySQL 연동
- ✅ Auto Scaling 및 모니터링
- ✅ 네트워크 보안 (NSG, Private Access)

---

## 🏗️ 아키텍처

```
┌─────────────────────────────────────────────────────────────────────┐
│                          인터넷 (사용자)                              │
└───────────────────────────────┬─────────────────────────────────────┘
                                │ HTTPS (443)
                                ↓
                    ┌───────────────────────────┐
                    │  Application Gateway      │
                    │  (Public IP)              │
                    │  - SSL/TLS 종단           │
                    │  - HTTP → HTTPS 리다이렉션 │
                    │  - WAF (선택)             │
                    └─────────┬─────────────────┘
                              │ HTTP (80)
                              ↓
┌─────────────────────────────────────────────────────────────────────┐
│                         VNet: 10.10.0.0/16                          │
├─────────────────────────────────────────────────────────────────────┤
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ Tier 1: Application Gateway Subnet (10.10.0.0/27)              │ │
│ │ - Application Gateway 인스턴스                                  │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                                                                     │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ Tier 2: App Subnet (10.10.1.0/24)                              │ │
│ │ ┌───────────────────────────────────────┐                       │ │
│ │ │ VMSS: app-vmss                        │                       │ │
│ │ │ - 최소 2개, 최대 5개 인스턴스          │                       │ │
│ │ │ - Ubuntu 22.04 + Nginx                │                       │ │
│ │ │ - Auto Scaling (CPU 기반)             │                       │ │
│ │ └───────────────────────────────────────┘                       │ │
│ │                         ↓                                       │ │
│ │                   NAT Gateway                                   │ │
│ │                   (아웃바운드 인터넷)                            │ │
│ └─────────────────────────────────────────────────────────────────┘ │
│                              │ MySQL (3306)                          │
│                              ↓                                       │
│ ┌─────────────────────────────────────────────────────────────────┐ │
│ │ Tier 3: DB Subnet (10.10.2.0/24)                               │ │
│ │ ┌───────────────────────────────────────┐                       │ │
│ │ │ Azure Database for MySQL              │                       │ │
│ │ │ - Flexible Server                     │                       │ │
│ │ │ - Private Access (VNet 통합)          │                       │ │
│ │ │ - SSL/TLS 필수                        │                       │ │
│ │ └───────────────────────────────────────┘                       │ │
│ └─────────────────────────────────────────────────────────────────┘ │
└─────────────────────────────────────────────────────────────────────┘

보안 규칙 (NSG):
- Tier 1: 인터넷 → 80, 443 허용
- Tier 2: Tier 1 → 80 허용, Tier 3 → 3306 허용, 인터넷 → NAT Gateway
- Tier 3: Tier 2 → 3306 허용, 인터넷 차단
```

---

## 🚀 빠른 시작

### 1️⃣ 전제 조건
```bash
# 도구 설치 확인
terraform version  # >= 1.5.0
az --version

# Azure 로그인
az login
az account set --subscription "<subscription-id>"
```

### 2️⃣ SSL 인증서 생성
```bash
# Self-signed 인증서 생성 (테스트용)
mkdir -p ~/certs/7-https-appgw && cd ~/certs/7-https-appgw

# 인증서 생성
openssl req -x509 -newkey rsa:4096 -keyout key.pem -out cert.pem -days 365 -nodes \
  -subj "/C=KR/ST=Seoul/L=Seoul/O=MyCompany/OU=IT/CN=*.koreacentral.cloudapp.azure.com"

# PFX 변환
openssl pkcs12 -export -out certificate.pfx -inkey key.pem -in cert.pem -passout pass:YourPassword123

# Base64 인코딩
cat certificate.pfx | base64 | tr -d '\n' > certificate.base64
```

### 3️⃣ Bootstrap 실행
```bash
cd terraform/terraform-with-azure/7-https-appgw/bootstrap

terraform init
terraform apply

# Access Key 저장
export ARM_ACCESS_KEY="$(terraform output -raw primary_access_key)"
```

### 4️⃣ 환경 설정
```bash
cd ../environments/dev

# 변수 파일 생성
cp terraform.tfvars.example terraform.tfvars
vim terraform.tfvars  # SSL 인증서 정보 입력

# 필수 수정 항목:
# - ssl_certificate_data
# - ssl_certificate_password
# - domain_name_label (고유한 값)
# - mysql_server_name (고유한 값)
```

### 5️⃣ 인프라 생성
```bash
terraform init
terraform plan
terraform apply  # 약 20~30분 소요
```

### 6️⃣ 접속 확인
```bash
# Public IP 확인
terraform output appgw_public_ip

# 브라우저에서 접속
# https://<public-ip>
```

---

## 🔑 주요 기능

### 1. HTTPS 지원
- **SSL/TLS 종단**: Application Gateway에서 SSL 처리
- **HTTP → HTTPS 리다이렉션**: 자동 리다이렉션
- **최신 SSL Policy**: TLS 1.2+ 지원

### 2. 3-Tier 아키텍처
- **Tier 1 (Presentation)**: Application Gateway
- **Tier 2 (Application)**: VMSS (애플리케이션 서버)
- **Tier 3 (Data)**: Azure Database for MySQL

### 3. 보안
- **NSG**: 계층별 네트워크 격리
- **NAT Gateway**: 아웃바운드 전용 인터넷 연결
- **Private Access**: 데이터베이스는 VNet 내부에서만 접근

### 4. Auto Scaling
- **Application Gateway**: 트래픽 기반 자동 확장
- **VMSS**: CPU 기반 자동 확장 (2~5 인스턴스)

### 5. 고가용성
- **Multiple Instances**: Application Gateway 2개 인스턴스
- **VMSS**: 최소 2개 인스턴스 보장
- **Database Backup**: 자동 백업 (7일 보관)

---

## 🧪 테스트

### HTTPS 접속 테스트
```bash
PUBLIC_IP=$(terraform output -raw appgw_public_ip)

# HTTP → HTTPS 리다이렉션 확인
curl -I http://${PUBLIC_IP}

# HTTPS 직접 접속
curl -k https://${PUBLIC_IP}
```

### Auto Scaling 테스트
```bash
# 부하 발생
ab -n 10000 -c 100 https://${PUBLIC_IP}/

# Azure Portal에서 VMSS 인스턴스 수 증가 확인
```

### MySQL 연결 테스트
```bash
# VMSS 인스턴스에서 실행 (Azure Portal Serial Console)
mysql -h <mysql-fqdn> -u mysqladmin -p appdb
```

---

## 🧹 정리

### 전체 삭제
```bash
# 환경 삭제
cd environments/dev
terraform destroy

# Bootstrap 삭제 (선택)
cd ../../bootstrap
terraform destroy
```

**주의:**
- 데이터베이스 데이터는 복구 불가능
- 백업이 필요한 경우 먼저 백업 수행