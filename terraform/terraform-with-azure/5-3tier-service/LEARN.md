# 5. 실제 서비스를 배포하는 3-Tier 아키텍처 🚀

> **학습 목표**: Terraform 파일을 기능별로 분리하고, VM에 실제 동작하는 애플리케이션을 자동 배포하는 방법을 학습합니다.

---

## 1. 이전 폴더와의 차이점 🔄

### 1.1 4-3tier-architecture vs 5-3tier-service 비교

#### 📁 파일 구조 비교

**4-3tier-architecture** (이전):
```
4-3tier-architecture/
├── main.tf          (260줄 - 모든 리소스)
├── variables.tf     (8줄 - 2개 변수)
└── provider.tf
```

**5-3tier-service** (현재):
```
5-3tier-service/
├── main.tf          (6줄 - Resource Group만)
├── vnet.tf          (27줄 - Network 리소스)
├── nsg.tf           (105줄 - 보안 규칙)
├── web.tf           (55줄 - Web tier)
├── app.tf           (69줄 - App tier)
├── db.tf            (62줄 - DB tier)
├── variables.tf     (11줄 - 3개 변수)
├── outputs.tf       (4줄 - 출력값)
└── provider.tf
```

#### 🎯 핵심 차이점

| 측면 | 4-3tier-architecture | 5-3tier-service |
|------|---------------------|----------------|
| **파일 개수** | 3개 | 9개 |
| **코드 분리** | main.tf에 모두 | 기능별 분리 |
| **애플리케이션** | ❌ 없음 (빈 VM) | ✅ Nginx, Flask, MySQL |
| **custom_data** | ❌ 사용 안 함 | ✅ 자동 설치 스크립트 |
| **SSH 접근** | ❌ NSG 규칙 없음 | ✅ 계층별 SSH 허용 |
| **실제 테스트** | 네트워크만 확인 | 전체 스택 동작 확인 |
| **변수** | 2개 (location, rg_name) | 3개 (+ username, password) |
| **outputs** | ❌ 없음 | ✅ Public IP 출력 |

### 1.2 왜 파일을 분리할까? 🤔

#### 문제 상황: 하나의 파일에 모든 코드

```terraform
# main.tf (260줄)
resource "azurerm_resource_group" "rg" { ... }
resource "azurerm_virtual_network" "vnet" { ... }
resource "azurerm_subnet" "web" { ... }
resource "azurerm_subnet" "app" { ... }
resource "azurerm_subnet" "db" { ... }
resource "azurerm_network_security_group" "web_nsg" { ... }
resource "azurerm_network_security_rule" "web_http" { ... }
resource "azurerm_network_security_group" "app_nsg" { ... }
# ... 200줄 더 ...
```

**문제점**:
- 🔍 특정 리소스 찾기 어려움
- 🤯 코드 이해에 시간 소요
- 👥 여러 명이 동시 작업 시 충돌
- 🐛 버그 발생 시 원인 파악 어려움

#### 해결: 기능별 파일 분리

```terraform
# vnet.tf - 네트워크 담당자가 관리
resource "azurerm_virtual_network" "vnet" { ... }
resource "azurerm_subnet" "web" { ... }
resource "azurerm_subnet" "app" { ... }

# nsg.tf - 보안 담당자가 관리
resource "azurerm_network_security_group" "web_nsg" { ... }
resource "azurerm_network_security_rule" "web_http" { ... }

# web.tf - 프론트엔드 팀이 관리
resource "azurerm_linux_virtual_machine" "web_vm" { ... }

# app.tf - 백엔드 팀이 관리
resource "azurerm_linux_virtual_machine" "app_vm" { ... }

# db.tf - DBA가 관리
resource "azurerm_linux_virtual_machine" "db_vm" { ... }
```

**장점**:
- ✅ 파일 이름만 봐도 내용 예측 가능
- ✅ 팀별로 파일 분담 가능
- ✅ Git merge conflict 감소
- ✅ 코드 리뷰 용이

---

## 2. 파일 분리 전략 📂

### 2.1 파일 구조와 책임

#### 🏗️ Infrastructure Layer (인프라 계층)

**main.tf** - 프로젝트의 시작점
```terraform
resource "azurerm_resource_group" "rg" {
  name     = "rg-3tier-service-pratice"
  location = var.location
}
```
- **책임**: Resource Group 생성
- **왜 분리?**: 모든 리소스의 기반이 되는 최상위 리소스
- **관리자**: DevOps 팀장

**vnet.tf** - 네트워크 토폴로지
```terraform
resource "azurerm_virtual_network" "vnet" { ... }
resource "azurerm_subnet" "web" { ... }
resource "azurerm_subnet" "app" { ... }
resource "azurerm_subnet" "db" { ... }
```
- **책임**: Virtual Network와 Subnet 정의
- **왜 분리?**: 네트워크 설계는 독립적인 도메인
- **관리자**: Network Engineer

**nsg.tf** - 보안 정책
```terraform
resource "azurerm_network_security_group" "web_nsg" { ... }
resource "azurerm_network_security_group" "app_nsg" { ... }
resource "azurerm_network_security_group" "db_nsg" { ... }
```
- **책임**: 모든 NSG와 보안 규칙
- **왜 분리?**: 보안 감사 시 한 곳에서 확인
- **관리자**: Security Engineer

#### 🖥️ Compute Layer (컴퓨팅 계층)

**web.tf** - 프론트엔드 인프라
```terraform
resource "azurerm_public_ip" "web_pip" { ... }
resource "azurerm_network_interface" "web_nic" { ... }
resource "azurerm_linux_virtual_machine" "web_vm" { ... }
```
- **책임**: Web tier 모든 리소스 (Public IP, NIC, VM)
- **관리자**: Frontend Team

**app.tf** - 백엔드 인프라
```terraform
resource "azurerm_network_interface" "app_nic" { ... }
resource "azurerm_linux_virtual_machine" "app_vm" { ... }
```
- **책임**: App tier 모든 리소스
- **관리자**: Backend Team

**db.tf** - 데이터베이스 인프라
```terraform
resource "azurerm_network_interface" "db_nic" { ... }
resource "azurerm_linux_virtual_machine" "db_vm" { ... }
```
- **책임**: DB tier 모든 리소스
- **관리자**: DBA Team

#### ⚙️ Configuration Layer (설정 계층)

**variables.tf** - 입력 변수
```terraform
variable "location" { default = "Korea Central" }
variable "admin_username" { default = "azureuser" }
variable "admin_password" { default = "Password1234!" }
```
- **책임**: 모든 변수 정의
- **관리자**: 모든 팀 (공통)

**outputs.tf** - 출력 값
```terraform
output "web_public_ip" {
  value = azurerm_public_ip.web_pip.ip_address
}
```
- **책임**: 배포 후 필요한 정보 출력
- **관리자**: DevOps

**provider.tf** - Provider 설정
```terraform
terraform { ... }
provider "azurerm" { ... }
```
- **책임**: Terraform과 Azure 연결 설정
- **관리자**: DevOps

### 2.2 파일 분리 원칙

#### 📏 단일 책임 원칙 (Single Responsibility Principle)

```
나쁜 예: 여러 책임을 한 파일에
❌ compute.tf
   - VM도 있고
   - Network도 있고
   - 보안 규칙도 있고
   → 무엇을 위한 파일인지 불명확

좋은 예: 하나의 책임만
✅ web.tf → Web tier만
✅ nsg.tf → 보안만
✅ vnet.tf → 네트워크만
```

#### 🎯 응집도 높이기 (High Cohesion)

**관련된 리소스는 함께 배치**:
```terraform
# web.tf - Web tier의 모든 것
resource "azurerm_public_ip" "web_pip" { ... }      # 1. Public IP
resource "azurerm_network_interface" "web_nic" { ... }  # 2. NIC
resource "azurerm_linux_virtual_machine" "web_vm" { ... }  # 3. VM

# 왜 함께? Web VM을 만들려면 3개가 모두 필요하기 때문
```

#### 🔗 결합도 낮추기 (Low Coupling)

