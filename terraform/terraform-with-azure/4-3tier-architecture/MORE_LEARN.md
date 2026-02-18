# 아키텍처 패턴 심화 학습

> **학습 목표**: 모놀리식과 3-Tier 아키텍처를 비교하고, Terraform 리소스 간 의존성을 완벽히 이해합니다.

---

## 1. 모놀리식 아키텍처 (Monolithic Architecture) 🏢

### 1.1 모놀리식 아키텍처란?

**모놀리식(Monolithic)**은 "단일체", "일체형"이라는 의미로, **모든 기능이 하나의 애플리케이션에 통합**된 아키텍처입니다.

#### 🏛️ 기본 구조

```
┌────────────────────────────────────────────┐
│         단일 애플리케이션 서버              │
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │  사용자 인터페이스 (UI)               │ │
│  │  - 웹 페이지 렌더링                   │ │
│  │  - 사용자 입력 처리                   │ │
│  └──────────────────────────────────────┘ │
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │  비즈니스 로직                        │ │
│  │  - 주문 처리                          │ │
│  │  - 결제 처리                          │ │
│  │  - 재고 관리                          │ │
│  │  - 사용자 관리                        │ │
│  └──────────────────────────────────────┘ │
│                                            │
│  ┌──────────────────────────────────────┐ │
│  │  데이터 접근 계층                     │ │
│  │  - SQL 쿼리                           │ │
│  │  - ORM                                │ │
│  └──────────────────────────────────────┘ │
│                                            │
└────────────────────────────────────────────┘
                    ↓
            ┌──────────────┐
            │   Database    │
            └──────────────┘
```

**특징**:
- 모든 코드가 **하나의 코드베이스**
- 하나의 프로세스에서 실행
- 단일 배포 단위
- 같은 메모리 공간 공유

#### 🌍 현실 세계 비유

```
전통적인 식당 (모놀리식)
┌──────────────────────┐
│   한 건물 안에:       │
│   - 주방             │
│   - 홀 (식사 공간)   │
│   - 창고             │
│   - 사무실           │
└──────────────────────┘
```

### 1.2 모놀리식 아키텍처 예시

#### 전형적인 E-Commerce 애플리케이션

```java
// 하나의 애플리케이션 안에 모든 기능
public class ECommerceApp {
    
    // 사용자 관리
    public void registerUser(User user) { ... }
    public void login(String username, String password) { ... }
    
    // 상품 관리
    public List<Product> getProducts() { ... }
    public Product getProductDetails(int id) { ... }
    
    // 주문 처리
    public Order createOrder(Cart cart) { ... }
    public void processPayment(Order order) { ... }
    
    // 재고 관리
    public void updateInventory(int productId, int quantity) { ... }
    
    // 배송 관리
    public void scheduleShipping(Order order) { ... }
}
```

**Azure에서 배포한다면**:

```
┌──────────────────────────────────┐
│  단일 VM 또는 App Service        │
│                                  │
│  ┌────────────────────────────┐ │
│  │  Monolithic App            │ │
│  │  - Tomcat / Node.js        │ │
│  │  - 포트: 8080              │ │
│  │  - 모든 기능 포함          │ │
│  └────────────────────────────┘ │
│                                  │
│  Public IP: x.x.x.x              │
└──────────────────────────────────┘
            ↓
    ┌──────────────┐
    │   MySQL DB    │
    └──────────────┘
```

### 1.3 모놀리식 vs 3-Tier 비교

#### 🏗️ 구조 비교

**모놀리식**:
```
사용자 → [단일 애플리케이션] → 데이터베이스
         (모든 기능이 여기)
```

**3-Tier**:
```
사용자 → [Web 계층] → [App 계층] → [DB 계층]
         (UI만)      (비즈니스)     (데이터)
```

#### 📊 상세 비교표

| 측면 | 모놀리식 | 3-Tier |
|------|---------|--------|
| **구조** | 단일 애플리케이션 | 3개 독립 계층 |
| **배포** | 전체를 한 번에 배포 | 계층별 독립 배포 |
| **확장** | 전체를 복제해야 함 | 필요한 계층만 확장 |
| **개발** | 팀 전체가 같은 코드베이스 | 계층별 팀 분리 가능 |
| **기술 스택** | 하나의 언어/프레임워크 | 계층별 다른 기술 가능 |
| **장애 격리** | 부분 장애가 전체 영향 | 계층별 격리 가능 |
| **초기 복잡도** | 낮음 (시작 쉬움) | 높음 (설정 많음) |
| **운영 복잡도** | 중간 | 높음 (많은 서버) |
| **비용** | 낮음 (서버 1대) | 높음 (서버 3대 이상) |
| **성능** | 빠름 (메모리 공유) | 네트워크 오버헤드 |

