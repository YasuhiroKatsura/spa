variable "common" {
  type = object({
    project_name = string
    region       = string
  })
}

variable "public_subnet_ids" {
  type = list(string)
}

variable "vpc_id" {
  type = string
}

variable "security_group_ids" {
  type = object({
    alb      = string
    endpoint = string
  })
}