**파일 간 의존성 최소화**:
```terraform
# web.tf가 vnet.tf를 참조 (OK)
subnet_id = azurerm_subnet.web.id  # vnet.tf에 정의된 리소스

# 하지만 web.tf는 app.tf나 db.tf를 참조하지 않음 (Good!)
# 각 tier는 독립적으로 동작
```

### 2.3 Terraform에서 파일 로딩 메커니즘

#### 🔍 중요한 사실

```bash
# Terraform은 작업 디렉토리의 모든 .tf 파일을 자동으로 읽습니다
terraform init
terraform plan
terraform apply

# 내부적으로:
# 1. *.tf 파일을 알파벳 순으로 읽음
# 2. 모든 내용을 하나로 합침
# 3. 리소스 간 의존성 분석
# 4. 생성 순서 자동 결정
```

#### 📋 파일 로딩 순서

```
1. app.tf        ← 알파벳 순
2. db.tf
3. main.tf
4. nsg.tf
5. outputs.tf
6. provider.tf
7. variables.tf
8. vnet.tf
9. web.tf

하지만 로딩 순서는 중요하지 않음!
Terraform이 의존성을 분석해서 올바른 순서로 생성합니다.
```

#### 🎨 실제 효과

```terraform
# web.tf에서
subnet_id = azurerm_subnet.web.id

# azurerm_subnet.web은 vnet.tf에 정의되어 있음
# 파일 순서 상관없이 참조 가능!
# Terraform이 자동으로 "vnet.tf의 subnet 먼저, web.tf의 NIC 나중" 판단
```

---

## 3. Custom Data로 VM 초기화 🎬

### 3.1 Custom Data란?

**Custom Data**는 VM이 처음 생성될 때 **자동으로 실행되는 스크립트**입니다.

#### 🎯 사용 목적

```
VM 생성 후 수동으로:                  Custom Data 사용:
1. SSH 접속                          자동으로 모두 실행됨! ✅
2. sudo apt update
3. sudo apt install nginx
4. sudo systemctl start nginx
   (너무 번거로움 😓)
```

### 3.2 Custom Data 기본 문법

```terraform
resource "azurerm_linux_virtual_machine" "example" {
  # ... 기본 설정 ...
  
  custom_data = base64encode(<<EOF
#!/bin/bash
echo "Hello from custom data!"
apt update
apt install -y nginx
EOF
  )
}
```

**구성 요소**:
1. `custom_data`: VM 초기화 스크립트를 지정하는 속성
2. `base64encode()`: 스크립트를 Base64로 인코딩 (Azure 요구사항)
3. `<<EOF ... EOF`: Bash 스크립트 작성 영역

#### 🔍 base64encode가 필요한 이유

```
Azure Cloud-Init은 스크립트를 Base64 인코딩된 문자열로 받습니다.

원본 스크립트:
#!/bin/bash
apt update

Base64 인코딩 후:
IyEvYmluL2Jhc2gKYXB0IHVwZGF0ZQo=

Terraform의 base64encode()가 이 변환을 자동으로 해줍니다.
```

### 3.3 Web VM: Nginx 자동 설치

#### 📄 web.tf 코드 분석

```terraform
resource "azurerm_linux_virtual_machine" "web_vm" {
  name                = "web-vm"
  resource_group_name = azurerm_resource_group.rg.name
  location            = azurerm_resource_group.rg.location
  size                = "Standard_B1s"
  admin_username      = var.admin_username
  admin_password      = var.admin_password
  disable_password_authentication = false
  
  network_interface_ids = [
    azurerm_network_interface.web_nic.id
  ]

  os_disk {
    caching              = "ReadWrite"
    storage_account_type = "Standard_LRS"
  }

  source_image_reference {
    publisher = "Canonical"
    offer     = "0001-com-ubuntu-server-jammy"
    sku       = "22_04-lts"
    version   = "latest"
  }

  custom_data = base64encode(<<EOF
#!/bin/bash
apt update
apt install -y nginx
systemctl enable nginx
systemctl start nginx
EOF
  )
}
```

#### 🔄 실행 흐름

```
1. Azure가 VM 생성
   └─▶ Ubuntu 22.04 설치

2. VM이 부팅 시작
   └─▶ Cloud-Init 실행

3. Custom Data 스크립트 실행
   ├─▶ apt update (패키지 목록 업데이트)
   ├─▶ apt install -y nginx (Nginx 설치)
   │    └─▶ -y: 자동으로 "Yes" 응답
   ├─▶ systemctl enable nginx (부팅 시 자동 시작 설정)
   └─▶ systemctl start nginx (즉시 시작)

4. Nginx 실행 완료
   └─▶ 포트 80에서 요청 대기 중
```

#### 🌐 결과

```bash
# VM이 생성되고 몇 분 후...
curl http://<web-public-ip>

# 응답:
<html>
<head>
<title>Welcome to nginx!</title>
</head>
...
</html>

# ✅ Nginx가 자동으로 설치되고 실행 중!
```

### 3.4 App VM: Flask 애플리케이션 자동 배포

#### 📄 app.tf 코드 분석

```terraform
resource "azurerm_linux_virtual_machine" "app_vm" {
  # ... 기본 설정 ...
  
  custom_data = base64encode(<<EOF
#!/bin/bash

# 1. 패키지 업데이트 및 Python 설치
apt update
apt install -y python3-pip

# 2. Python 라이브러리 설치
pip3 install flask mysql-connector-python

# 3. Flask 애플리케이션 코드 생성
cat <<EOT > /home/${var.admin_username}/app.py
from flask import Flask
import mysql.connector

app = Flask(__name__)

@app.route("/")
def hello():
    conn = mysql.connector.connect(
        host="10.10.3.4",        # DB VM의 Private IP
        user="appuser",
        password="password123",
        database="appdb"
    )
    cursor = conn.cursor()
    cursor.execute("SELECT 1")
    result = cursor.fetchone()
    return f"DB Connected: {result}"

app.run(host="0.0.0.0", port=5000)
EOT

# 4. 파일 권한 설정
chown ${var.admin_username}:${var.admin_username} /home/${var.admin_username}/app.py

# 5. Flask 앱 백그라운드 실행
nohup python3 /home/${var.admin_username}/app.py &

EOF
  )
}
```

#### 🔍 코드 상세 해설

**1. Heredoc 중첩 (`<<EOF`와 `<<EOT`)**
```bash
cat <<EOT > /home/azureuser/app.py
... Python 코드 ...
EOT

# 설명:
# - <<EOF: Terraform용 Heredoc (Bash 스크립트 전체)
# - <<EOT: Bash용 Heredoc (Python 파일 내용)
# - 서로 다른 마커를 사용해야 충돌 방지
```

**2. 변수 치환**
```bash
/home/${var.admin_username}/app.py

# Terraform 변수 var.admin_username이 "azureuser"면:
# /home/azureuser/app.py로 변환됨
```

**3. MySQL 연결 정보**
```python
conn = mysql.connector.connect(
    host="10.10.3.4",        # DB VM의 Private IP
    user="appuser",          # DB에서 생성할 사용자
    password="password123",  # DB 사용자 비밀번호
    database="appdb"         # DB에서 생성할 데이터베이스
)
```

**4. Flask 서버 설정**
```python
app.run(host="0.0.0.0", port=5000)

# host="0.0.0.0": 모든 네트워크 인터페이스에서 수신
#                (외부에서 접근 가능)
# port=5000: 포트 5000에서 리스닝
```

**5. 백그라운드 실행**
```bash
nohup python3 /home/azureuser/app.py &

# nohup: SSH 세션이 끊겨도 계속 실행
# &: 백그라운드에서 실행
```

#### 🔄 실행 흐름

```
VM 생성
  │
  ├─▶ apt update & install python3-pip
  │   └─▶ Python 3 및 pip 준비 완료
  │
  ├─▶ pip3 install flask mysql-connector-python
  │   └─▶ Flask 웹 프레임워크 설치
  │   └─▶ MySQL 클라이언트 라이브러리 설치
  │
  ├─▶ cat <<EOT > app.py
  │   └─▶ /home/azureuser/app.py 파일 생성
  │   └─▶ Flask 앱 코드 작성
  │
  ├─▶ chown azureuser:azureuser app.py
  │   └─▶ 파일 소유권 설정
  │
  └─▶ nohup python3 app.py &
      └─▶ Flask 앱 실행
      └─▶ 포트 5000에서 대기 중
```