### 1.4 모놀리식의 장점 ✅

#### 1. **단순성**
```javascript
// 함수 호출이 간단
function checkout(userId, cartItems) {
    const user = getUserDetails(userId);        // 같은 애플리케이션
    const order = createOrder(user, cartItems); // 같은 메모리
    const payment = processPayment(order);      // 같은 프로세스
    updateInventory(cartItems);                 // 함수 호출로 끝
    return order;
}
```

**3-Tier에서는**:
```javascript
// 여러 서비스 간 통신 필요
async function checkout(userId, cartItems) {
    const user = await http.get('http://user-service/api/users/' + userId);
    const order = await http.post('http://order-service/api/orders', {...});
    const payment = await http.post('http://payment-service/api/pay', {...});
    await http.put('http://inventory-service/api/stock', {...});
    return order;
}
```

#### 2. **빠른 개발**
- 초기 프로토타입 빠르게 구축
- IDE에서 전체 코드 탐색 용이
- 디버깅 쉬움 (하나의 프로세스)

#### 3. **성능**
- 함수 호출 (나노초)
- 네트워크 오버헤드 없음
- 트랜잭션 관리 간단

#### 4. **낮은 운영 비용**
```
모놀리식:
- VM 1대
- 데이터베이스 1대
= 총 2대

3-Tier:
- Web VM 1~N대
- App VM 1~N대
- DB VM 1~N대
= 최소 3대 이상
```

#### 5. **작은 팀에 적합**
- 1~5명 개발팀
- 스타트업 초기 단계
- MVP (Minimum Viable Product)

### 1.5 모놀리식의 단점 ❌

#### 1. **확장성 제한**
```
사용자 100명 → VM 1대
사용자 1,000명 → VM 1대 (느려짐)
사용자 10,000명 → VM을 크게 업그레이드 (비용↑)
사용자 100,000명 → 한계에 도달
```

**문제**: 사용자가 주로 상품 조회만 하는데, 결제 기능까지 복제해야 함

#### 2. **배포 위험**
```
시나리오: 사소한 UI 버그 수정

모놀리식:
1. UI 코드 수정
2. 전체 애플리케이션 재배포
3. 결제, 주문 등 모든 기능 다시 시작
4. 만약 버그가 있다면? 전체 서비스 다운 ⚠️

3-Tier:
1. Web 계층만 수정
2. Web 서버만 재배포
3. App, DB는 계속 동작
4. 버그가 있어도 UI만 영향 ✅
```

#### 3. **기술 부채 증가**
```java
// 처음에는 깔끔
public class OrderService {
    public Order createOrder(Cart cart) {
        // 50줄
    }
}

// 2년 후...
public class OrderService {
    public Order createOrder(Cart cart) {
        // 500줄
        // 결제, 재고, 배송, 포인트, 쿠폰, 이벤트...
        // 누가 수정할까요? 😱
    }
}
```

#### 4. **팀 확장 어려움**
```
팀 A: "주문 기능 수정 중..."
팀 B: "결제 기능 수정 중..."
팀 C: "재고 기능 수정 중..."

→ 같은 코드베이스
→ Git Conflict 지옥 🔥
→ 서로 코드 리뷰 대기
→ 배포 순서 조율 필요
```

#### 5. **부분 장애의 전체 확산**
```
시나리오: 결제 게이트웨이 응답 지연

모놀리식:
결제 API 느림 
→ 스레드 풀 고갈
→ 전체 애플리케이션 응답 없음
→ 사용자는 상품 조회도 못 함 😱

3-Tier:
결제 서비스 느림
→ App 계층은 타임아웃 처리
→ 사용자는 상품 조회/검색 계속 가능 ✅
```

### 1.6 언제 모놀리식을 사용할까?

#### ✅ 적합한 경우

