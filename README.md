# Apache Web Server 정리(with. Azure VM)

Linux 학습 과정에서 Apache 웹 서버를 직접 설치하고,
설정 파일을 수정하며 네트워크 및 포트 개념까지 함께 실습한 내용을 정리한 문서입니다.

> 🥕 Azure VM CLI에서 작성한 글입니다.

## 실습 환경
- Cloud : Microsoft Azure
- Service : Azure Virtual Machine
- OS : Linux (ubuntu 24.04)
- 크기 : Standard B1s(1개 vcpu, 1GiB 메모리)
- 공용 IP
- Web Server : Apache2
- 접속 방식 : SSH(pem key 사용) or HTTP
- 로컬 환경 : macOS + Terminal
- NSG 설정 : SSH(22), HTTP(80), 커스텀(8080) 인바운드 포트 규칙 추가(Allow용)

## 학습 과정
- [Azure VM 생성 및 아파치 프로그램 설치](./apache/CREATE_AZURE_VM.md)
- [도메인 학습](./apache/DOMAIN.md)
- [rsync 및 SSH](./apache/RSYNC_SSH.md)
