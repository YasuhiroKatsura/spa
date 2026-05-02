# -----変数定義-----
variable "s3" {
  type = map(string)
  default = {
    bucket_name= "spa-y-okamura-dev-2026"
  }
}


#-----S3バケット-----
resource "aws_s3_bucket" "spa" {
  bucket = var.s3.bucket_name
}

resource "aws_s3_bucket_versioning" "spa" {
  bucket = aws_s3_bucket.spa.id
  versioning_configuration {
    status = "Disabled"
  }
}

resource "aws_s3_bucket_public_access_block" "spa" {
  bucket                  = aws_s3_bucket.spa.id
  block_public_acls       = "true" # public公開ACLの新規作成を禁止する
  ignore_public_acls      = "true" # 既存のpublic公開ACLを無視する
  block_public_policy     = "false" # Principal:*に設定されたバケットポリシーの作成を禁止しない(個人利用だし...)
  restrict_public_buckets = "false" # Principal:*に設定された既存バケットポリシーを無視しない
}

#-----バケットポリシー-----
resource "aws_s3_bucket_policy" "spa" {
  bucket = aws_s3_bucket.spa.id
  policy = templatefile(
    "./03_bucket_policy_AllowVpcEndpointAccess.json",
    {
      bucket_name = aws_s3_bucket.spa.bucket,
      vpc_endpoint_id = aws_vpc_endpoint.s3_spa.id
    }
  )
}

# -----VPCエンドポイント-----
resource "aws_vpc_endpoint" "s3_spa" {
  vpc_id             = data.terraform_remote_state.landing_zone.outputs.ids.vpc_id
  service_name       = "com.amazonaws.ap-northeast-1.s3"
  vpc_endpoint_type  = "Interface"
  subnet_ids         = data.terraform_remote_state.landing_zone.outputs.ids.public_subnet_ids
  security_group_ids = [aws_security_group.s3_endpoint.id]
}


# -----S3エンドポイントのネットワークインターフェース取得-----
data "aws_network_interface" "s3_endpoint" {
  id = tolist(aws_vpc_endpoint.s3_spa.network_interface_ids)[0]
}

# -----S3エンドポイント用セキュリティグループ-----
resource "aws_security_group" "s3_endpoint" {
  name        = "${var.s3.bucket_name}-s3-endpoint-sg"
  vpc_id      = data.terraform_remote_state.landing_zone.outputs.ids.vpc_id

  # ALBからのHTTPSを許可
  ingress {
    from_port       = "443"
    to_port         = "443"
    protocol        = "tcp"
    security_groups = [aws_security_group.alb.id]
  }
}