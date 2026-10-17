variable "common" {
  type = object({
    project_name = string
    region       = string
  })
}

variable "network" {
  type = object({
    vpc = object({
      cidr_block = string
    })
    public_subnets = map(object({
      cidr_block = string
    }))
    private_subnets = map(object({
      cidr_block = string
    }))
  })
}