### 3.5 DB VM: MySQL 자동 설치 및 설정

#### 📄 db.tf 코드 분석

```terraform
resource "azurerm_linux_virtual_machine" "db_vm" {
  # ... 기본 설정 ...
  
  custom_data = base64encode(<<EOF
#!/bin/bash

# 1. MySQL 서버 설치
apt update
apt install -y mysql-server

# 2. MySQL 서비스 시작
systemctl enable mysql
systemctl start mysql

# 3. 외부 접속 허용 설정
sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# 4. MySQL 재시작
systemctl restart mysql

# 5. 데이터베이스 및 사용자 생성
mysql -e "CREATE DATABASE appdb;"
mysql -e "CREATE USER 'appuser'@'10.10.2.%' IDENTIFIED BY 'password123';"
mysql -e "GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'10.10.2.%';"
mysql -e "FLUSH PRIVILEGES;"

EOF
  )
}
```

#### 🔍 코드 상세 해설

**1. MySQL 기본 설정**
```bash
systemctl enable mysql  # 부팅 시 자동 시작
systemctl start mysql   # 즉시 서비스 시작
```

**2. 외부 접속 허용**
```bash
sed -i "s/^bind-address.*/bind-address = 0.0.0.0/" /etc/mysql/mysql.conf.d/mysqld.cnf

# 설명:
# - MySQL은 기본적으로 127.0.0.1 (localhost)만 허용
# - bind-address를 0.0.0.0으로 변경하면 모든 IP에서 접속 가능
# - sed -i: 파일을 직접 수정 (in-place edit)
```

**기존 설정**:
```ini
bind-address = 127.0.0.1  # localhost만
```

**변경 후**:
```ini
bind-address = 0.0.0.0    # 모든 IP
```

**3. 데이터베이스 생성**
```bash
mysql -e "CREATE DATABASE appdb;"

# -e: SQL 명령어를 직접 실행
# appdb: 데이터베이스 이름
```

**4. 사용자 생성 및 권한 부여**
```bash
mysql -e "CREATE USER 'appuser'@'10.10.2.%' IDENTIFIED BY 'password123';"

# 'appuser': 사용자 이름
# '@10.10.2.%': 10.10.2.0/24 subnet에서만 접속 허용
#               (App subnet의 모든 IP)
# 'password123': 비밀번호
```

```bash
mysql -e "GRANT ALL PRIVILEGES ON appdb.* TO 'appuser'@'10.10.2.%';"

# appdb 데이터베이스의 모든 테이블(*)에 대한
# 모든 권한(SELECT, INSERT, UPDATE, DELETE 등)을
# appuser에게 부여
```

```bash
mysql -e "FLUSH PRIVILEGES;"

# 권한 변경사항을 즉시 적용
```

#### 🔐 보안 설정 분석

```sql
CREATE USER 'appuser'@'10.10.2.%' IDENTIFIED BY 'password123';

# ✅ '10.10.2.%': App subnet (10.10.2.0/24)에서만 접속 허용
# ❌ Internet에서 직접 접속 불가능
# ❌ Web subnet (10.10.1.0/24)에서도 접속 불가능

허용되는 IP:
- 10.10.2.0 ✅
- 10.10.2.1 ✅
- 10.10.2.4 ✅ (App VM)
- 10.10.2.255 ✅

차단되는 IP:
- 10.10.1.x ❌ (Web subnet)
- 0.0.0.0 ❌ (Internet)
```

#### 🔄 실행 흐름

```
DB VM 생성
  │
  ├─▶ MySQL 설치
  │   └─▶ apt install -y mysql-server
  │
  ├─▶ MySQL 시작
  │   └─▶ systemctl start mysql
  │
  ├─▶ 외부 접속 허용
  │   └─▶ bind-address = 0.0.0.0
  │   └─▶ systemctl restart mysql
  │
  └─▶ 데이터베이스 초기화
      ├─▶ CREATE DATABASE appdb
      ├─▶ CREATE USER 'appuser'@'10.10.2.%'
      ├─▶ GRANT ALL PRIVILEGES
      └─▶ FLUSH PRIVILEGES
      
✅ MySQL 준비 완료!
   - 데이터베이스: appdb
   - 사용자: appuser
   - 접속 허용: 10.10.2.0/24만
```

### 3.6 Custom Data 실행 타이밍

```
Timeline:

00:00  terraform apply 실행
       └─▶ Azure API 호출

00:30  VM 생성 시작
       ├─▶ 디스크 할당
       ├─▶ 네트워크 인터페이스 연결
       └─▶ OS 이미지 복사

01:00  VM 첫 부팅
       └─▶ Ubuntu 22.04 시작

01:30  Cloud-Init 시작 ⭐
       └─▶ custom_data 스크립트 실행
       
02:00  Custom Data 실행 중
       ├─▶ apt update (30초)
       ├─▶ apt install (1분)
       ├─▶ 서비스 시작 (10초)
       └─▶ 추가 설정 (10초)
       
02:30  모든 초기화 완료 ✅
       └─▶ 애플리케이션 실행 중

03:00  terraform apply 완료
       (custom_data는 백그라운드에서 계속 실행)
```

#### ⚠️ 중요한 포인트

```bash
# Terraform apply가 완료되어도
# custom_data 스크립트는 아직 실행 중일 수 있습니다!

terraform apply  # 완료 ✅
  │
  │ 하지만...
  │
  └─▶ VM 안에서 custom_data 실행 중 (진행 중 ⏳)

# 따라서 배포 후 5-10분 대기 필요
```

---

## 4. 실제 동작하는 서비스 🌐

### 4.1 전체 아키텍처 다이어그램

```
┌────────────────────────────────────────────────────────────────────────┐
│                            Internet                                     │
└────────────────────────────────┬───────────────────────────────────────┘
                                 │
                                 │ HTTP GET /
                                 │
                    ┌────────────▼────────────┐
                    │   Public IP             │
                    │   20.196.xxx.xxx        │
                    └────────────┬────────────┘
                                 │
                                 │
       ┌─────────────────────────┴─────────────────────────┐
       │                  Web Tier                         │
       │                  10.10.1.0/24                     │
       │                                                   │
       │  ┌─────────────────────────────────────────────┐  │
       │  │  Web VM (10.10.1.4)                        │  │
       │  │  ┌──────────────────────────────────────┐  │  │
       │  │  │  Nginx                               │  │  │
       │  │  │  - Listen: 0.0.0.0:80               │  │  │
       │  │  │  - Static files                      │  │  │
       │  │  │  - Reverse proxy                     │  │  │
       │  │  └──────────────────────────────────────┘  │  │
       │  └─────────────────────────────────────────────┘  │
       └───────────────────────┬──────────────────────────┘
                               │
                               │ HTTP GET http://10.10.2.4:5000/
                               │
       ┌───────────────────────▼──────────────────────────┐
       │                  App Tier                         │
       │                  10.10.2.0/24                     │
       │                                                   │
       │  ┌─────────────────────────────────────────────┐  │
       │  │  App VM (10.10.2.4)                        │  │
       │  │  ┌──────────────────────────────────────┐  │  │
       │  │  │  Flask Application                   │  │  │
       │  │  │  - Listen: 0.0.0.0:5000             │  │  │
       │  │  │  - Route: GET /                      │  │  │
       │  │  │  - Business Logic                    │  │  │
       │  │  └──────────────────────────────────────┘  │  │
       │  └─────────────────────────────────────────────┘  │
       └───────────────────────┬──────────────────────────┘
                               │
                               │ MySQL Query
                               │ SELECT 1
                               │
       ┌───────────────────────▼──────────────────────────┐
       │                  DB Tier                          │
       │                  10.10.3.0/24                     │
       │                                                   │
       │  ┌─────────────────────────────────────────────┐  │
       │  │  DB VM (10.10.3.4)                         │  │
       │  │  ┌──────────────────────────────────────┐  │  │
       │  │  │  MySQL Server                        │  │  │
       │  │  │  - Listen: 0.0.0.0:3306             │  │  │
       │  │  │  - Database: appdb                   │  │  │
       │  │  │  - User: appuser@10.10.2.%          │  │  │
       │  │  └──────────────────────────────────────┘  │  │
       │  └─────────────────────────────────────────────┘  │
       └───────────────────────────────────────────────────┘
```

