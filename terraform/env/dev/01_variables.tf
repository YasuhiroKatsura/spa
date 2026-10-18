variable "common" {
  type = object({
    project_name = string
    env          = string
    region       = string
  })
}

variable "vpc_conf" {
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

variable "sg_conf" {
  type = map(object({
    name        = string
    description = string
    ingress_rules = optional(map(object({
      description                   = string
      ip_protocol                   = string
      from_port                     = optional(number)
      to_port                       = optional(number)
      cidr_ipv4                     = optional(list(string)) # SGで制御する場合はnullに設定
      referenced_security_group_key = optional(string)       # CIDRで制御する場合はnullに設定
    })), {})
    egress_rules = optional(map(object({
      description                   = string
      ip_protocol                   = string
      from_port                     = optional(number)
      to_port                       = optional(number)
      cidr_ipv4                     = optional(list(string)) # SGで制御する場合はnullに設定
      referenced_security_group_key = optional(string)       # CIDRで制御する場合はnullに設定
    })), {})
  }))
}

variable "iam_conf" {
  type = object({
    roles = map(object({ # IAM Roleの定義
      name                    = string
      description             = string
      assume_role_policy_file = string
      assume_role_service     = string # IAM Roleを引き受けるサービスのARN
    }))

    inline_policies = map(object({ # インラインポリシーの定義
      name               = string
      role_key           = string # Policyの埋め込み対象となるIAM Roleのキー
      inline_policy_file = string
    }))

    # custom_policies = map(object({ # カスタマー管理ポリシーの定義
    #   name        = string
    #   policy_file = string
    # }))

    managed_policy_attachments = map(object({ # AWS管理ポリシー/カスタマー管理ポリシーの紐づけ
      role_key   = string
      policy_arn = string
    }))
  })
}