**1. 스타트업 초기**
```
- 빠른 MVP 개발
- 시장 검증이 우선
- 트래픽 적음 (< 10,000 사용자)
- 개발자 1~5명
```

**2. 작은 내부 도구**
```
- 사내 관리 시스템
- 백오피스 도구
- 배치 처리 시스템
```

**3. 간단한 웹사이트**
```
- 블로그
- 포트폴리오 사이트
- 회사 소개 페이지
```

#### ❌ 부적합한 경우

**1. 대규모 서비스**
```
- 수만~수백만 사용자
- 24/7 무중단 필요
- 글로벌 서비스
```

**2. 팀 규모가 클 때**
```
- 10명 이상 개발자
- 여러 팀으로 나뉨
- 동시 개발 많음
```

**3. 빠른 변화 필요**
```
- 빈번한 배포 (하루 여러 번)
- A/B 테스트 많음
- 기능별 독립 출시
```

### 1.7 진화 경로: 모놀리식 → 3-Tier → 마이크로서비스

```
단계 1: 모놀리식
┌──────────────────┐
│  Monolithic App  │
└──────────────────┘
        ↓
     (트래픽 증가, 팀 증가)
        ↓
단계 2: 3-Tier
┌─────┐   ┌─────┐   ┌─────┐
│ Web │ → │ App │ → │ DB  │
└─────┘   └─────┘   └─────┘
        ↓
     (복잡도 증가, 확장 필요)
        ↓
단계 3: 마이크로서비스
┌─────┐   ┌──────────────────────┐   ┌──────────┐
│ Web │ → │ User Service         │ → │ User DB  │
│     │   │ Order Service        │   │ Order DB │
│     │   │ Payment Service      │   │ Pay DB   │
│     │   │ Inventory Service    │   │ Inv DB   │
└─────┘   └──────────────────────┘   └──────────┘
```

### 1.8 실무 조언

#### 💡 선생님의 경험

**시작은 모놀리식으로**
```
✅ "일단 만들어라, 그 다음에 분리해라"
✅ Premature optimization is the root of all evil
✅ 실제 문제가 생긴 후 리팩토링
```

**분리 신호**
```
다음 신호가 보이면 3-Tier 고려:
1. 배포할 때마다 긴장됨
2. 개발자 5명 넘어감
3. 특정 기능만 확장하고 싶음
4. 배포 시간 1시간 이상
5. 테스트 실행 10분 이상
```

**점진적 분리**
```
한 번에 전부 바꾸지 말고:
1. 먼저 Web 계층 분리 (Static files)
2. 다음 DB 접근 계층 분리
3. 마지막 비즈니스 로직 분리
```

---

## 2. 4-3tier-architecture 리소스 의존성 다이어그램 🔗

### 2.1 전체 리소스 연결 관계

