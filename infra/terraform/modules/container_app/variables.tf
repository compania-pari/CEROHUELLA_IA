variable "name" {
  description = "Container App name."
  type        = string
}

variable "resource_group_name" {
  description = "Resource group name."
  type        = string
}

variable "container_app_environment_id" {
  description = "Container Apps Environment ID."
  type        = string
}

variable "revision_mode" {
  description = "Container App revision mode."
  type        = string
  default     = "Single"
}

variable "identity_id" {
  description = "User-assigned managed identity ID."
  type        = string
}

variable "registry_server" {
  description = "Container registry login server."
  type        = string
}

variable "secrets" {
  description = "Container App secrets. Keys must match Azure Container Apps secret naming rules."
  type        = map(string)
  default     = {}
  sensitive   = true
}

variable "env" {
  description = "Plain environment variables."
  type        = map(string)
  default     = {}
}

variable "secret_env" {
  description = "Environment variables backed by Container App secret names."
  type        = map(string)
  default     = {}
}

variable "container_name" {
  description = "Container name."
  type        = string
  default     = "api"
}

variable "image" {
  description = "Initial container image."
  type        = string
}

variable "cpu" {
  description = "CPU allocated to the container."
  type        = number
  default     = 0.5
}

variable "memory" {
  description = "Memory allocated to the container."
  type        = string
  default     = "1Gi"
}

variable "min_replicas" {
  description = "Minimum replicas."
  type        = number
  default     = 0
}

variable "max_replicas" {
  description = "Maximum replicas."
  type        = number
  default     = 1
}

variable "ingress_enabled" {
  description = "Whether ingress is configured."
  type        = bool
  default     = true
}

variable "ingress_external_enabled" {
  description = "Whether ingress is externally reachable."
  type        = bool
  default     = true
}

variable "ingress_transport" {
  description = "Ingress transport."
  type        = string
  default     = "auto"
}

variable "target_port" {
  description = "Container target port."
  type        = number
  default     = 8000
}

variable "tags" {
  description = "Tags applied to the Container App."
  type        = map(string)
  default     = {}
}

