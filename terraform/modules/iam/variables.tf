variable "iam_conf" {
  type = object({
    roles = map(object({
      name                = string
      description         = string
      assume_role_service = string
    }))
    inline_policies = map(object({
      name        = string
      role_key    = string
      inline_policy_file = string
    }))
    managed_policy_attachments = map(object({
      role_key   = string
      policy_arn = string
    }))
  })
}
