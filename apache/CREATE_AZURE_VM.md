# 인터넷, 네트워크, 서버 학습

## 인터넷, 네트워크, 서버 개념 간단 정리

### 서버란?
- 네트워크를 통해 요청을 받고 응답을 제공하는 컴퓨터
- 웹 서버는 HTTP 요청을 받아 HTML, CSS 등의 리소스를 응답하는 서버

### 클라이언트와 서버
- 클라이언트 : 브라우저 (Chrome, Safari 등)
- 서버 : Apache가 실행 중인 Azure VM

브라우저에서 IP 주소로 접속하면 :
1. 클라이언트가 서버의 (IP + 포트)로 요청
2. 서버의 웹 서버(Apache)가 요청 처리
3. 설정된 DocumentRoot의 파일을 응답

## Apache
- Apache 기본 DocumentRoot 경로 : 
  ```text
  /var/www/html
  ```
- 기본 파일 :
  ```bash
  /var/www/html/index.html
  ```

### Apache 설정 파일 구조 이해
- Apache 설정 디렉토리 :
  ```text
  /etc/apache2
  ```
- 주요 파일 및 디렉토리 :
  - `apache2.conf` : 전체 Apache 기본 설정
  - `ports.conf` : Apache가 수신(Listen)할 포트 정의
  - `sites-available` : VirtualHost 설정 파일 보관
  - `sites-enabled` : 활성화된 VirtualHost 설정
  - `mods-available/`, `mods-enabled/` : Apache 모듈 관리

### Apache 포트 변경 실습(80 -> 8080)
1. `ports.conf` 수정
```bash
sudo vim /etc/apache2/ports.conf
```
```apache
Listen 8080
```

2. `VirtualHost` 설정 수정
```bash
sudo vim /etc/apache2/sites-available/000-default.conf
```
```apache
<VirtualHost *:8080>
    DocumentRoot /var/www/html
    ErrorLog ${APACHE_LOG_DIR}/error.log
    CustomLog ${APACHE_LOG_DIR}/access.log combined
</VirtualHost>
```
3. Apache 재시작
```bash
sudo systemctl restart apache2
```

### Azure NSG(네트워크 보안 그룹) 설정

Apache 설정만으로 외부 접속이 가능한 것이 아니라, Azure NSG(Network Security Group)에서 인바운드 규칙으로 포트를 허용해야합니다.
- 허용한 포트 : 22(SSH), 80(HTTP), 8080(실습용)
- 프로토콜 : TCP
- 작업 : Allow






