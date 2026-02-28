# Cloud-init와 Custom Data 완벽 가이드

## 📖 개요

Custom Data는 VM이 처음 시작될 때 자동으로 실행하는 스크립트입니다. 이 문서는 Azure에서 Cloud-init을 통한 VM 초기화를 설명합니다.

---

## 🎯 Custom Data란?

### 문제: VM이 시작된 후 수동으로 설정

```
❌ 수동 설정 (비효율적)
  1. VM 생성
  2. SSH 접속
  3. apt-get update
  4. apt-get install nginx
  5. systemctl start nginx
  6. 설정 파일 수정
  ...

  모든 VM마다 반복! 😫
```

### 해결책: Custom Data로 자동화

```
✅ 자동화 (효율적)
  VM 생성 + Custom Data 실행
    ↓
  자동으로 Nginx 설치
  + 설정 파일 생성
  + 시작

  모든 VMSS VM이 동일하게 준비됨! ✨
```

### Custom Data의 역할

```
VM 부팅 순서:
  1️⃣ OS 시작 (Ubuntu 22.04)
  2️⃣ Network 설정 (DHCP로 IP 할당)
  3️⃣ Custom Data 실행 ← 우리 스크립트
  4️⃣ VM 완전히 준비됨
```

---

## 📝 Cloud-init 형식

### YAML 기반 설정

```yaml
#cloud-config
# 이 주석이 있으면 Cloud-init이 YAML 파일로 인식

# 설정 내용
```

### 우리 프로젝트의 Custom Data 전체

```hcl
custom_data = base64encode(<<EOF
#cloud-config
package_update: true
packages:
  - nginx

write_files:
  - path: /var/www/html/index.html
    owner: root:root
    permissions: '0644'
    content: |
      <h1>VMSS Web Server</h1>

runcmd:
  - [ bash, -lc, "export DEBIAN_FRONTEND=noninteractive; apt-get update -y >> /var/log/cc_bootstrap.log 2>&1 || true" ]
  - [ bash, -lc, "export DEBIAN_FRONTEND=noninteractive; (apt-get install -y nginx >> /var/log/cc_bootstrap.log 2>&1) || (sleep 10 && apt-get install -y nginx >> /var/log/cc_bootstrap.log 2>&1) || true" ]
  - [ bash, -lc, "systemctl enable nginx >> /var/log/cc_bootstrap.log 2>&1 || true" ]
  - [ bash, -lc, "systemctl start nginx >> /var/log/cc_bootstrap.log 2>&1 || (sleep 5 && systemctl start nginx >> /var/log/cc_bootstrap.log 2>&1) || true" ]
  - [ bash, -lc, "echo \"[$(date -u +%Y-%m-%dT%H:%M:%SZ)] cloud-init runcmd finished\" >> /var/log/cc_bootstrap.log" ]

final_message: "Cloud-init finished"
EOF
)
```

---

## 🏗️ Cloud-init의 5가지 주요 섹션

### 1️⃣ package_update: true

```yaml
package_update: true
```

**의미**: 패키지 목록 업데이트 (`apt-get update`)

**언제 실행**: Cloud-init 초기 단계

```
VM 부팅
  ↓
Cloud-init 시작
  ↓
package_update: true
  ├─ apt-get update
  ├─ 패키지 목록 최신화
  └─ 이후 설치 가능
  ↓
나머지 작업
```

### 2️⃣ packages: [list]

```yaml
packages:
  - nginx
```

**의미**: 설치할 패키지 목록

**실행 과정**:
```
packages 섹션 진행:
  1. apt-get install -y nginx
  2. Nginx 설치 완료
  3. 서비스 등록 (자동)
```

### 3️⃣ write_files: [list]

```yaml
write_files:
  - path: /var/www/html/index.html
    owner: root:root
    permissions: '0644'
    content: |
      <h1>VMSS Web Server</h1>
```

**의미**: VM에 파일을 생성/수정

**각 항목의 역할**:

| 항목 | 값 | 의미 |
|------|-----|------|
| **path** | /var/www/html/index.html | 생성할 파일 경로 |
| **owner** | root:root | 소유자 (user:group) |
| **permissions** | '0644' | 파일 권한 (rw-r--r--) |
| **content** | HTML 내용 | 파일의 내용 |

**실행 결과**:
```bash
$ cat /var/www/html/index.html
<h1>VMSS Web Server</h1>
```

### 4️⃣ runcmd: [list]

```yaml
runcmd:
  - [ bash, -lc, "command 1" ]
  - [ bash, -lc, "command 2" ]
  - [ bash, -lc, "command 3" ]
```

**의미**: 순서대로 실행할 명령어들

