variable "vpc_cidr" {
  type        = string
  default     = "10.0.0.0/16"
  description = "VPCのCIDRブロック"
}

variable "vpc_name" {
  type        = string
  default     = "main-vpc"
  description = "VPCの名前"
}

variable "enable_dns_support" {
  type        = bool
  default     = true
  description = "DNSサポートを有効にするか"
}

variable "enable_dns_hostnames" {
  type        = bool
  default     = true
  description = "DNSホスト名を有効にするか"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "リソースに付与するタグ"
}