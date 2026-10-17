variable "common" {
  type = object({
    project_name = string
    region       = string
  })
}

variable "vpc_id" {
  type = string
}

variable "subnet_ids" {
  type = list(string)
}

variable "settings" {
  type = object({
    engine_version               = string
    instance_class               = string
    instance_count               = number
    backup_retention_days        = number
    deletion_protection          = bool
    skip_final_snapshot          = bool
    performance_insights_enabled = bool
  })
}