### 4.2 데이터 흐름 상세

#### 📊 Request Flow (요청 흐름)

```
Step 1: 사용자 요청
──────────────────
curl http://20.196.xxx.xxx/

Internet → Azure Public IP
           └─▶ NAT to 10.10.1.4:80


Step 2: Web 계층 처리
──────────────────
Web VM (Nginx)
├─▶ 요청 수신: 10.10.1.4:80
├─▶ 정적 파일 확인
│   └─▶ 없음 (기본 Nginx 페이지만)
└─▶ 응답 반환: "Welcome to nginx!"

또는 Nginx를 Reverse Proxy로 설정했다면:
├─▶ 프록시 요청: http://10.10.2.4:5000/
└─▶ App 계층으로 전달


Step 3: App 계층 처리
──────────────────
App VM (Flask)
├─▶ 요청 수신: GET / @ 10.10.2.4:5000
├─▶ hello() 함수 실행
├─▶ MySQL 연결 생성
│   └─▶ mysql.connector.connect(
│         host="10.10.3.4",
│         user="appuser",
│         password="password123",
│         database="appdb"
│       )
└─▶ DB 쿼리 실행


Step 4: DB 계층 처리
──────────────────
DB VM (MySQL)
├─▶ 연결 수신: 10.10.2.4 → 10.10.3.4:3306
├─▶ 인증 확인
│   └─▶ appuser@10.10.2.% OK ✅
├─▶ 쿼리 실행: SELECT 1
└─▶ 결과 반환: (1,)


Step 5: 응답 역방향 전달
──────────────────
DB VM → App VM
        ├─▶ result = (1,)
        └─▶ return f"DB Connected: {result}"

App VM → Web VM
        └─▶ "DB Connected: (1,)"

Web VM → Internet
        └─▶ 사용자에게 응답
```

### 4.3 포트와 프로토콜 매핑

```
┌───────────┬──────────┬──────────┬─────────────────────────────┐
│ 계층      │ VM IP    │ 포트     │ 서비스                       │
├───────────┼──────────┼──────────┼─────────────────────────────┤
│ Web       │ 10.10.1.4│ 80       │ Nginx (HTTP)                │
│           │          │ 22       │ SSH                          │
├───────────┼──────────┼──────────┼─────────────────────────────┤
│ App       │ 10.10.2.4│ 5000     │ Flask (Python Web Framework)│
│           │          │ 22       │ SSH                          │
├───────────┼──────────┼──────────┼─────────────────────────────┤
│ DB        │ 10.10.3.4│ 3306     │ MySQL                        │
│           │          │ 22       │ SSH                          │
└───────────┴──────────┴──────────┴─────────────────────────────┘
```

### 4.4 NSG 규칙과 트래픽 허용

#### 🔒 Web NSG (10.10.1.0/24)

```terraform
security_rule {
  name                       = "Allow-HTTP"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_address_prefix      = "*"              # 모든 곳
  destination_port_range     = "80"
  destination_address_prefix = "*"
  source_port_range          = "*"
}

security_rule {
  name                       = "Allow-SSH"
  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_address_prefix      = "*"              # 모든 곳
  destination_port_range     = "22"
  destination_address_prefix = "*"
  source_port_range          = "*"
}
```

**허용되는 트래픽**:
```
✅ Internet → Web VM:80 (HTTP)
✅ Internet → Web VM:22 (SSH)
❌ Internet → Web VM:다른 포트 (차단)
```

#### 🔒 App NSG (10.10.2.0/24)

```terraform
security_rule {
  name                       = "Allow-Web-5000"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_address_prefix      = "10.10.1.0/24"   # Web subnet만
  destination_port_range     = "5000"
  destination_address_prefix = "*"
  source_port_range          = "*"
}

security_rule {
  name                       = "Allow-SSH-From-Web-Subnet"
  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "10.10.1.0/24"   # Web subnet만
  destination_address_prefix = "*"
}
```

**허용되는 트래픽**:
```
✅ Web VM (10.10.1.4) → App VM:5000
✅ Web VM (10.10.1.4) → App VM:22
❌ Internet → App VM:5000 (차단)
❌ DB VM (10.10.3.4) → App VM:5000 (차단)
```

#### 🔒 DB NSG (10.10.3.0/24)

```terraform
security_rule {
  name                       = "Allow-App-3306"
  priority                   = 100
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_address_prefix      = "10.10.2.0/24"   # App subnet만
  destination_port_range     = "3306"
  destination_address_prefix = "*"
  source_port_range          = "*"
}

security_rule {
  name                       = "Allow-SSH-From-App-Subnet"
  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_port_range          = "*"
  destination_port_range     = "22"
  source_address_prefix      = "10.10.2.0/24"   # App subnet만
  destination_address_prefix = "*"
}
```

**허용되는 트래픽**:
```
✅ App VM (10.10.2.4) → DB VM:3306
✅ App VM (10.10.2.4) → DB VM:22
❌ Internet → DB VM:3306 (차단)
❌ Web VM (10.10.1.4) → DB VM:3306 (차단) ⚠️ 중요!
```

### 4.5 보안 정책 분석

```
Internet (외부)
    │
    │ ❌ 차단: 8080, 5000, 3306 (App, DB 포트)
    │ ✅ 허용: 80, 22 (Web 포트)
    │
    ▼
┌─────────────────────────────────┐
│ Web Tier (DMZ)                  │
│ - Public IP 있음                │
│ - 외부 노출                      │
│ - HTTP(80), SSH(22) 개방        │
└─────────┬───────────────────────┘
          │
          │ ❌ 차단: Internet → App:5000
          │ ✅ 허용: Web → App:5000, 22
          │
          ▼
┌─────────────────────────────────┐
│ App Tier (내부)                 │
│ - Private IP만                  │
│ - Web에서만 접근 가능            │
│ - 5000, 22 (Web subnet)         │
└─────────┬───────────────────────┘
          │
          │ ❌ 차단: Internet/Web → DB:3306
          │ ✅ 허용: App → DB:3306, 22
          │
          ▼
┌─────────────────────────────────┐
│ DB Tier (최고 보안)             │
│ - Private IP만                  │
│ - App에서만 접근 가능            │
│ - 3306, 22 (App subnet)         │
└─────────────────────────────────┘
```

---

## 5. 코드 상세 분석 📝

### 5.1 main.tf - 시작점

```terraform
resource "azurerm_resource_group" "rg" {
  name     = "rg-3tier-service-pratice"
  location = var.location
}
```

**역할**:
- 모든 리소스를 담을 Resource Group 생성
- 다른 모든 리소스가 이것을 참조

**참조하는 리소스**:
```terraform
# vnet.tf
resource_group_name = azurerm_resource_group.rg.name
location            = azurerm_resource_group.rg.location

# nsg.tf, web.tf, app.tf, db.tf 모두 동일하게 참조
```

### 5.2 variables.tf - 변수 정의

```terraform
variable "location" {
  default = "Korea Central"
}

variable "admin_username" {
  default = "azureuser"
}

variable "admin_password" {
  default = "Password1234!"
}
```

#### 🎯 변수 사용 목적

**1. location 변수**
```terraform
# 나쁜 예: 하드코딩
location = "Korea Central"  # 여러 곳에 반복

# 좋은 예: 변수 사용
location = var.location  # 한 곳에서 관리
```

**2. admin_username, admin_password 변수**
```terraform
# VM 생성 시
admin_username = var.admin_username
admin_password = var.admin_password

# Custom data에서
/home/${var.admin_username}/app.py
```

#### 🔐 보안 개선 방법

