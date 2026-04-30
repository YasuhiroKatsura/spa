variable "vpc_id" {
  type        = string
  description = "セキュリティグループを作成するVPCのID"
}

variable "sg_name" {
  type        = string
  default     = "alb-sg"
  description = "セキュリティグループの名前"
}

variable "sg_description" {
  type        = string
  default     = "Security group for ALB"
  description = "セキュリティグループの説明"
}

variable "ingress_port" {
  type        = number
  default     = 80
  description = "インバウンドで許可するポート番号"
}

variable "ingress_protocol" {
  type        = string
  default     = "tcp"
  description = "インバウンドで許可するプロトコル"
}

variable "allowed_cidr_blocks" {
  type        = list(string)
  default     = ["0.0.0.0/0"]
  description = "アクセスを許可するCIDRブロック"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "リソースに付与するタグ"
}