```
┌─────────────────────────────────────────────────────────────────────────────────┐
│                          Azure Subscription                                     │
│                                                                                 │
│  ┌──────────────────────────────────────────────────────────────────────────┐   │
│  │  azurerm_resource_group.rg                                               │   │
│  │  Name: var.resource_group_name                                           │   │
│  │  Location: var.location                                                  │   │
│  └──────────────────────────────────────────────────────────────────────────┘   │
│          │                                                                      │
│          │ (모든 리소스가 이 RG에 속함)                                               │
│          │                                                                      │
│          │                                                                      │
│          │                                                                      │
│          ▼                                                                      │
│  ┌──────────────────────────────────────────────┐                               │
│  │  azurerm_virtual_network.vnet                │                               │
│  │  Name: 3tier-architecture-vnet               │                               │
│  │  Address Space: 10.10.0.0/16                 │                               │
│  │  resource_group_name: rg.name                │                               │
│  │  location: rg.location                       │                               │
│  └──────────────────────────────────────────────┘                               │
│          │                                                                      │
│          │ (VNet을 3개의 Subnet으로 분할)                                           │
│          │                                                                      │
│      ┌───┴────────────────────┬──────────────────┐                              │
│      │                        │                  │                              │
│      ▼                        ▼                  ▼                              │
│  ┌────────────────┐  ┌────────────────┐  ┌────────────────┐                     │
│  │ azurerm_subnet │  │ azurerm_subnet │  │ azurerm_subnet │                     │
│  │   .web         │  │   .app         │  │   .db          │                     │
│  │ 10.10.1.0/24   │  │ 10.10.2.0/24   │  │ 10.10.3.0/24   │                     │
│  └────────┬───────┘  └────────┬───────┘  └────────┬───────┘                     │
│           │                   │                   │                             │
│           │                   │                   │                             │
│  ┌────────┴────────┐ ┌────────┴────────┐ ┌────────┴────────┐                    │
│  │ NSG 연결         │ │ NSG 연결         │ │ NSG 연결         │                    │
│  └────────┬────────┘ └────────┬────────┘ └────────┬────────┘                    │
│           │                   │                   │                             │
│           ▼                   ▼                   ▼                             │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │  Network Security Groups & Rules                                        │    │
│  │                                                                         │    │
│  │  ┌─────────────────────────────────────────────────────────────┐        │    │
│  │  │ azurerm_network_security_group.web_nsg                      │        │    │
│  │  │ Name: web-nsg                                               │        │    │
│  │  │   │                                                         │        │    │
│  │  │   ├─▶ azurerm_network_security_rule.web_http                │        │    │
│  │  │   │    Priority: 100                                        │        │    │
│  │  │   │    Inbound: * → 80 (Allow)                              │        │    │
│  │  │   │                                                         │        │    │
│  │  │   └─▶ azurerm_subnet_network_security_group_association     │        │    │
│  │  │         .web_assoc                                          │        │    │
│  │  │         subnet_id: azurerm_subnet.web.id                    │        │    │
│  │  └─────────────────────────────────────────────────────────────┘        │    │
│  │                                                                         │    │
│  │  ┌─────────────────────────────────────────────────────────────┐        │    │
│  │  │ azurerm_network_security_group.app_nsg                      │        │    │
│  │  │ Name: app-nsg                                               │        │    │
│  │  │   │                                                         │        │    │
│  │  │   ├─▶ azurerm_network_security_rule.app_allow_web           │        │    │
│  │  │   │    Priority: 100                                        │        │    │
│  │  │   │    Inbound: 10.10.1.0/24 → 8080 (Allow)                 │        │    │
│  │  │   │                                                         │        │    │
│  │  │   └─▶ azurerm_subnet_network_security_group_association     │        │    │
│  │  │         .app_assoc                                          │        │    │
│  │  │         subnet_id: azurerm_subnet.app.id                    │        │    │
│  │  └─────────────────────────────────────────────────────────────┘        │    │
│  │                                                                         │    │
│  │  ┌─────────────────────────────────────────────────────────────┐        │    │
│  │  │ azurerm_network_security_group.db_nsg                       │        │    │
│  │  │ Name: db-nsg                                                │        │    │
│  │  │   │                                                         │        │    │
│  │  │   ├─▶ azurerm_network_security_rule.db_allow_app            │        │    │
│  │  │   │    Priority: 100                                        │        │    │
│  │  │   │    Inbound: 10.10.2.0/24 → 3306 (Allow)                 │        │    │
│  │  │   │                                                         │        │    │
│  │  │   └─▶ azurerm_subnet_network_security_group_association     │        │    │
│  │  │         .db_assoc                                           │        │    │
│  │  │         subnet_id: azurerm_subnet.db.id                     │        │    │
│  │  └─────────────────────────────────────────────────────────────┘        │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
│                                                                                 │
│  ┌─────────────────────────────────────────────────────────────────────────┐    │
│  │  Compute Resources (Virtual Machines)                                   │    │
│  │                                                                         │    │
│  │  ┌─────────────────────────────────────────────────────────────┐        │    │
│  │  │ WEB TIER                                                    │        │    │
│  │  │                                                             │        │    │
│  │  │  azurerm_public_ip.web_pip                                  │        │    │
│  │  │  Name: web-pip                                              │        │    │
│  │  │  Allocation: Static                                         │        │    │
│  │  │  IP Address: 20.196.xxx.xxx (생성 후 할당)                     │        │    │
│  │  │         │                                                   │        │    │
│  │  │         ▼                                                   │        │    │
│  │  │  azurerm_network_interface.web_nic                          │        │    │
│  │  │  Name: web-nic                                              │        │    │
│  │  │  subnet_id: azurerm_subnet.web.id                           │        │    │
│  │  │  private_ip: 10.10.1.x (Dynamic)                            │        │    │
│  │  │  public_ip_address_id: azurerm_public_ip.web_pip.id         │        │    │
│  │  │         │                                                   │        │    │
│  │  │         ▼                                                   │        │    │
│  │  │  azurerm_linux_virtual_machine.web_vm                       │        │    │
│  │  │  Name: web-vm                                               │        │    │
│  │  │  Size: Standard_B1s                                         │        │    │
│  │  │  network_interface_ids: [web_nic.id]                        │        │    │
│  │  │  OS: Ubuntu 22.04 LTS                                       │        │    │
│  │  │  Admin: azureuser / Password1234!                           │        │    │
│  │  └─────────────────────────────────────────────────────────────┘        │    │
│  │                                                                         │    │
│  │  ┌─────────────────────────────────────────────────────────────┐        │    │
│  │  │ APP TIER                                                    │        │    │
│  │  │                                                             │        │    │
│  │  │  azurerm_network_interface.app_nic                          │        │    │
│  │  │  Name: app-nic                                              │        │    │
│  │  │  subnet_id: azurerm_subnet.app.id                           │        │    │
│  │  │  private_ip: 10.10.2.x (Dynamic)                            │        │    │
│  │  │  ⚠️  public_ip_address_id: NONE (Private만!)                 │        │    │
│  │  │         │                                                   │        │    │
│  │  │         ▼                                                   │        │    │
│  │  │  azurerm_linux_virtual_machine.app_vm                       │        │    │
│  │  │  Name: app-vm                                               │        │    │
│  │  │  Size: Standard_B1s                                         │        │    │
│  │  │  network_interface_ids: [app_nic.id]                        │        │    │
│  │  │  OS: Ubuntu 22.04 LTS                                       │        │    │
│  │  │  Admin: azureuser / Password1234!                           │        │    │
│  │  └─────────────────────────────────────────────────────────────┘        │    │
│  │                                                                         │    │
│  │  ┌─────────────────────────────────────────────────────────────┐        │    │
│  │  │ DB TIER                                                     │        │    │
│  │  │                                                             │        │    │
│  │  │  azurerm_network_interface.db_nic                           │        │    │
│  │  │  Name: db-nic                                               │        │    │
│  │  │  subnet_id: azurerm_subnet.db.id                            │        │    │
│  │  │  private_ip: 10.10.3.x (Dynamic)                            │        │    │
│  │  │  ⚠️  public_ip_address_id: NONE (Private만!)                 │        │    │
│  │  │         │                                                   │        │    │
│  │  │         ▼                                                   │        │    │
│  │  │  azurerm_linux_virtual_machine.db_vm                        │        │    │
│  │  │  Name: db-vm                                                │        │    │
│  │  │  Size: Standard_B1s                                         │        │    │
│  │  │  network_interface_ids: [db_nic.id]                         │        │    │
│  │  │  OS: Ubuntu 22.04 LTS                                       │        │    │
│  │  │  Admin: azureuser / Password1234!                           │        │    │
│  │  └─────────────────────────────────────────────────────────────┘        │    │
│  └─────────────────────────────────────────────────────────────────────────┘    │
└─────────────────────────────────────────────────────────────────────────────────┘
```