```terraform
# ⚠️ 현재: 기본값에 하드코딩 (안전하지 않음)
variable "admin_password" {
  default = "Password1234!"
}

# ✅ 개선 1: 기본값 제거, 실행 시 입력
variable "admin_password" {
  description = "Admin password for VMs"
  sensitive   = true
}

# 사용:
terraform apply
# var.admin_password
#   Enter a value: __________ (입력 시 숨김)

# ✅ 개선 2: terraform.tfvars 파일 사용
admin_password = "SecurePassword!@#"

# .gitignore에 추가
echo "terraform.tfvars" >> .gitignore

# ✅ 개선 3: 환경 변수 사용
export TF_VAR_admin_password="SecurePassword!@#"
terraform apply
```

### 5.3 outputs.tf - 출력 값

```terraform
output "web_public_ip" {
  value = azurerm_public_ip.web_pip.ip_address
}
```

#### 📤 Output의 용도

**1. 배포 후 정보 확인**
```bash
terraform apply

# ...배포 중...

Outputs:

web_public_ip = "20.196.123.45"

# ✅ Public IP를 복사해서 브라우저에 입력!
```

**2. 다른 Terraform 프로젝트에서 사용**
```terraform
# 다른 프로젝트에서
data "terraform_remote_state" "network" {
  backend = "azurerm"
  config = {
    # ... 설정 ...
  }
}

# Output 값 참조
web_ip = data.terraform_remote_state.network.outputs.web_public_ip
```

**3. 스크립트에서 사용**
```bash
# Output 값을 JSON으로 추출
terraform output -json > outputs.json

# jq로 파싱
WEB_IP=$(terraform output -json | jq -r '.web_public_ip.value')

# 자동으로 SSH 접속
ssh azureuser@$WEB_IP
```

#### 💡 유용한 Outputs 추가

```terraform
# outputs.tf 확장

output "web_public_ip" {
  value       = azurerm_public_ip.web_pip.ip_address
  description = "Web VM의 Public IP 주소"
}

output "web_ssh_command" {
  value       = "ssh ${var.admin_username}@${azurerm_public_ip.web_pip.ip_address}"
  description = "Web VM SSH 접속 명령어"
}

output "app_private_ip" {
  value       = azurerm_network_interface.app_nic.private_ip_address
  description = "App VM의 Private IP"
}

output "db_private_ip" {
  value       = azurerm_network_interface.db_nic.private_ip_address
  description = "DB VM의 Private IP"
}

output "mysql_connection_string" {
  value       = "mysql -h ${azurerm_network_interface.db_nic.private_ip_address} -u appuser -p appdb"
  description = "MySQL 접속 명령어"
  sensitive   = true  # 비밀번호가 포함되어 있으면 sensitive로 표시
}
```

**사용 예시**:
```bash
terraform apply

Outputs:

app_private_ip = "10.10.2.4"
db_private_ip = "10.10.3.4"
mysql_connection_string = <sensitive>
web_public_ip = "20.196.123.45"
web_ssh_command = "ssh azureuser@20.196.123.45"

# 복사해서 바로 실행
ssh azureuser@20.196.123.45
```

### 5.4 vnet.tf - 네트워크 토폴로지

```terraform
resource "azurerm_virtual_network" "vnet" {
  name                = "vnet-3tier"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  address_space       = ["10.10.0.0/16"]  # 65,536개 IP
}

resource "azurerm_subnet" "web" {
  name                 = "web-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.1.0/24"]  # 256개 IP
}

resource "azurerm_subnet" "app" {
  name                 = "app-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.2.0/24"]  # 256개 IP
}

resource "azurerm_subnet" "db" {
  name                 = "db-subnet"
  resource_group_name  = azurerm_resource_group.rg.name
  virtual_network_name = azurerm_virtual_network.vnet.name
  address_prefixes     = ["10.10.3.0/24"]  # 256개 IP
}
```

#### 📊 IP 주소 계획

```
VNet: 10.10.0.0/16
├─▶ 10.10.0.0 ~ 10.10.255.255
├─▶ 총 65,536개 IP 주소
│
├─▶ Subnet: web (10.10.1.0/24)
│   ├─▶ 10.10.1.0 ~ 10.10.1.255
│   ├─▶ 254개 사용 가능 IP
│   └─▶ 예약된 IP:
│       ├─▶ 10.10.1.0: Network Address
│       ├─▶ 10.10.1.1: Gateway
│       ├─▶ 10.10.1.2: Azure DNS
│       ├─▶ 10.10.1.3: Azure DNS
│       └─▶ 10.10.1.255: Broadcast
│
├─▶ Subnet: app (10.10.2.0/24)
│   └─▶ 10.10.2.0 ~ 10.10.2.255
│
└─▶ Subnet: db (10.10.3.0/24)
    └─▶ 10.10.3.0 ~ 10.10.3.255
```

### 5.5 nsg.tf - 보안 규칙 집중 관리

#### 특징

```terraform
# NSG에 security_rule 블록을 직접 포함
resource "azurerm_network_security_group" "web_nsg" {
  name                = "web-nsg"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name

  security_rule {  # ← NSG 내부에 규칙
    name                       = "Allow-HTTP"
    priority                   = 100
    # ...
  }

  security_rule {  # ← 여러 규칙 가능
    name                       = "Allow-SSH"
    priority                   = 110
    # ...
  }
}
```

#### 🆚 다른 방식과 비교

**방식 1: NSG 내부에 규칙 포함 (현재 사용 중)**
```terraform
resource "azurerm_network_security_group" "web_nsg" {
  security_rule {
    name = "Allow-HTTP"
    # ...
  }
}

# 장점: 규칙과 NSG가 함께 있어 보기 편함
# 단점: 규칙 추가 시 NSG 전체 재생성 가능
```

**방식 2: 별도의 리소스로 규칙 정의 (4-3tier-architecture에서 사용)**
```terraform
resource "azurerm_network_security_group" "web_nsg" {
  name = "web-nsg"
  # 규칙 없음
}

resource "azurerm_network_security_rule" "web_http" {
  name                        = "allow-http"
  network_security_group_name = azurerm_network_security_group.web_nsg.name
  priority                    = 100
  # ...
}

# 장점: 규칙만 독립적으로 수정 가능
# 단점: 코드가 더 길고 분산됨
```

#### 🔐 SSH 규칙 추가 이유

```terraform
security_rule {
  name                       = "Allow-SSH"
  priority                   = 110
  direction                  = "Inbound"
  access                     = "Allow"
  protocol                   = "Tcp"
  source_address_prefix      = "*"
  destination_port_range     = "22"
  destination_address_prefix = "*"
  source_port_range          = "*"
}
```

**목적**:
- VM 접속해서 로그 확인
- Custom data 스크립트 실행 상태 확인
- 애플리케이션 디버깅
- 수동 설정 변경

**⚠️ 프로덕션에서는**:
```terraform
# 특정 IP에서만 SSH 허용
source_address_prefix = "1.2.3.4/32"  # 관리자 IP만

# 또는 Bastion Host 사용
# SSH를 완전히 차단하고 Azure Bastion으로 접속
```

### 5.6 web.tf / app.tf / db.tf - 계층별 리소스

각 파일이 **하나의 티어(Tier)를 완전히 정의**합니다.

#### 패턴

```
web.tf
├─▶ Public IP (외부 접근용)
├─▶ Network Interface (IP 연결)
└─▶ Virtual Machine (컴퓨팅 + 애플리케이션)

app.tf
├─▶ Network Interface (Private only)
└─▶ Virtual Machine (Flask 앱)

db.tf
├─▶ Network Interface (Private only)
└─▶ Virtual Machine (MySQL)
```

#### 의존성 체인

```terraform
# web.tf
azurerm_public_ip.web_pip
    │
    ├─▶ azurerm_network_interface.web_nic
    │       public_ip_address_id = azurerm_public_ip.web_pip.id
    │       subnet_id = azurerm_subnet.web.id (vnet.tf)
    │
    └─▶ azurerm_linux_virtual_machine.web_vm
            network_interface_ids = [azurerm_network_interface.web_nic.id]
```

---

## 6. 배포 및 테스트 🚀

### 6.1 배포 단계별 가이드

#### Step 1: 코드 검증

