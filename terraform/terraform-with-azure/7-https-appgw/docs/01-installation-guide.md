# 설치 및 실행 가이드

## 📋 목차
1. [전제 조건](#전제-조건)
2. [SSL 인증서 생성](#ssl-인증서-생성)
3. [Bootstrap 실행](#bootstrap-실행)
4. [환경 설정](#환경-설정)
5. [Terraform 실행](#terraform-실행)
6. [검증](#검증)

---

## 전제 조건

### 필수 도구
```bash
# Terraform 설치 확인
terraform version  # >= 1.5.0

# Azure CLI 설치 확인
az --version

# OpenSSL 설치 확인 (SSL 인증서 생성용)
openssl version
```

### Azure 인증
```bash
# Azure 로그인
az login

# 사용 가능한 구독 확인
az account list --output table

# 사용할 구독 선택
az account set --subscription "<subscription-id>"

# 현재 구독 확인
az account show
```

---

## SSL 인증서 생성

### Self-signed 인증서 생성 (테스트용)

```bash
# 1. 작업 디렉토리 생성
mkdir -p ~/certs/7-https-appgw
cd ~/certs/7-https-appgw

# 2. Private Key 및 인증서 생성
openssl req -x509 \
  -newkey rsa:4096 \
  -keyout key.pem \
  -out cert.pem \
  -days 365 \
  -nodes \
  -subj "/C=KR/ST=Seoul/L=Seoul/O=MyCompany/OU=IT/CN=*.koreacentral.cloudapp.azure.com"

# 3. PFX 형식으로 변환
openssl pkcs12 -export \
  -out certificate.pfx \
  -inkey key.pem \
  -in cert.pem \
  -passout pass:YourPassword123

# 4. Base64 인코딩
cat certificate.pfx | base64 | tr -d '\n' > certificate.base64

# 5. 결과 확인
echo "Certificate created successfully!"
echo "Base64 certificate:"
cat certificate.base64
```

**주의사항:**
- 프로덕션에서는 Let's Encrypt 또는 상용 인증서 사용
- Self-signed 인증서는 브라우저 경고 발생
- PFX 비밀번호는 terraform.tfvars에 입력

### Let's Encrypt 인증서 사용 (프로덕션 권장)

```bash
# Certbot 설치 (Ubuntu/Debian)
sudo apt-get update
sudo apt-get install certbot

# 인증서 발급 (도메인 필요)
sudo certbot certonly --manual --preferred-challenges dns -d yourdomain.com

# PFX로 변환
sudo openssl pkcs12 -export \
  -out /etc/letsencrypt/live/yourdomain.com/certificate.pfx \
  -inkey /etc/letsencrypt/live/yourdomain.com/privkey.pem \
  -in /etc/letsencrypt/live/yourdomain.com/fullchain.pem \
  -passout pass:YourPassword123
```

---

## Bootstrap 실행

### 1. Bootstrap 디렉토리로 이동
```bash
cd terraform/terraform-with-azure/7-https-appgw/bootstrap
```

### 2. Terraform 초기화
```bash
terraform init
```

### 3. 상태 파일 저장소 생성
```bash
# Plan 확인
terraform plan

# Apply 실행
terraform apply

# 출력값 확인
terraform output
terraform output -raw primary_access_key
```

### 4. 환경변수 설정
```bash
# Access Key를 환경변수로 설정
export ARM_ACCESS_KEY="$(terraform output -raw primary_access_key)"

# 영구 저장 (선택사항)
echo "export ARM_ACCESS_KEY=\"$(terraform output -raw primary_access_key)\"" >> ~/.bashrc
source ~/.bashrc
```

---

## 환경 설정

### 1. environments/dev 디렉토리로 이동
```bash
cd ../environments/dev
```

### 2. terraform.tfvars 파일 생성
```bash
# 예제 파일 복사
cp terraform.tfvars.example terraform.tfvars

# 편집기로 열기
vim terraform.tfvars
```

### 3. terraform.tfvars 수정
```hcl
# 기본 설정
resource_group_name = "dev-rg"
location            = "Korea Central"

# Network 설정
vnet_name         = "dev-vnet"
vnet_cidr         = "10.10.0.0/16"
appgw_subnet_cidr = "10.10.0.0/27"
app_subnet_cidr   = "10.10.1.0/24"
db_subnet_cidr    = "10.10.2.0/24"

# Application Gateway 설정
appgw_name        = "dev-appgw"
domain_name_label = "myapp-dev"  # 변경하세요!

# SSL 인증서 (생성한 인증서 정보 입력)
ssl_certificate_data     = "<Base64 인코딩된 PFX 데이터>"
ssl_certificate_password = "YourPassword123"

# VMSS 설정
vmss_name           = "dev-vmss"
vmss_admin_password = "YourSecurePassword123!"

# Database 설정
mysql_server_name    = "dev-mysql-unique123"  # Azure 전체에서 고유해야 함!
mysql_admin_password = "YourSecureMySQLPassword123!"
```

**중요:**
- `domain_name_label`: 고유한 값으로 변경
- `mysql_server_name`: Azure 전체에서 고유해야 함
- 모든 비밀번호는 강력하게 설정
- terraform.tfvars는 Git에 커밋하지 말 것!

### 4. backend.tf 확인
```bash
# backend.tf 파일 확인
cat backend.tf

# bootstrap에서 출력한 값과 일치하는지 확인
# - resource_group_name
# - storage_account_name
# - container_name
```

---

## Terraform 실행

### 1. Terraform 초기화
```bash
terraform init
```

**예상 출력:**
```
Initializing the backend...

Successfully configured the backend "azurerm"!

Initializing modules...
- appgw in ../../modules/appgw
- database in ../../modules/database
- nat_gateway in ../../modules/nat_gateway
- network in ../../modules/network
- nsg in ../../modules/nsg
- vmss in ../../modules/vmss

Terraform has been successfully initialized!
```

### 2. Plan 실행
```bash
terraform plan
```

**확인 사항:**
- 생성될 리소스 개수 (약 30~40개)
- 네트워크 구성 (VNet, Subnet, NSG)
- Application Gateway 설정
- VMSS 설정
- Database 설정

### 3. Apply 실행
```bash
terraform apply
```

**소요 시간:**
- Application Gateway: 약 10~15분
- VMSS: 약 5분
- MySQL: 약 5~10분
- **전체: 약 20~30분**

**Apply 중 확인 사항:**
```
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes  ← 입력
```

### 4. 출력값 확인
```bash
# 모든 출력값 확인
terraform output

# 특정 출력값 확인
terraform output appgw_public_ip
terraform output appgw_https_url
terraform output mysql_server_fqdn
```

---

## 검증

### 1. Azure Portal 확인
```
1. Azure Portal (https://portal.azure.com) 접속
2. Resource Groups → dev-rg 선택
3. 생성된 리소스 확인:
   - Application Gateway: dev-appgw
   - VMSS: dev-vmss
   - MySQL Server: dev-mysql-unique123
   - VNet: dev-vnet
   - NAT Gateway: dev-vnet-nat-gw
```

### 2. HTTPS 접속 테스트
```bash
# Public IP 확인
APPGW_IP=$(terraform output -raw appgw_public_ip)

# HTTP 접속 (자동으로 HTTPS로 리다이렉션)
curl -k -L http://${APPGW_IP}

# HTTPS 직접 접속
curl -k https://${APPGW_IP}

# 브라우저 접속
echo "https://${APPGW_IP}"
```

**예상 결과:**
```html
<!DOCTYPE html>
<html>
<head>
    <title>dev-vmss</title>
    ...
</head>
<body>
    <div class="container">
        <h1>🚀 Azure VMSS with Application Gateway</h1>
        ...
    </div>
</body>
</html>
```

### 3. MySQL 연결 테스트
```bash
# VMSS 인스턴스에서 MySQL 연결 테스트 (Azure Portal의 Serial Console 또는 Bastion 사용)
mysql -h <mysql-fqdn> -u mysqladmin -p appdb
```

### 4. Auto Scaling 테스트
```bash
# 부하 테스트 도구 설치 (로컬)
sudo apt-get install apache2-utils

# 부하 발생 (CPU 70% 이상)
ab -n 10000 -c 100 https://${APPGW_IP}/

# Azure Portal에서 VMSS 인스턴스 수 증가 확인
# Monitoring → Metrics → Instance Count
```

---

## 리소스 정리

### 전체 삭제
```bash
# 환경 삭제
cd environments/dev
terraform destroy

# Bootstrap 삭제 (선택사항)
cd ../../bootstrap
terraform destroy
```

**주의:**
- MySQL 데이터는 복구 불가능
- 백업이 필요한 경우 먼저 백업 후 삭제
- Storage Account 삭제 시 상태 파일도 삭제됨

---

## 다음 단계

- [Azure Portal 확인 가이드](./02-azure-portal-guide.md)
- [HTTPS 설정 가이드](./03-https-setup-guide.md)
- [Application Gateway 가이드](./04-application-gateway-guide.md)
- [Troubleshooting 가이드](./05-troubleshooting-guide.md)