### 2.2 생성 순서 (Terraform Dependency Graph)

Terraform은 리소스 간 참조를 분석하여 **자동으로 생성 순서**를 결정합니다.

```
Level 0 (시작)
└─▶ azurerm_resource_group.rg
      │
      │
Level 1 (RG 필요)
├─▶ azurerm_virtual_network.vnet
│     │
│     │
Level 2 (VNet 필요)
├─▶ azurerm_subnet.web
├─▶ azurerm_subnet.app
├─▶ azurerm_subnet.db
│     │
│     │
Level 3 (RG 필요, Subnet과 독립)
├─▶ azurerm_network_security_group.web_nsg
├─▶ azurerm_network_security_group.app_nsg
├─▶ azurerm_network_security_group.db_nsg
├─▶ azurerm_public_ip.web_pip
│     │
│     │
Level 4 (NSG 필요)
├─▶ azurerm_network_security_rule.web_http
├─▶ azurerm_network_security_rule.app_allow_web
├─▶ azurerm_network_security_rule.db_allow_app
│     │
│     │
Level 5 (Subnet + NSG 필요)
├─▶ azurerm_subnet_network_security_group_association.web_assoc
├─▶ azurerm_subnet_network_security_group_association.app_assoc
├─▶ azurerm_subnet_network_security_group_association.db_assoc
│     │
│     │
Level 6 (Subnet + Public IP 필요)
├─▶ azurerm_network_interface.web_nic  (Subnet + Public IP)
├─▶ azurerm_network_interface.app_nic  (Subnet만)
├─▶ azurerm_network_interface.db_nic   (Subnet만)
│     │
│     │
Level 7 (NIC 필요)
└─▶ azurerm_linux_virtual_machine.web_vm
└─▶ azurerm_linux_virtual_machine.app_vm
└─▶ azurerm_linux_virtual_machine.db_vm
      │
      │
    완료! ✅
```

