# Terraform 초기화 (backend.tfvars 사용)

이 문서는 `backend.tf`로 선언된 백엔드를 `backend.tfvars` 파일을 사용해 초기화(`terraform init`)하는 방법을 정리합니다.

## 기본 명령

`backend.tf`와 `backend.tfvars`가 있는 디렉터리에서 실행합니다:

```bash
cd 6-vmss-lb/environments/dev
terraform init -backend-config=backend.tfvars
```

## 자주 쓰는 옵션

- 기존 백엔드 설정을 무시하고 재구성할 때:

```bash
terraform init -backend-config=backend.tfvars -reconfigure
```

- 여러 `-backend-config` 사용 예시 (파일 또는 키=값):

```bash
terraform init \
  -backend-config=backend.tfvars \
  -backend-config=../common.backend.tfvars \
  -backend-config="key=env/dev.tfstate"
```

- 개별 키=값 전달 (파일 대신 민감한 값을 CLI로 전달할 때 사용):

```bash
terraform init \
  -backend-config="storage_account_name=myacct" \
  -backend-config="container_name=tfstate" \
  -backend-config="key=6-vmss-lb-dev.tfstate"
```

## 파일 경로 지정
- 상대/절대 경로 모두 사용 가능:

```bash
terraform init -backend-config=/full/path/to/backend.tfvars
```

## 주의사항 및 권장사항
- `backend.tf`는 백엔드 타입(예: `azurerm`)과 블록 구조를 선언합니다. `backend.tfvars`에는 `storage_account_name`, `container_name`, `key`, `resource_group_name` 등 실제 값이 들어갑니다.
- 민감 정보(예: 스토리지 계정 키, 서비스 프린시펄 비밀)는 리포지토리에 커밋하지 마세요. 가능한 경우 다음 중 하나를 사용하세요:
  - 백엔드 설정 파일을 리포지토리 외부(예: ~/.tf/backend.tfvars)로 두기
  - CI 비밀(Secrets)을 사용하고 CI에서 `-backend-config="key=value"`로 전달
  - Azure 경우 `az login`/Managed Identity 방식으로 인증하고 스토리지 키 대신 권한으로 접근
- 백엔드를 변경하거나 상태 위치를 옮길 때는 `-reconfigure`를 사용해 재구성하세요.
- 초기화 성공 시 출력에서 `Terraform has been successfully initialized!`를 확인하세요.

## 예시 (Azure Storage backend)

`backend.tf`에는 다음과 같이 선언되어 있을 수 있습니다:

```hcl
terraform {
  backend "azurerm" {}
}
```

그리고 `backend.tfvars` 예시 (커밋하지 않음):

```hcl
storage_account_name = "mystorageacct"
container_name       = "tfstate"
key                  = "6-vmss-lb/dev.terraform.tfstate"
resource_group_name  = "rg-terraform"
```

이제 `terraform init -backend-config=backend.tfvars`를 실행하면 해당 백엔드 설정으로 상태가 초기화됩니다.

---
파일: 6-vmss-lb/docs/init.md