**실행 시점**: 다른 모든 설정 후 (마지막)

```
Cloud-init 순서:
  1️⃣ package_update
  2️⃣ packages (설치)
  3️⃣ write_files (파일 생성)
  4️⃣ runcmd (명령어 실행) ← 마지막!
```

### 5️⃣ final_message

```yaml
final_message: "Cloud-init finished"
```

**의미**: 모든 작업 완료 후 표시할 메시지

**확인 위치**:
```bash
$ cat /var/log/cloud-init.log | tail
...
Cloud-init finished
```

---

## 📊 우리 프로젝트의 Custom Data 상세

### 구조 분해

```
#cloud-config
├─ package_update: true
│  └─ apt 패키지 목록 업데이트
│
├─ packages:
│  └─ nginx (웹 서버 설치)
│
├─ write_files:
│  └─ /var/www/html/index.html (홈페이지 생성)
│
├─ runcmd:
│  ├─ apt-get update (패키지 재업데이트, 로그 저장)
│  ├─ apt-get install nginx (설치 재시도 로직)
│  ├─ systemctl enable nginx (부팅 시 자동 시작)
│  ├─ systemctl start nginx (즉시 시작, 재시도 로직)
│  └─ 로그 기록
│
└─ final_message: "Cloud-init finished"
```

### 각 명령어 상세 분석

#### 1️⃣ apt-get update with Error Handling

```bash
[ bash, -lc, "export DEBIAN_FRONTEND=noninteractive; apt-get update -y >> /var/log/cc_bootstrap.log 2>&1 || true" ]
```

**구성 요소**:

| 부분 | 의미 |
|------|------|
| `bash, -lc` | bash 셸로 실행 |
| `export DEBIAN_FRONTEND=noninteractive` | 대화형 입력 제거 (스크립트용) |
| `apt-get update -y` | 패키지 목록 업데이트, -y는 모두 동의 |
| `>> /var/log/cc_bootstrap.log` | 표준 출력을 로그에 저장 |
| `2>&1` | 에러도 로그에 저장 |
| `\|\| true` | 실패해도 계속 진행 |

**동작**:
```
apt-get update 시도
  ├─ 성공: OK
  └─ 실패: 로그만 남기고 계속 (|| true)
```

#### 2️⃣ apt-get install with Retry

```bash
[ bash, -lc, "export DEBIAN_FRONTEND=noninteractive; (apt-get install -y nginx >> /var/log/cc_bootstrap.log 2>&1) || (sleep 10 && apt-get install -y nginx >> /var/log/cc_bootstrap.log 2>&1) || true" ]
```

**동작 흐름**:
```
1️⃣ 첫 시도: apt-get install -y nginx
   ├─ 성공 ✅ → 완료
   └─ 실패 → 다음 단계

2️⃣ 10초 대기: sleep 10
   (네트워크 안정화 또는 lock 해제 대기)

3️⃣ 두 번째 시도: apt-get install -y nginx
   ├─ 성공 ✅ → 완료
   └─ 실패 → 무시 (|| true)
```

**왜 재시도?**
```
상황 1: 패키지 목록 lock 있음
  → 첫 시도 실패
  → 10초 대기로 lock 해제 대기
  → 두 번째 시도 성공

상황 2: 네트워크 일시 불안정
  → 첫 시도 실패
  → 10초 동안 네트워크 복구
  → 두 번째 시도 성공

상황 3: 계속 실패 (심각한 문제)
  → || true로 계속 진행
  → Health Probe에서 감지
  → VM 재시작 또는 제거
```

#### 3️⃣ Systemctl Enable & Start

```bash
[ bash, -lc, "systemctl enable nginx >> /var/log/cc_bootstrap.log 2>&1 || true" ]
[ bash, -lc, "systemctl start nginx >> /var/log/cc_bootstrap.log 2>&1 || (sleep 5 && systemctl start nginx >> /var/log/cc_bootstrap.log 2>&1) || true" ]
```

**enable vs start**:

| 명령어 | 의미 | 실행 시점 |
|--------|------|---------|
| **enable** | 부팅 시 자동 시작 설정 | 부팅할 때마다 |
| **start** | 지금 바로 시작 | 지금 당장 |

**동작**:
```
systemctl enable nginx
  └─ /etc/systemd/system/multi-user.target.wants/nginx.service 생성
     (부팅 시 자동 실행)

systemctl start nginx
  ├─ 첫 시도: nginx 시작
  ├─ 실패 시: 5초 대기
  └─ 재시도: nginx 시작
```

#### 4️⃣ Logging Timestamp