```bash
# 1. 작업 디렉토리로 이동
cd 5-3tier-service/

# 2. Terraform 초기화
terraform init

# 출력:
# Initializing the backend...
# Initializing provider plugins...
# - Finding hashicorp/azurerm versions matching "~> 3.0"...
# - Installing hashicorp/azurerm v3.117.1...
# Terraform has been successfully initialized!

# 3. 코드 포맷 확인
terraform fmt

# 4. 코드 검증
terraform validate

# 출력:
# Success! The configuration is valid.
```

#### Step 2: 실행 계획 확인

```bash
terraform plan

# 출력 예시:
Terraform will perform the following actions:

  # azurerm_linux_virtual_machine.app_vm will be created
  + resource "azurerm_linux_virtual_machine" "app_vm" {
      + admin_password                  = (sensitive value)
      + admin_username                  = "azureuser"
      + name                            = "app-vm"
      + size                            = "Standard_B1s"
      # ... 기타 속성 ...
    }

  # ... 더 많은 리소스 ...

Plan: 21 to add, 0 to change, 0 to destroy.

Changes to Outputs:
  + web_public_ip = (known after apply)
```

**확인 사항**:
- ✅ 21개 리소스 생성 예정
- ✅ sensitive value로 비밀번호 숨김
- ✅ Public IP는 생성 후 결정됨

#### Step 3: 리소스 생성

```bash
terraform apply

# 확인 메시지
Do you want to perform these actions?
  Terraform will perform the actions described above.
  Only 'yes' will be accepted to approve.

  Enter a value: yes  ← 입력

# 배포 시작...
azurerm_resource_group.rg: Creating...
azurerm_resource_group.rg: Creation complete after 1s

azurerm_virtual_network.vnet: Creating...
azurerm_public_ip.web_pip: Creating...

# ... 진행 상황 ...

azurerm_linux_virtual_machine.web_vm: Still creating... [40s elapsed]
azurerm_linux_virtual_machine.app_vm: Still creating... [40s elapsed]

# ... 3-5분 후 ...

Apply complete! Resources: 21 added, 0 changed, 0 destroyed.

Outputs:

web_public_ip = "20.196.123.45"
```

#### Step 4: 배포 상태 확인

```bash
# 1. 생성된 리소스 목록
terraform state list

# 출력:
azurerm_linux_virtual_machine.app_vm
azurerm_linux_virtual_machine.db_vm
azurerm_linux_virtual_machine.web_vm
azurerm_network_interface.app_nic
azurerm_network_interface.db_nic
azurerm_network_interface.web_nic
# ... 등등 ...

# 2. 특정 리소스 상세 정보
terraform state show azurerm_linux_virtual_machine.web_vm

# 3. Output 값 재확인
terraform output

# 출력:
web_public_ip = "20.196.123.45"
```

### 6.2 애플리케이션 테스트

#### ⏱️ 중요: 초기화 대기 시간

```bash
# Terraform apply가 완료되어도
# Custom data 스크립트는 백그라운드에서 실행 중입니다.

# 권장 대기 시간:
# - Web VM: 2-3분 (Nginx 설치)
# - App VM: 3-5분 (Python, Flask 설치 및 앱 실행)
# - DB VM: 3-5분 (MySQL 설치 및 설정)

# 전체 스택이 준비되기까지: 5-10분
```

#### 🧪 Test 1: Web VM (Nginx)

```bash
# Public IP 확인
WEB_IP=$(terraform output -raw web_public_ip)
echo $WEB_IP

# HTTP 요청
curl http://$WEB_IP

# 예상 출력:
<!DOCTYPE html>
<html>
<head>
<title>Welcome to nginx!</title>
<style>
    body {
        width: 35em;
        margin: 0 auto;
        font-family: Tahoma, Verdana, Arial, sans-serif;
    }
</style>
</head>
<body>
<h1>Welcome to nginx!</h1>
<p>If you see this page, the nginx web server is successfully installed and
working. Further configuration is required.</p>
# ...
</body>
</html>

# ✅ Nginx가 정상적으로 실행 중!
```

**브라우저 테스트**:
```
http://20.196.123.45

→ Nginx 기본 페이지 표시됨
```

#### 🧪 Test 2: SSH 접속 및 내부 확인

```bash
# Web VM 접속
ssh azureuser@$WEB_IP
# Password: Password1234!

# Nginx 상태 확인
systemctl status nginx

# 출력:
● nginx.service - A high performance web server and a reverse proxy server
     Loaded: loaded (/lib/systemd/system/nginx.service; enabled; vendor preset: enabled)
     Active: active (running) since ...

# 로그 확인
sudo tail -f /var/log/cloud-init-output.log

# Custom data 실행 로그를 볼 수 있음
```

#### 🧪 Test 3: App VM 확인 (Web VM을 통해)

```bash
# Web VM에서 App VM으로 접속
ssh azureuser@10.10.2.4
# Password: Password1234!

# Flask 앱 프로세스 확인
ps aux | grep python3

# 출력:
azureuser  1234  0.0  5.5  123456  12345 ?  S  12:34  0:01 python3 /home/azureuser/app.py

# Flask 앱 파일 확인
cat /home/azureuser/app.py

# Flask 앱 테스트
curl http://localhost:5000/

# 예상 출력:
DB Connected: (1,)

# ✅ Flask 앱이 DB에 성공적으로 연결!
```

#### 🧪 Test 4: DB VM 확인 (App VM을 통해)

```bash
# App VM에서 DB VM으로 접속
ssh azureuser@10.10.3.4
# Password: Password1234!

# MySQL 상태 확인
systemctl status mysql

# 출력:
● mysql.service - MySQL Community Server
     Loaded: loaded (/lib/systemd/system/mysql.service; enabled; vendor preset: enabled)
     Active: active (running) since ...

# MySQL 접속
mysql -u appuser -p -h 10.10.3.4
# Password: password123

# MySQL 프롬프트에서
mysql> SHOW DATABASES;
+--------------------+
| Database           |
+--------------------+
| appdb              |
| information_schema |
+--------------------+

mysql> USE appdb;
mysql> CREATE TABLE test (id INT, name VARCHAR(50));
mysql> INSERT INTO test VALUES (1, 'Hello from DB!');
mysql> SELECT * FROM test;
+------+----------------+
| id   | name           |
+------+----------------+
|    1 | Hello from DB! |
+------+----------------+

# ✅ MySQL이 정상 작동!
```

#### 🧪 Test 5: 전체 스택 통합 테스트

```bash
# 로컬 터미널에서
WEB_IP=$(terraform output -raw web_public_ip)

# 1. Web VM에서 App VM으로 요청 (from Web VM)
ssh azureuser@$WEB_IP "curl http://10.10.2.4:5000/"

# 예상 출력:
DB Connected: (1,)

# 2. 네트워크 연결 확인
ssh azureuser@$WEB_IP "curl -v http://10.10.2.4:5000/"

# 출력 분석:
* Trying 10.10.2.4:5000...
* Connected to 10.10.2.4 (10.10.2.4) port 5000 (#0)
> GET / HTTP/1.1
> Host: 10.10.2.4:5000
< HTTP/1.1 200 OK
< Content-Type: text/html; charset=utf-8
DB Connected: (1,)

# ✅ 전체 3-Tier 스택이 정상 작동!
```

### 6.3 저장 및 정리

#### 📁 상태 파일 확인

```bash
# terraform.tfstate 파일 생성됨
ls -lh terraform.tfstate

# 크기: 약 50-100KB
# 내용: 21개 리소스의 모든 정보 (JSON 형식)

# 백업 파일도 자동 생성
ls -lh terraform.tfstate.backup
```

#### 🗑️ 리소스 삭제

```bash
# 모든 리소스 삭제
terraform destroy

# 확인 메시지
Do you really want to destroy all resources?
  Terraform will destroy all your managed infrastructure, as shown above.
  There is no undo. Only 'yes' will be accepted to confirm.

  Enter a value: yes  ← 입력

# 삭제 진행...
azurerm_linux_virtual_machine.web_vm: Destroying...
azurerm_linux_virtual_machine.app_vm: Destroying...
# ... 5-10분 후 ...

Destroy complete! Resources: 21 destroyed.
```

---

## 7. 실무 베스트 프랙티스 💡

### 7.1 파일 구조 Best Practices

