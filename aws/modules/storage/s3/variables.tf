variable "bucket_name" {
  type        = string
  default     = ""
  description = "S3バケット名"
}

variable "bucket_versioning" {
  type        = string
  default     = "Disabled"
  description = "バージョニングの有無"
}

variable "block_public_acls" {
  type        = bool
  default     = "true"
  description = "public公開ACLの新規作成を禁止する"
}

variable "ignore_public_acls" {
  type        = bool
  default     = "true"
  description = "既存のpublic公開ACLを無視する"
}

variable "block_public_policy" {
  type        = bool
  default     = "true"
  description = "Principal:*に設定されたバケットポリシーの作成を禁止する"
}

variable "restrict_public_buckets" {
  type        = bool
  default     = "true"
  description = "Principal:*に設定された既存バケットポリシーを無視する"
}