```bash
[ bash, -lc, "echo \"[$(date -u +%Y-%m-%dT%H:%M:%SZ)] cloud-init runcmd finished\" >> /var/log/cc_bootstrap.log" ]
```

**의미**: 완료 시간 기록

**로그 예시**:
```
[2025-02-28T10:45:32Z] cloud-init runcmd finished
```

---

## 🔄 Cloud-init 실행 순서 (완전한 타임라인)

```
t=0초: VM 부팅 시작

t=5초: OS 로드, Network 초기화
  └─ DHCP로 IP 할당

t=10초: Cloud-init 시작
  └─ /var/lib/cloud/ 체크

t=12초: 데이터 소스 감지
  └─ Azure 메타데이터 읽음

t=15초: package_update 실행
  └─ apt-get update
     └─ /var/log/apt/history.log 기록

t=20초: packages 설치 시작
  └─ apt-get install -y nginx
  └─ /var/log/apt/history.log 기록

t=35초: write_files 실행
  └─ /var/www/html/index.html 생성
  └─ 권한 설정 (root:root, 0644)

t=40초: runcmd 실행 시작
  1️⃣ apt-get update (재차)
     └─ /var/log/cc_bootstrap.log

  2️⃣ apt-get install nginx (재차)
     └─ /var/log/cc_bootstrap.log

  3️⃣ systemctl enable nginx

  4️⃣ systemctl start nginx
     └─ Nginx 포트 80 오픈

  5️⃣ echo timestamp

t=50초: runcmd 완료

t=52초: Cloud-init 완료
  └─ /var/log/cloud-init.log에 "Cloud-init finished" 기록

t=55초: VM 완전 준비
  └─ Load Balancer Health Probe 응답 가능
  └─ 트래픽 수신 준비 완료
```

---

## 🐛 로그 확인하기

### Cloud-init 로그 위치

```bash
# 전체 cloud-init 로그
/var/log/cloud-init.log

# Cloud-init output 로그
/var/log/cloud-init-output.log

# 우리가 리다이렉션한 로그
/var/log/cc_bootstrap.log

# APT 로그
/var/log/apt/history.log
```

### 로그 확인 명령어

```bash
# Cloud-init 상태 확인
cloud-init status

# Cloud-init 로그 확인
cat /var/log/cloud-init.log

# 우리 스크립트 로그
tail -100 /var/log/cc_bootstrap.log

# Nginx 시작 로그
systemctl status nginx

# 최근 부팅 로그
journalctl -b | grep cloud-init
```

### 실패 진단

```bash
# Cloud-init 실패 확인
cloud-init status
# Output:
# status: error

# 원인 파악
cat /var/log/cloud-init.log | grep -i error

# 수동 명령어 시도
apt-get update
apt-get install -y nginx
systemctl start nginx

# 권한 확인
ls -la /var/www/html/
```

---

## 🛡️ Error Handling 패턴

### Pattern 1: || true (무시하고 계속)

```bash
apt-get update || true
```

**언제 사용**: 실패해도 진행해야 할 때
- 부가 업데이트
- 로깅
- 상태 확인

**위험**: 중요한 작업 실패를 모를 수 있음

### Pattern 2: || (재시도)

```bash
apt-get install nginx || (sleep 10 && apt-get install nginx)
```

**언제 사용**: 일시적 오류 가능성
- 네트워크 불안정
- 패키지 lock
- 임시 서버 오류

**장점**: 대부분의 일시적 오류 극복

### Pattern 3: || (재시도) || true (최종 무시)

```bash
apt-get install nginx || (sleep 10 && apt-get install nginx) || true
```

**언제 사용**: 실패 가능성 있지만 계속 진행해야 할 때

**흐름**:
```
1차 시도 실패
  ↓
대기 후 2차 시도
  ↓
2차도 실패
  ↓
로그만 남기고 계속 진행 (|| true)
  ↓
다른 명령어 실행
  ↓
Health Probe가 최종 판단
```

### Pattern 4: 명시적 실패 (die early)

```bash
#!/bin/bash
set -e  # 아무 명령어 실패 시 중단

apt-get update
apt-get install -y nginx
systemctl start nginx
```

**언제 사용**: 모든 단계가 필수적일 때

**위험**: 중간에 실패하면 나머지 실행 안 됨

---

## 📊 데이터 포맷: base64 인코딩

### 왜 base64?

```hcl
custom_data = base64encode(<<EOF
#cloud-config
...
EOF
)
```

**이유**:
1. 텍스트를 이진 형식으로 변환
2. Azure API 전송 시 안전성 (특수문자 이스케이프)
3. Azure VM이 base64로 디코딩해서 실행

### 동작 원리

