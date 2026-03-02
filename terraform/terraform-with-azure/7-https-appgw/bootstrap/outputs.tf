# ============================================================================
# Bootstrap Outputs: 생성된 리소스 정보를 출력
# ============================================================================
# 이 출력값들은 environments/dev/backend.tf에서 사용됩니다.
# ============================================================================

output "resource_group_name" {
  description = "상태 파일을 저장하는 Resource Group 이름"
  value       = azurerm_resource_group.tfstate.name
}

output "storage_account_name" {
  description = "상태 파일을 저장하는 Storage Account 이름"
  value       = azurerm_storage_account.tfstate.name
}

output "container_name" {
  description = "상태 파일을 저장하는 Container 이름"
  value       = azurerm_storage_container.tfstate.name
}

output "primary_access_key" {
  description = "Storage Account의 Primary Access Key (환경변수로 설정 필요)"
  value       = azurerm_storage_account.tfstate.primary_access_key
  sensitive   = true
}

output "backend_config_example" {
  description = "environments/dev/backend.tf에 사용할 설정 예시"
  value       = <<-EOT

    ╔════════════════════════════════════════════════════════════════════╗
    ║  다음 내용을 environments/dev/backend.tf에 복사하세요:              ║
    ╚════════════════════════════════════════════════════════════════════╝

    terraform {
      backend "azurerm" {
        resource_group_name  = "${azurerm_resource_group.tfstate.name}"
        storage_account_name = "${azurerm_storage_account.tfstate.name}"
        container_name       = "${azurerm_storage_container.tfstate.name}"
        key                  = "dev.terraform.tfstate"
      }
    }

    ╔════════════════════════════════════════════════════════════════════╗
    ║  Access Key를 환경변수로 설정:                                      ║
    ╚════════════════════════════════════════════════════════════════════╝

    export ARM_ACCESS_KEY="$(terraform output -raw primary_access_key)"
  EOT
}
