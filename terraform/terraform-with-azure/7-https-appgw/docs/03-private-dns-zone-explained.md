# Private DNS Zone 완전 정복

## 📋 목차
1. [왜 IP가 아닌 DNS를 사용하나요?](#왜-ip가-아닌-dns를-사용하나요)
2. [Private DNS Zone이란?](#private-dns-zone이란)
3. [실제 동작 방식](#실제-동작-방식)
4. [IP 직접 사용 시 문제점](#ip-직접-사용-시-문제점)
5. [코드로 이해하기](#코드로-이해하기)
6. [실습: 확인해보기](#실습-확인해보기)

---

## 왜 IP가 아닌 DNS를 사용하나요?

### 🏠 일상생활 비유

**IP 주소 = 집 주소 (서울시 강남구 테헤란로 123)**
- 정확하지만 외우기 어려움
- 이사하면 주소가 바뀜
- 매번 전화번호부를 확인해야 함

**DNS = 이름 (친구 이름: "철수")**
- 외우기 쉬움
- 철수가 이사해도 이름으로 찾으면 됨
- 전화번호부(DNS)가 자동으로 새 주소를 알려줌

### 💻 데이터베이스 연결 예시

#### ❌ IP 직접 사용
```javascript
// 애플리케이션 코드
const dbConnection = mysql.createConnection({
  host: '10.10.2.5',  // 하드코딩된 IP
  user: 'mysqladmin',
  password: 'password',
  database: 'appdb'
});
```

**문제점:**
- 데이터베이스 IP가 바뀌면? → 코드 수정 필요
- 여러 서버에서 사용하면? → 모든 코드 수정 필요
- IP 주소를 외워야 함

#### ✅ DNS 사용
```javascript
// 애플리케이션 코드
const dbConnection = mysql.createConnection({
  host: 'dev-mysql-server-syungg.mysql.database.azure.com',  // FQDN
  user: 'mysqladmin',
  password: 'password',
  database: 'appdb'
});
```

**장점:**
- 데이터베이스 IP가 바뀌어도 코드 수정 불필요
- 읽기 쉽고 의미가 명확함
- DNS가 자동으로 IP를 찾아줌

---

## Private DNS Zone이란?

### 📚 개념

**Private DNS Zone**은 **VNet 내부에서만 작동하는 전용 DNS 서버**입니다.

```
┌─────────────────────────────────────────────────────────────┐
│                    인터넷 (공개 DNS)                          │
│  - google.com → 142.250.XXX.XXX                             │
│  - naver.com → 223.130.XXX.XXX                              │
└─────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────┐
│              VNet (10.10.0.0/16) - 내부 네트워크             │
├─────────────────────────────────────────────────────────────┤
│  Private DNS Zone: privatelink.mysql.database.azure.com     │
│                                                              │
│  - dev-mysql-server.mysql.database.azure.com → 10.10.2.5   │
│  - 외부에서는 조회 불가 (VNet 내부에서만)                    │
└─────────────────────────────────────────────────────────────┘
```

### 🔒 왜 "Private"인가?

**Public DNS**:
- 전 세계 누구나 조회 가능
- `nslookup google.com` → 누구나 IP 확인 가능

**Private DNS**:
- **VNet 내부에서만** 조회 가능
- 외부에서는 조회 불가 (보안 강화)

---

## 실제 동작 방식

### 1️⃣ MySQL Flexible Server 생성 과정

```
┌─────────────────────────────────────────────────┐
│ Step 1: Private DNS Zone 생성                   │
├─────────────────────────────────────────────────┤
│ privatelink.mysql.database.azure.com            │
│ - 아직 레코드 없음                               │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Step 2: VNet과 DNS Zone 연결                    │
├─────────────────────────────────────────────────┤
│ dev-vnet ↔ privatelink.mysql.database.azure.com │
│ - VNet 내부 VM이 이 DNS Zone 사용 가능           │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Step 3: MySQL Server 생성                       │
├─────────────────────────────────────────────────┤
│ dev-mysql-server-syungg                         │
│ - Private IP: 10.10.2.5 할당됨                  │
│ - FQDN: dev-mysql-server-syungg.                │
│         mysql.database.azure.com                │
└─────────────────────────────────────────────────┘
                    ↓
┌─────────────────────────────────────────────────┐
│ Step 4: DNS 레코드 자동 생성                     │
├─────────────────────────────────────────────────┤
│ privatelink.mysql.database.azure.com            │
│ - dev-mysql-server-syungg → 10.10.2.5          │
│ (Azure가 자동으로 추가)                          │
└─────────────────────────────────────────────────┘
```

### 2️⃣ 애플리케이션에서 연결 과정

```
VMSS 인스턴스 (10.10.1.5)에서 MySQL 연결 시도:

┌──────────────────────────────────────────────────┐
│ Step 1: DNS 조회 요청                            │
├──────────────────────────────────────────────────┤
│ mysql -h dev-mysql-server-syungg.                │
│         mysql.database.azure.com -u mysqladmin   │
│                                                  │
│ "dev-mysql-server-syungg.mysql.database.azure.com의 │
│  IP 주소가 뭐야?"                                 │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│ Step 2: Private DNS Zone 조회                   │
├──────────────────────────────────────────────────┤
│ privatelink.mysql.database.azure.com에서 검색    │
│ → 10.10.2.5 발견!                                │
└──────────────────────────────────────────────────┘
                    ↓
┌──────────────────────────────────────────────────┐
│ Step 3: IP로 직접 연결                           │
├──────────────────────────────────────────────────┤
│ 10.10.1.5 → 10.10.2.5 (포트 3306)               │
│ MySQL 연결 성공!                                 │
└──────────────────────────────────────────────────┘
```

---

## IP 직접 사용 시 문제점

### ❌ 문제 1: IP 주소가 고정되지 않음

Azure MySQL Flexible Server는 Private IP를 **동적으로 할당**합니다.

```bash
# 오늘
dev-mysql-server-syungg → 10.10.2.5

# 서버 재시작 후 (또는 장애 복구 후)
dev-mysql-server-syungg → 10.10.2.7  # IP 변경!
```

**결과:**
- 애플리케이션이 `10.10.2.5`로 하드코딩되어 있으면 → 연결 실패!
- 모든 코드를 수정해야 함

### ❌ 문제 2: 고가용성 구성 시 문제

MySQL High Availability 활성화 시:

```
Primary Server: 10.10.2.5
Standby Server: 10.10.2.6

장애 발생 시 자동 Failover:
Primary (10.10.2.5) 다운 → Standby (10.10.2.6)가 Primary로 승격
```

**IP 직접 사용:**
- ❌ 애플리케이션이 계속 `10.10.2.5`로 접속 시도 → 실패
- ❌ 수동으로 IP를 `10.10.2.6`으로 변경해야 함

**DNS 사용:**
- ✅ DNS가 자동으로 `10.10.2.6`으로 업데이트
- ✅ 애플리케이션은 동일한 FQDN 사용 → 자동 복구

### ❌ 문제 3: 보안 및 관리

```bash
# application.properties (설정 파일)

# IP 직접 사용
db.host=10.10.2.5  # 이게 뭐야? 어떤 서버지?

# DNS 사용
db.host=dev-mysql-server-syungg.mysql.database.azure.com  # 명확!
```

**IP 직접 사용:**
- 설정 파일만 봐서는 어떤 서버인지 모름
- IP 주소 관리 필요 (스프레드시트에 정리?)

**DNS 사용:**
- 설정 파일만 봐도 어떤 서버인지 명확
- DNS Zone에서 중앙 관리

---

## 코드로 이해하기

### Terraform 코드 분석

```terraform
# modules/database/main.tf

# 1. Private DNS Zone 생성
resource "azurerm_private_dns_zone" "mysql" {
  name                = "privatelink.mysql.database.azure.com"
  resource_group_name = var.resource_group_name
}
```

**왜 이 이름?**
- Azure MySQL Flexible Server의 표준 DNS Zone 이름
- Azure가 자동으로 이 Zone에 레코드 추가

```terraform
# 2. VNet과 DNS Zone 연결
resource "azurerm_private_dns_zone_virtual_network_link" "mysql" {
  name                  = "${var.mysql_server_name}-vnet-link"
  resource_group_name   = var.resource_group_name
  private_dns_zone_name = azurerm_private_dns_zone.mysql.name
  virtual_network_id    = var.vnet_id
  registration_enabled  = false  # Azure가 자동 관리
}
```

**중요:**
- `registration_enabled = false`: Azure MySQL이 자동으로 레코드 등록
- 우리가 수동으로 DNS 레코드를 만들 필요 없음

```terraform
# 3. MySQL Server 생성
resource "azurerm_mysql_flexible_server" "this" {
  name                   = "dev-mysql-server-syungg"
  delegated_subnet_id    = var.db_subnet_id
  private_dns_zone_id    = azurerm_private_dns_zone.mysql.id  # ← 중요!

  # 이 설정으로 인해 Azure가 자동으로:
  # 1. Private IP 할당 (예: 10.10.2.5)
  # 2. DNS 레코드 생성
  #    dev-mysql-server-syungg.mysql.database.azure.com → 10.10.2.5
}
```

---

## 실습: 확인해보기

### 1️⃣ VMSS 인스턴스에 접속

```bash
# Azure Portal
Resource Groups → dev-rg → dev-vmss → Instances → (인스턴스 선택) → Connect → Serial Console
```

### 2️⃣ DNS 조회 테스트

```bash
# VMSS 인스턴스 내부에서 실행

# 1. DNS로 IP 조회
nslookup dev-mysql-server-syungg.mysql.database.azure.com

# 출력 예시:
# Server:  127.0.0.53
# Address: 127.0.0.53#53
#
# Non-authoritative answer:
# Name: dev-mysql-server-syungg.mysql.database.azure.com
# Address: 10.10.2.5  ← Private IP!
```

### 3️⃣ 외부에서 조회 시도 (실패)

```bash
# 로컬 컴퓨터에서 실행

nslookup dev-mysql-server-syungg.mysql.database.azure.com

# 출력:
# ** server can't find dev-mysql-server-syungg.mysql.database.azure.com: NXDOMAIN
# ← Private DNS이므로 외부에서 조회 불가!
```

### 4️⃣ MySQL 연결 테스트

```bash
# VMSS 인스턴스 내부에서

# DNS 사용 (정상 작동)
mysql -h dev-mysql-server-syungg.mysql.database.azure.com -u mysqladmin -p

# IP 직접 사용 (현재는 작동하지만 권장 안함)
mysql -h 10.10.2.5 -u mysqladmin -p
```

---

## 요약

### 🎯 Private DNS Zone이 필요한 이유

| 항목 | IP 직접 사용 | Private DNS Zone 사용 |
|------|-------------|---------------------|
| **유지보수** | ❌ IP 변경 시 코드 수정 필요 | ✅ DNS가 자동으로 새 IP 반영 |
| **고가용성** | ❌ Failover 시 수동 대응 | ✅ 자동 Failover 지원 |
| **가독성** | ❌ `10.10.2.5` (무슨 서버?) | ✅ `dev-mysql-server.mysql...` (명확!) |
| **보안** | ⚠️ IP 노출 | ✅ VNet 내부에서만 조회 가능 |
| **확장성** | ❌ 서버 추가 시 IP 관리 복잡 | ✅ DNS로 중앙 관리 |

### ✅ 결론

**Private DNS Zone은 선택이 아닌 필수입니다!**

1. **Azure MySQL Flexible Server 요구사항**
   - Private DNS Zone 연결이 없으면 생성 자체가 불가능
   - `VnetNotLinkedToPrivateDnsZone` 에러 발생

2. **실무 베스트 프랙티스**
   - IP 직접 사용은 안티패턴
   - DNS를 통한 간접 참조가 표준

3. **운영 안정성**
   - IP 변경에 자동 대응
   - 코드 수정 없이 인프라 변경 가능

---

## 관련 문서

- [Azure Portal 가이드](./02-azure-portal-guide.md)
- [Troubleshooting 가이드](./05-troubleshooting-guide.md)