#### ✅ 권장 구조

```
프로젝트/
├── main.tf           # Resource Group, 프로젝트 진입점
├── variables.tf      # 모든 변수 정의
├── outputs.tf        # 모든 출력 값
├── provider.tf       # Provider 설정
├── network.tf        # VNet, Subnet
├── security.tf       # NSG, 방화벽 규칙
├── compute-web.tf    # Web tier
├── compute-app.tf    # App tier
├── compute-db.tf     # DB tier
├── terraform.tfvars  # 변수 값 (Git에 포함 안 함)
├── .gitignore        # Terraform 파일 제외
└── README.md         # 문서
```

#### ❌ 피해야 할 구조

```
나쁜 예 1: 너무 많은 분리
├── web-pip.tf
├── web-nic.tf
├── web-vm.tf
├── app-nic.tf
├── app-vm.tf
└── ... (파일 20개)
→ 관리 어려움, 파일 찾기 힘듦

나쁜 예 2: 분리 안 함
└── main.tf (500줄)
→ 가독성 낮음, 협업 어려움

나쁜 예 3: 의미 없는 이름
├── resources1.tf
├── resources2.tf
└── stuff.tf
→ 파일 이름만 봐도 내용 예측 안 됨
```

### 7.2 Variables 관리

#### 🎛️ 변수 타입 활용

```terraform
# variables.tf

# 1. 단순 문자열
variable "location" {
  type        = string
  default     = "Korea Central"
  description = "Azure region"
}

# 2. 숫자
variable "vm_count" {
  type        = number
  default     = 3
  description = "Number of VMs per tier"
}

# 3. Boolean
variable "enable_public_ip" {
  type        = bool
  default     = true
  description = "Enable public IP for web tier"
}

# 4. 리스트
variable "allowed_ip_ranges" {
  type        = list(string)
  default     = ["1.2.3.4/32", "5.6.7.8/32"]
  description = "IP ranges allowed for SSH"
}

# 5. 맵 (딕셔너리)
variable "vm_sizes" {
  type = map(string)
  default = {
    web = "Standard_B1s"
    app = "Standard_B2s"
    db  = "Standard_B2ms"
  }
  description = "VM sizes per tier"
}

# 6. 객체
variable "web_config" {
  type = object({
    vm_size    = string
    disk_size  = number
    enable_pip = bool
  })
  default = {
    vm_size    = "Standard_B1s"
    disk_size  = 30
    enable_pip = true
  }
}
```

#### 🔒 민감한 정보 관리

```terraform
# 1. sensitive 속성 사용
variable "admin_password" {
  type        = string
  sensitive   = true
  description = "Admin password for VMs"
}

# terraform plan/apply 시 값이 숨겨짐:
# admin_password = (sensitive value)

# 2. Azure Key Vault 사용
data "azurerm_key_vault_secret" "admin_password" {
  name         = "vm-admin-password"
  key_vault_id = azurerm_key_vault.main.id
}

resource "azurerm_linux_virtual_machine" "example" {
  admin_password = data.azurerm_key_vault_secret.admin_password.value
  # ...
}

# 3. 환경 변수 사용
# export TF_VAR_admin_password="SecurePassword"
# terraform apply
```

### 7.3 Custom Data Best Practices

#### ✅ 권장 사항

**1. Idempotency (멱등성) 보장**
```bash
# 나쁜 예: 재실행 시 오류
apt install -y nginx
mysql -e "CREATE DATABASE appdb;"  # 이미 있으면 에러

# 좋은 예: 재실행 가능
apt install -y nginx  # apt는 이미 설치되어 있으면 스킵
mysql -e "CREATE DATABASE IF NOT EXISTS appdb;"  # 조건부 생성
```

**2. 로그 남기기**
```bash
#!/bin/bash
set -x  # 모든 명령어 출력
exec > >(tee /var/log/custom-data.log)  # 로그 파일에 저장
exec 2>&1

echo "Starting custom data script..."
apt update
apt install -y nginx
echo "Custom data script completed!"
```

**3. 오류 처리**
```bash
#!/bin/bash
set -e  # 오류 발생 시 중단

# 함수로 오류 처리
install_nginx() {
    if ! apt install -y nginx; then
        echo "Failed to install nginx" >> /var/log/custom-data-error.log
        return 1
    fi
}

install_nginx || exit 1
```

**4. 외부 스크립트 사용**
```terraform
# 나쁜 예: custom_data에 긴 스크립트
custom_data = base64encode(<<EOF
#!/bin/bash
# ... 200줄의 스크립트 ...
EOF
)

# 좋은 예: 외부 파일 참조
custom_data = base64encode(file("${path.module}/scripts/web-init.sh"))

# scripts/web-init.sh 파일에 스크립트 작성
```

#### ❌ 피해야 할 패턴

```bash
# 1. 하드코딩된 IP
mysql -e "... host='10.10.3.4' ..."
# → 변수나 자동 검색 사용

# 2. 비밀번호 노출
mysql -e "... password='password123' ..."
# → Key Vault나 환경 변수 사용

# 3. 타임아웃 없는 다운로드
wget http://example.com/large-file.tar.gz
# → wget --timeout=30 사용

# 4. 실패해도 계속 진행
apt install package-that-does-not-exist  # 실패
systemctl start myapp  # 실행되지만 앱이 설치 안 됨
# → set -e 사용
```

### 7.4 모듈화 (다음 단계)

현재는 모든 코드가 한 디렉토리에 있지만, 큰 프로젝트에서는 **모듈**로 분리합니다.

```
modules/
├── network/
│   ├── main.tf       # VNet, Subnet
│   ├── variables.tf
│   └── outputs.tf
│
├── vm/
│   ├── main.tf       # VM, NIC
│   ├── variables.tf
│   └── outputs.tf
│
└── nsg/
    ├── main.tf       # NSG, Rules
    ├── variables.tf
    └── outputs.tf

main.tf:
module "network" {
  source = "./modules/network"
  location = "Korea Central"
}

module "web_vm" {
  source    = "./modules/vm"
  tier      = "web"
  subnet_id = module.network.web_subnet_id
}
```

### 7.5 Remote State (팀 작업)

```terraform
# backend.tf
terraform {
  backend "azurerm" {
    resource_group_name  = "terraform-state-rg"
    storage_account_name = "tfstateXXXXX"
    container_name       = "tfstate"
    key                  = "3tier-service.tfstate"
  }
}

# 효과:
# - terraform.tfstate가 Azure Storage에 저장
# - 여러 명이 동시 작업 가능
# - State Lock으로 충돌 방지
```

---

## 8. 트러블슈팅 🔧

### 8.1 일반적인 문제와 해결

#### 🐛 문제 1: Custom Data가 실행 안 됨

**증상**:
```bash
curl http://<web-ip>
# 응답 없음 또는 Connection refused
```

**원인**:
- Custom data 스크립트가 아직 실행 중
- 스크립트 오류로 실패

**해결**:
```bash
# 1. SSH 접속
ssh azureuser@<web-ip>

# 2. Cloud-init 로그 확인
sudo tail -100 /var/log/cloud-init-output.log

# 확인할 내용:
# - apt update 성공?
# - apt install nginx 성공?
# - systemctl start nginx 성공?

# 3. Cloud-init 상태 확인
cloud-init status

# 출력:
# status: done  ← 완료
# status: running  ← 아직 실행 중
# status: error  ← 오류 발생

# 4. Nginx 상태 직접 확인
systemctl status nginx

# 5. 수동으로 시작
sudo systemctl start nginx
```

#### 🐛 문제 2: App VM이 DB에 연결 안 됨

**증상**:
```bash
curl http://10.10.2.4:5000/
# 응답 없음 또는 DB 연결 오류
```

**원인**:
- DB VM의 MySQL이 아직 시작 안 됨
- 네트워크 규칙 문제
- MySQL 사용자 권한 문제

