variable "common" {
  type = object({
    project_name = string
    region       = string
  })
}

variable "vpc_id" {
  type = string
}

variable "sg_conf" {
  type = map(object({
    name        = string
    description = string
    ingress_rules = optional(map(object({
      description                   = string
      ip_protocol                   = string
      from_port                     = optional(number)
      to_port                       = optional(number)
      cidr_ipv4                     = optional(string)
      referenced_security_group_key = optional(string)
    })), {})
    egress_rules = optional(map(object({
      description                   = string
      ip_protocol                   = string
      from_port                     = optional(number)
      to_port                       = optional(number)
      cidr_ipv4                     = optional(string)
      referenced_security_group_key = optional(string)
    })), {})
  }))

  validation {
    condition = alltrue(flatten([
      for security_group in values(var.sg_conf) : [
        for rule in concat(values(security_group.ingress_rules), values(security_group.egress_rules)) :
        ((rule.cidr_ipv4 != null) != (rule.referenced_security_group_key != null)) &&
        (rule.referenced_security_group_key == null || contains(keys(var.sg_conf), rule.referenced_security_group_key))
      ]
    ]))
    error_message = "Each rule must specify exactly one CIDR or valid referenced security group."
  }
}