### 2.3 데이터 흐름 다이어그램

#### 사용자 요청 흐름

```
┌──────────────┐
│   Internet   │
│   (사용자)     │
└──────┬───────┘
       │
       │ HTTP Request (Port 80)
       │
       ▼
┌──────────────────────────────────────────┐
│  Azure Public IP: 20.196.xxx.xxx         │
│  azurerm_public_ip.web_pip               │
└──────┬───────────────────────────────────┘
       │
       │ (Public IP → NIC 매핑)
       │
       ▼
┌──────────────────────────────────────────┐
│  Web Subnet: 10.10.1.0/24                │
│  ┌────────────────────────────────────┐  │
│  │ NSG: web_nsg                       │  │
│  │ ✅ Allow: * → 80 (Priority 100)    │   │
│  │ ❌ Deny: 기타 (Default Rule)        │   │
│  └────────────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ NIC: web_nic                       │  │
│  │ Private IP: 10.10.1.4              │  │
│  │ Public IP: 연결됨                    │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ VM: web-vm                         │  │
│  │ - Nginx 실행 (Port 80)              │  │
│  │ - 사용자 요청 처리                     │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
       │
       │ 10.10.1.4 → 10.10.2.4:8080
       │ (App 서버 호출)
       │
       ▼
┌──────────────────────────────────────────┐
│  App Subnet: 10.10.2.0/24                │
│  ┌────────────────────────────────────┐  │
│  │ NSG: app_nsg                       │  │
│  │ ✅ Allow: 10.10.1.0/24 → 8080       │  │
│  │    (Web Subnet만 허용!)              │  │
│  │ ❌ Deny: Internet → 8080            │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ NIC: app_nic                       │  │
│  │ Private IP: 10.10.2.4              │  │
│  │ Public IP: 없음 ⚠️                   │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ VM: app-vm                         │  │
│  │ - Spring Boot (Port 8080)          │  │
│  │ - 비즈니스 로직 처리                    │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
       │
       │ 10.10.2.4 → 10.10.3.4:3306
       │ (DB 쿼리)
       │
       ▼
┌──────────────────────────────────────────┐
│  DB Subnet: 10.10.3.0/24                 │
│  ┌────────────────────────────────────┐  │
│  │ NSG: db_nsg                        │  │
│  │ ✅ Allow: 10.10.2.0/24 → 3306       │ │
│  │    (App Subnet만 허용!)              │ │
│  │ ❌ Deny: Web/Internet → 3306        │ │
│  └────────────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ NIC: db_nic                        │  │
│  │ Private IP: 10.10.3.4              │  │
│  │ Public IP: 없음 ⚠️                   │  │
│  └────────────────────────────────────┘  │
│                                          │
│  ┌────────────────────────────────────┐  │
│  │ VM: db-vm                          │  │
│  │ - MySQL (Port 3306)                │  │
│  │ - 데이터 저장/조회                     │  │
│  └────────────────────────────────────┘  │
└──────────────────────────────────────────┘
       │
       │ 데이터 조회 결과
       │
       ▼
   (역순으로 응답 반환)
   App VM → Web VM → 사용자
```

### 2.4 보안 계층 분석

