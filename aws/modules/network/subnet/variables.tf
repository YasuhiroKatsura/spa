variable "vpc_id" {
  type        = string
  description = "サブネットを作成するVPCのID"
}

variable "igw_id" {
  type        = string
  description = "ルートテーブルに紐付けるIGWのID"
}

variable "subnet_cidr" {
  type        = string
  description = "サブネットのCIDRブロック"
}

variable "az" {
  type        = string
  description = "配置するアベイラビリティゾーン"
}

variable "subnet_name" {
  type        = string
  description = "サブネットの名前"
}

variable "map_public_ip_on_launch" {
  type        = bool
  default     = true
  description = "パブリックIPを自動割り当てするか（ALB用パブリックサブネットならtrue）"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "リソースに付与するタグ"
}