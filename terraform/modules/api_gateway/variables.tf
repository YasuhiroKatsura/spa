variable "common" {
  type = object({
    project_name = string
    region       = string
  })
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "api_listener_arn" {
  type = string
}

variable "api_alb_security_group_id" {
  type = string
}

variable "settings" {
  type = object({
    stage       = string
    auto_deploy = bool
  })
}
