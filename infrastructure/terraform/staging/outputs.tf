
#--- Staging infrastructure outputs ---
output "staging_url" {
  description = "Local staging application URL"
  value       = "http://localhost:${var.host_port}"
}

output "health_check_url" {
  description = "Application health-check endpoint"
  value       = "http://localhost:${var.host_port}/health"
}

output "container_name" {
  description = "Terraform-managed staging container"
  value       = docker_container.staging_app.name
}

output "network_name" {
  description = "Terraform-managed staging network"
  value       = docker_network.staging.name
}