```
┌────────────────────────────────────────────────────────────────┐
│                        보안 계층화                              │
└────────────────────────────────────────────────────────────────┘

인터넷 (Internet)
    │
    │ ⚡ PUBLIC ACCESS
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  Layer 1: Public IP & NSG                                   │
│  - Public IP로 외부 노출                                     │
│  - web_nsg: HTTP(80) 허용, 나머지 차단                       │
│  - 첫 번째 방어선                                            │
└─────────────────────────────────────────────────────────────┘
    │
    │ ✅ Allowed: Port 80
    │ ❌ Blocked: Port 22, 443, 8080, 3306...
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  Web VM (10.10.1.x)                                         │
│  - 인터넷 접근 가능                                          │
│  - 외부 공격 표면 최소화 (Port 80만)                         │
└─────────────────────────────────────────────────────────────┘
    │
    │ 🔒 INTERNAL COMMUNICATION
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  Layer 2: Private Network + NSG                             │
│  - app_nsg: Web Subnet(10.10.1.0/24)에서만 허용            │
│  - 인터넷 직접 접근 불가                                     │
│  - 두 번째 방어선                                            │
└─────────────────────────────────────────────────────────────┘
    │
    │ ✅ Allowed:  10.10.1.0/24 → 8080
    │ ❌ Blocked:  Internet → 8080
    │ ❌ Blocked:  10.10.3.0/24 → 8080 (DB에서 App 접근 차단)
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  App VM (10.10.2.x)                                         │
│  - Private IP만 존재                                         │
│  - Web 계층을 통해서만 접근 가능                             │
└─────────────────────────────────────────────────────────────┘
    │
    │ 🔐 DATABASE ACCESS ONLY
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  Layer 3: Database Isolation + NSG                          │
│  - db_nsg: App Subnet(10.10.2.0/24)에서만 허용             │
│  - 최고 수준 보안                                            │
│  - 세 번째 방어선                                            │
└─────────────────────────────────────────────────────────────┘
    │
    │ ✅ Allowed:  10.10.2.0/24 → 3306
    │ ❌ Blocked:  Internet → 3306
    │ ❌ Blocked:  10.10.1.0/24 → 3306 (Web에서 DB 직접 접근 차단)
    │
    ▼
┌─────────────────────────────────────────────────────────────┐
│  DB VM (10.10.3.x)                                          │
│  - Private IP만 존재                                         │
│  - App 계층을 통해서만 접근 가능                             │
│  - 데이터 최종 보관소                                        │
└─────────────────────────────────────────────────────────────┘
```

### 2.5 리소스 참조 체인

각 리소스가 어떤 다른 리소스를 참조하는지 표현:

```
azurerm_resource_group.rg (독립)
    ├─▶ [참조 없음]
    │
    └─▶ 다음 리소스들이 rg를 참조:
         - azurerm_virtual_network.vnet
         - azurerm_network_security_group.*
         - azurerm_public_ip.web_pip
         - azurerm_network_interface.*
         - azurerm_linux_virtual_machine.*

azurerm_virtual_network.vnet
    ├─▶ resource_group_name = azurerm_resource_group.rg.name
    ├─▶ location = azurerm_resource_group.rg.location
    │
    └─▶ 다음 리소스들이 vnet을 참조:
         - azurerm_subnet.web
         - azurerm_subnet.app
         - azurerm_subnet.db

azurerm_subnet.web
    ├─▶ resource_group_name = azurerm_resource_group.rg.name
    ├─▶ virtual_network_name = azurerm_virtual_network.vnet.name
    │
    └─▶ 다음 리소스들이 web subnet을 참조:
         - azurerm_network_interface.web_nic (subnet_id)
         - azurerm_subnet_network_security_group_association.web_assoc

azurerm_network_security_group.web_nsg
    ├─▶ resource_group_name = azurerm_resource_group.rg.name
    ├─▶ location = azurerm_resource_group.rg.location
    │
    └─▶ 다음 리소스들이 web_nsg를 참조:
         - azurerm_network_security_rule.web_http
         - azurerm_subnet_network_security_group_association.web_assoc

azurerm_network_security_rule.web_http
    ├─▶ resource_group_name = azurerm_resource_group.rg.name
    └─▶ network_security_group_name = azurerm_network_security_group.web_nsg.name

azurerm_subnet_network_security_group_association.web_assoc
    ├─▶ subnet_id = azurerm_subnet.web.id
    └─▶ network_security_group_id = azurerm_network_security_group.web_nsg.id

azurerm_public_ip.web_pip
    ├─▶ resource_group_name = azurerm_resource_group.rg.name
    ├─▶ location = azurerm_resource_group.rg.location
    │
    └─▶ 다음 리소스가 public_ip를 참조:
         - azurerm_network_interface.web_nic

azurerm_network_interface.web_nic
    ├─▶ resource_group_name = azurerm_resource_group.rg.name
    ├─▶ location = azurerm_resource_group.rg.location
    ├─▶ subnet_id = azurerm_subnet.web.id
    ├─▶ public_ip_address_id = azurerm_public_ip.web_pip.id
    │
    └─▶ 다음 리소스가 nic를 참조:
         - azurerm_linux_virtual_machine.web_vm

azurerm_linux_virtual_machine.web_vm
    ├─▶ resource_group_name = azurerm_resource_group.rg.name
    ├─▶ location = azurerm_resource_group.rg.location
    └─▶ network_interface_ids = [azurerm_network_interface.web_nic.id]

[App, DB 계층도 동일한 패턴 반복]
```

