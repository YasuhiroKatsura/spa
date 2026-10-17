variable "common" {
  type = object({
    project_name = string
    region       = string
  })
}

variable "vpc_id" {
  type = string
}

variable "alb_subnet_ids" {
  type = list(string)
}

variable "ecs_subnet_ids" {
  type = list(string)
}

variable "security_group_ids" {
  type = object({
    api_tasks = string
    api_alb   = string
  })
}

variable "database" {
  type = object({
    endpoint        = string
    port            = number
    database_name   = string
    master_username = string
    secret_arn      = string
  })
}

variable "settings" {
  type = object({
    task_cpu      = number
    task_memory   = number
    image_tag     = string
    desired_count = number
  })
}
