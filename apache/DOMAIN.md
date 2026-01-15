# Domain 관련 학습

## DocumentRoot 및 HTML 수정
HTML 수정 이전에, 먼저 브라우저 접속(`http://<Azure_VM_Public_IP>`)해보면, Apache 기본 페이지가 출력됨을 확인할 수 있습니다.

Apache 기본 문서 경로는 `/var/www/html`입니다. HTML을 수정해 Apache 기본 페이지가 아닌 제가 작성한 내용이 보이도록 수정해보겠습니다. 다음 명령어를 입력합니다 :
```bash
sudo vim /var/www/html/index.html
```

```html
<h1>Apache Web Server</h1>
<p>written by leesyungg</p>
```

## 포트 개념 및 Apache 포트 변경

### 포트(port)
하나의 IP 주소에서 여러 네트워크 서비스를 구분하는 논리적 번호입니다. 대표 포트는 다음과 같습니다 :
- HTTP : 80
- HTTPS : 443
- SSH : 22

### Apache 리스닝 포트 변경
Apache 포트 설정은 `/etc/apache2/ports.conf` 파일에서 확인해볼 수 있습니다. 다음 명령어를 입력해서 8080 포트로 설정해봅니다 :
```bash
sudo vim /etc/apache2/ports/conf
```
```conf
Listen 8080
```

그 다음에 VirtualHost를 설정해야합니다. `8080 포트`로부터 요청을 받은 경우, `/var/www/html` 파일을 응답으로 주도록 설정합니다. 다음 명령어를 입력합니다 :
```bash
sudo vim /etc/apache2/sites-available/000-default.conf
```
```conf
<VirtualHost *:8080>
    DocumentRoot /var/www/html
</VirtualHost>
```

그런 다음, Apache를 재시작합니다 :
```bash
sudo systemctl restart apache2
```

> 🥕 현재 Azure Virtual Machine 서비스를 활용하고 있기 때문에, Azure NSG에 8080 포트 인바운드 허용 규칙이 설정되어있는지 확인해야합니다.

이제 `http://<Azure_VM_Public_IP>:8080`으로 접속해보면, 수정했던 내용대로 HTML 페이지가 응답함을 알 수 있습니다.

## 도메인 개념 & /etc/hosts

### 도메인의 역할
- 사람이 기억하기 쉬운 이름을 IP 주소로 변환
- 실제 서비스에서는 DNS 서버가 해당 역할을 수행

### /etc/hosts 파일의 특징
- 로컬 머신에서 DNS보다 우선 적용
- 해당 머신에만 적용

### /etc/hosts 수정
```bash
sudo vim /etc/hosts
```

맨 아래에 다음 내용을 추가합니다 :
```text
<Azure_VM_Public_IP> mytest.local
```

> 🥕 `curl ipinfo.io/ip` 명령어를 입력하면 퍼블릭 IP를 확인할 수 있습니다.

이제 테스트를 해봅니다 :
```bash
curl http://mytest.local
```

정상 응답을 확인할 수 있습니다. 다만, `/etc/hosts`는 DNS를 사용하지 않고 로컬에서 도메인을 사용해보기 위한 방법입니다. 따라서 다른 컴퓨터에서는 동작하지 않습니다(로컬 설정이기 때문)