**해결**:
```bash
# 1. DB VM에 접속 (App VM을 통해)
ssh azureuser@10.10.2.4  # App VM
ssh azureuser@10.10.3.4  # DB VM

# 2. MySQL 상태 확인
systemctl status mysql

# 3. MySQL 포트 리스닝 확인
sudo netstat -tlnp | grep 3306

# 출력:
tcp  0  0  0.0.0.0:3306  0.0.0.0:*  LISTEN  1234/mysqld
#           ^^^^^^^^
#           0.0.0.0이어야 외부 접속 가능

# 4. MySQL에 직접 접속해서 사용자 확인
mysql -u root

mysql> SELECT user, host FROM mysql.user;
+------------------+-----------+
| user             | host      |
+------------------+-----------+
| appuser          | 10.10.2.% |  ← 있어야 함
+------------------+-----------+

# 5. App VM에서 연결 테스트
mysql -h 10.10.3.4 -u appuser -ppassword123 appdb

# 성공하면:
mysql> SELECT 1;
+---+
| 1 |
+---+
| 1 |
+---+
```

#### 🐛 문제 3: SSH 접속 안 됨

**증상**:
```bash
ssh azureuser@<ip>
# Connection refused 또는 Permission denied
```

**원인**:
- NSG에 SSH 규칙 없음
- VM이 아직 부팅 중
- 비밀번호 인증 비활성화

**해결**:
```bash
# 1. NSG 규칙 확인
az network nsg rule list \
  --resource-group rg-3tier-service-pratice \
  --nsg-name web-nsg \
  --output table

# Allow-SSH 규칙이 있는지 확인

# 2. VM 상태 확인 (Azure Portal 또는 CLI)
az vm get-instance-view \
  --resource-group rg-3tier-service-pratice \
  --name web-vm \
  --query instanceView.statuses[1] \
  --output table

# PowerState/running이어야 함

# 3. Network connectivity 확인
telnet <ip> 22

# 응답 있으면 방화벽 문제 아님

# 4. Azure Serial Console 사용 (Azure Portal)
# VM → Help → Serial console
# 직접 콘솔로 접속 가능
```

#### 🐛 문제 4: Terraform Plan 오류

**증상**:
```bash
terraform plan

Error: Insufficient subnet_id argument
  on app.tf line 10, in resource "azurerm_network_interface" "app_nic":
  10:   subnet_id = azurerm_subnet.app.id
```

**원인**:
- Typo in resource name
- vnet.tf 파일을 만들지 않음

**해결**:
```bash
# 1. 리소스 이름 확인
grep "resource \"azurerm_subnet\"" vnet.tf

# 출력:
resource "azurerm_subnet" "app" {
#                          ^^^
# 이름이 정확히 일치해야 함

# 2. 파일 존재 확인
ls -la *.tf

# 3. Terraform init 재실행
terraform init

# 4. 문법 검증
terraform validate
```

### 8.2 디버깅 팁

#### 🔍 Terraform 디버그 모드

```bash
# 상세 로그 출력
export TF_LOG=DEBUG
terraform apply

# 로그를 파일에 저장
export TF_LOG=DEBUG
export TF_LOG_PATH=./terraform.log
terraform apply

# 로그 레벨:
# TRACE (가장 상세)
# DEBUG
# INFO
# WARN
# ERROR
```

#### 🔍 리소스 직접 확인

```bash
# 1. Azure CLI로 리소스 확인
az vm list \
  --resource-group rg-3tier-service-pratice \
  --output table

# 2. 특정 VM 상세 정보
az vm show \
  --resource-group rg-3tier-service-pratice \
  --name web-vm

# 3. NSG 규칙 확인
az network nsg rule list \
  --resource-group rg-3tier-service-pratice \
  --nsg-name web-nsg \
  --output table

# 4. Public IP 확인
az network public-ip show \
  --resource-group rg-3tier-service-pratice \
  --name web-pip \
  --query ipAddress \
  --output tsv
```

#### 🔍 네트워크 연결 테스트

```bash
# Web VM에서
# 1. App VM으로 ping
ping 10.10.2.4

# 2. App VM 포트 테스트
telnet 10.10.2.4 5000
# 또는
nc -zv 10.10.2.4 5000

# 3. HTTP 요청
curl -v http://10.10.2.4:5000/

# 4. DNS 확인
nslookup google.com
```

### 8.3 일반적인 실수

#### ❌ 실수 1: Custom data에서 sudo 사용

```bash
# 나쁜 예:
custom_data = base64encode(<<EOF
#!/bin/bash
sudo apt update  # 불필요!
sudo apt install nginx
EOF
)

# 좋은 예:
custom_data = base64encode(<<EOF
#!/bin/bash
apt update  # Custom data는 이미 root 권한
apt install nginx
EOF
)
```

**이유**: Custom data 스크립트는 **root 권한**으로 실행됩니다.

#### ❌ 실수 2: Subnet CIDR 중복

```terraform
# 나쁜 예:
resource "azurerm_subnet" "web" {
  address_prefixes = ["10.10.1.0/24"]
}

resource "azurerm_subnet" "app" {
  address_prefixes = ["10.10.1.0/24"]  # 중복!
}

# 오류: CIDR range overlaps
```

#### ❌ 실수 3: 순환 참조

```terraform
# 나쁜 예:
resource "azurerm_network_interface" "a" {
  subnet_id = azurerm_subnet.b.id
}

resource "azurerm_subnet" "b" {
  network_security_group_id = azurerm_network_interface.a.id
  # NIC가 Subnet을 참조하는데, Subnet도 NIC를 참조?
}

# 오류: Cycle detected
```

---

## 🎓 학습 완료 체크리스트

### 기본 개념
- [ ] 파일 분리의 목적과 장점 이해
- [ ] 각 파일의 역할과 책임 파악
- [ ] Terraform의 파일 로딩 메커니즘 이해
- [ ] 리소스 간 참조 관계 이해

### Custom Data
- [ ] Custom data의 목적과 동작 방식
- [ ] base64encode 함수의 필요성
- [ ] Heredoc 문법 (<<EOF ... EOF)
- [ ] VM 초기화 스크립트 작성 방법
- [ ] Cloud-init 로그 확인 방법

### 애플리케이션 배포
- [ ] Nginx 자동 설치 및 설정
- [ ] Flask 애플리케이션 배포
- [ ] MySQL 설치 및 초기화
- [ ] 계층 간 통신 구현
- [ ] 전체 스택 통합 테스트

### 보안
- [ ] NSG 규칙으로 계층별 접근 제어
- [ ] SSH 접근 규칙 설정
- [ ] MySQL 사용자 권한 관리 (@10.10.2.%)
- [ ] Private IP와 Public IP 구분
- [ ] 민감한 정보 관리 (sensitive 속성)

### 운영
- [ ] terraform init, plan, apply 워크플로우
- [ ] Output 값 활용
- [ ] SSH를 통한 VM 관리
- [ ] 로그 확인 및 디버깅
- [ ] 리소스 삭제 (terraform destroy)

### 실무 적용
- [ ] 파일 구조 Best Practices
- [ ] 변수 타입과 활용
- [ ] Custom data Best Practices
- [ ] 트러블슈팅 방법

---

## 🚀 다음 단계

### 1. Nginx를 Reverse Proxy로 설정
```nginx
# /etc/nginx/sites-available/default
server {
    listen 80;
    location / {
        proxy_pass http://10.10.2.4:5000;
        proxy_set_header Host $host;
        proxy_set_header X-Real-IP $remote_addr;
    }
}
```

### 2. Load Balancer 추가
```terraform
resource "azurerm_lb" "web_lb" {
  # Web VM 여러 대를 로드 밸런싱
}
```

### 3. Auto Scaling 구현
```terraform
resource "azurerm_virtual_machine_scale_set" "web_vmss" {
  # 트래픽에 따라 VM 자동 증감
}
```

### 4. Monitoring 추가
```terraform
resource "azurerm_monitor_diagnostic_setting" "vm_diagnostics" {
  # VM 메트릭을 Log Analytics로 전송
}
```

### 5. 모듈화
```
modules/
├── network/
├── vm/
└── nsg/
```

---

**축하합니다!** 🎉 실제 동작하는 3-Tier 애플리케이션을 Terraform으로 자동 배포하는 방법을 마스터했습니다! 이제 프로덕션 환경에서도 인프라를 코드로 관리할 수 있습니다! 💪
