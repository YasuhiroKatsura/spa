variable "alb_name" {
  type        = string
  default     = "main-alb"
  description = "ALBの名前"
}

variable "is_internal" {
  type        = bool
  default     = false
  description = "内部向けALBにするかどうか (falseでInternet-facing)"
}

variable "security_groups" {
  type        = list(string)
  description = "ALBに適用するセキュリティグループIDのリスト"
  # 必須項目のため default はあえて設定していません
}

variable "subnet_ids" {
  type        = list(string)
  description = "ALBを配置するサブネットIDのリスト（Internet-facingの場合はパブリックサブネット）"
  # 必須項目のため default はあえて設定していません
}

variable "enable_deletion_protection" {
  type        = bool
  default     = false
  description = "削除保護を有効にするか"
}

variable "http_listener_port" {
  type        = string
  default     = "80"
  description = "HTTPリスナーのポート"
}

variable "default_response_message" {
  type        = string
  default     = "Not Found (Managed by Terraform)"
  description = "デフォルトアクションで返すメッセージ"
}

variable "default_response_status_code" {
  type        = string
  default     = "404"
  description = "デフォルトアクションで返すステータスコード"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "リソースに付与するタグ"
}

variable "listener_rules" {
  description = "ALBリスナールールの設定。priorityを名前などの一意のキーにしたマップで定義します。"
  type = map(object({
    priority = number
    action = object({
      type             = string
      target_group_arn = optional(string)
      redirect = optional(object({
        host        = optional(string)
        path        = optional(string)
        port        = optional(string)
        protocol    = optional(string)
        status_code = string
      }))
    })
    condition = object({
      path_pattern = optional(list(string))
      host_header  = optional(list(string))
    })
  }))
  default = {}
}