### 2.6 요약: 21개 리소스 목록

```
┌────────────────────────────────────────────────────────────┐
│  리소스 타입                      │  수량  │  이름         │
├────────────────────────────────────────────────────────────┤
│  Resource Group                   │   1    │  rg           │
│  Virtual Network                  │   1    │  vnet         │
│  Subnet                           │   3    │  web,app,db   │
│  Network Security Group           │   3    │  web,app,db   │
│  Network Security Rule            │   3    │  각 NSG당 1개 │
│  NSG-Subnet Association           │   3    │  각 NSG당 1개 │
│  Public IP                        │   1    │  web_pip      │
│  Network Interface                │   3    │  web,app,db   │
│  Linux Virtual Machine            │   3    │  web,app,db   │
├────────────────────────────────────────────────────────────┤
│  총합                             │  21    │               │
└────────────────────────────────────────────────────────────┘
```

---

## 3. 학습 정리 📚

### 3.1 모놀리식 vs 3-Tier 선택 가이드

```
              시작                단순한가?
                │                    │
                │                    ├─ Yes → 모놀리식
                │                    │
                ▼                    └─ No
         무엇을 만들까?                     │
                │                          ▼
        ┌───────┼───────┐           트래픽 많은가?
        │       │       │                  │
     작은 앱  중간 앱  대규모            ├─ No → 모놀리식
        │       │       │                  │
        ▼       ▼       ▼                  └─ Yes
    모놀리식  3-Tier  마이크로                    │
                              서비스              ▼
                                          팀 규모 큰가?
                                                 │
                                          ├─ No → 모놀리식
                                          │
                                          └─ Yes → 3-Tier
```

### 3.2 핵심 개념 체크리스트

#### 모놀리식
- [ ] 모든 기능이 하나의 애플리케이션
- [ ] 빠른 개발, 단순한 배포
- [ ] 작은 팀에 적합
- [ ] 확장 시 전체 복제
- [ ] 스타트업 초기 단계에 권장

#### 3-Tier
- [ ] 계층별 독립적 확장
- [ ] 계층별 보안 규칙
- [ ] 장애 격리 가능
- [ ] 복잡한 네트워크 설정
- [ ] 규모가 커질 때 전환

#### Terraform 의존성
- [ ] 리소스 참조로 자동 의존성
- [ ] Terraform이 생성 순서 자동 결정
- [ ] 삭제는 역순으로 진행
- [ ] terraform graph로 시각화 가능

---

## 🎓 선생님의 최종 조언

### 실무에서의 접근법

**1단계: 모놀리식으로 시작** (0-6개월)
```
- 빠르게 MVP 개발
- 사용자 피드백 수집
- Product-Market Fit 찾기
```

**2단계: 모니터링 & 병목 파악** (6-12개월)
```
- 어느 부분이 느린가?
- 어느 기능이 자주 사용되나?
- 확장이 필요한 부분은?
```

**3단계: 선택적 분리** (12개월 이후)
```
- 병목이 되는 부분만 분리
- 처음에는 2-Tier도 OK
- 점진적 마이그레이션
```

### 의존성 그래프 활용

```bash
# Terraform 의존성 시각화
terraform graph | dot -Tpng > graph.png

# 특정 리소스만 생성
terraform apply -target=azurerm_virtual_network.vnet

# 의존성 체크
terraform plan
```

---

**축하합니다!** 🎉 아키텍처 패턴과 리소스 의존성을 마스터했습니다! 이제 프로덕션 시스템을 설계할 준비가 되었습니다! 🚀
