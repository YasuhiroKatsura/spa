variable "vpc_id" {
  type        = string
  description = "IGWをアタッチするVPCのID"
}

variable "igw_name" {
  type        = string
  default     = "main-igw"
  description = "IGWの名前"
}

variable "tags" {
  type        = map(string)
  default     = {}
  description = "リソースに付与するタグ"
}