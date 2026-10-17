variable "common" {
  type = object({
    project_name = string
    region       = string
  })
}

variable "private_subnet_ids" {
  type = list(string)
}

variable "api_listener_arn" {
  type = string
}

variable "vpc_link_security_group_id" {
  type = string
}

variable "settings" {
  type = object({
    stage       = string
    auto_deploy = bool
  })
}