```
Terraform:
  Cloud-init YAML 텍스트
    ↓
  base64encode() 함수
    ↓
  Base64 문자열 (예: IyBjbG91ZC1pbml0...)

Azure API로 전송
    ↓
Azure VM 부팅:
  Base64 문자열 수신
    ↓
  base64 디코딩
    ↓
  원래 YAML 텍스트 복원
    ↓
  Cloud-init 실행
```

---

## 🚨 자주 하는 실수

### ❌ 실수 1: 권한 문제

```yaml
write_files:
  - path: /root/script.sh
    permissions: '0755'  # 실행 권한
    content: |
      #!/bin/bash
      echo "test"

runcmd:
  - /root/script.sh  # 또는 bash /root/script.sh
```

**문제**: 경로가 절대 경로가 아니거나 권한 없을 수 있음

**해결**: 절대 경로 + 명시적 bash 호출
```yaml
runcmd:
  - [ bash, /root/script.sh ]
  - [ bash, -c, "/root/script.sh" ]
```

### ❌ 실수 2: 따옴표 처리

```yaml
runcmd:
  - echo "Hello World"  # ❌ 잘못됨
```

**문제**: 따옴표가 제거될 수 있음

**해결**: 배열 형식 사용
```yaml
runcmd:
  - [ echo, "Hello World" ]  # ✅ 올바름
  - [ bash, -c, "echo 'Hello World'" ]  # ✅ 올바름
```

### ❌ 실수 3: 환경 변수 미설정

```bash
apt-get install nginx  # ❌ 대화형 입력 요청 가능
```

**문제**: 설치 중 사용자 입력 요청 → 스크립트 중단

**해결**:
```bash
export DEBIAN_FRONTEND=noninteractive
apt-get install -y nginx  # ✅ 자동 동의
```

### ❌ 실수 4: Health Probe 응답 경로 없음

```yaml
write_files:
  - path: /var/www/html/index.html
    content: |
      <h1>Server</h1>  # Health Probe가 / 요청 → 200 OK 응답
```

**Nginx 기본 동작**: /var/www/html/index.html을 / 경로로 서빙 ✅

**문제가 될 수 있는 경우**:
```yaml
write_files:
  - path: /var/www/html/status.html  # 이상한 경로
    content: OK

runcmd:
  - cp /var/www/html/status.html /var/www/html/index.html  # 필요
```

---

## ✅ Cloud-init 검증 체크리스트

- [ ] `#cloud-config` 선언이 있는가?
- [ ] `package_update: true`로 패키지 목록 업데이트?
- [ ] 필요한 패키지를 `packages:`에 나열했는가?
- [ ] 중요한 파일을 `write_files:`로 생성했는가?
- [ ] 시작 명령어를 `runcmd:`에 포함했는가?
- [ ] 모든 명령어에 적절한 오류 처리가 있는가?
- [ ] `DEBIAN_FRONTEND=noninteractive` 설정했는가?
- [ ] 모든 명령어가 배열 형식인가? ([bash, -c, "..."])
- [ ] 로그 리다이렉션으로 문제 추적 가능한가?
- [ ] Health Probe가 정상 응답할 경로가 있는가?

---

## 📝 실습: Custom Data 수정하기

### 요구사항: 홈페이지에 서버 이름 표시

#### 현재 코드
```yaml
write_files:
  - path: /var/www/html/index.html
    content: |
      <h1>VMSS Web Server</h1>
```

#### 개선된 코드
```yaml
write_files:
  - path: /var/www/html/index.html
    owner: root:root
    permissions: '0644'
    content: |
      <!DOCTYPE html>
      <html>
      <head>
        <title>VMSS Web Server</title>
        <style>
          body { font-family: Arial; margin: 20px; }
        </style>
      </head>
      <body>
        <h1>VMSS Web Server</h1>
        <p>Server Hostname: <code>$(hostname)</code></p>
        <p>Deployed at: <code>$(date)</code></p>
      </body>
      </html>

runcmd:
  # ... 기존 명령어 ...
  - [ bash, -c, "sed -i \"s/$(hostname)/$HOSTNAME/g\" /var/www/html/index.html" ]
```

#### 결과
```html
Server Hostname: web-vmss000001
Deployed at: Fri Feb 28 10:45:32 UTC 2025
```

---

## 🔗 관련 문서 및 파일

- [vmss-guide.md](vmss-guide.md) - VMSS 개요
- [modules/vmss/main.tf](../../modules/vmss/main.tf) - Custom Data 구현
- [Cloud-init 공식 문서](https://cloud-init.io/)
- [Azure Custom Script Extension](https://docs.microsoft.com/azure/virtual-machines/extensions/custom-script-linux)
