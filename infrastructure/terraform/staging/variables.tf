
#--- Parameterized staging configuration ---
variable "project_name" {
  description = "Application project identifier"
  type        = string
  default     = "itsd4350"
}

variable "environment" {
  description = "Deployment environment"
  type        = string
  default     = "staging"
}

variable "docker_image" {
  description = "Prebuilt Docker application image"
  type        = string
  default     = "itsd4350-staging-app:1.0"
}

variable "container_port" {
  description = "Application port inside the container"
  type        = number
  default     = 8000
}

variable "host_port" {
  description = "Port exposed on the staging host"
  type        = number
  default     = 8000
}
