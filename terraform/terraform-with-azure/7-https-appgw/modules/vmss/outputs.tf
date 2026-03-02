# ============================================================================
# VMSS Module Outputs
# ============================================================================

output "vmss_id" {
  description = "VMSS ID"
  value       = azurerm_linux_virtual_machine_scale_set.this.id
}

output "vmss_name" {
  description = "VMSS 이름"
  value       = azurerm_linux_virtual_machine_scale_set.this.name
}

output "vmss_unique_id" {
  description = "VMSS Unique ID"
  value       = azurerm_linux_virtual_machine_scale_set.this.unique_id
}

output "autoscale_setting_id" {
  description = "Auto Scaling 설정 ID"
  value       = azurerm_monitor_autoscale_setting.this.id
}
