# -----変数定義-----
variable "apigw" {
  type = map(string)
  default = {
    name = "spa"
    stage = "dev"
    auto_deploy = "true"
  }
}

# -----API Gateway v2 (HTTP API)-----
resource "aws_apigatewayv2_api" "spa" {
  name          = "${var.apigw.name}"
  protocol_type = "HTTP"
}

resource "aws_apigatewayv2_stage" "spa" {
  api_id      = aws_apigatewayv2_api.spa.id
  name        = "${var.apigw.stage}"
  auto_deploy = var.apigw.auto_deploy
}

resource "aws_apigatewayv2_integration" "api_connectivity_test_httpbin" {
  api_id             = aws_apigatewayv2_api.spa.id
  integration_type   = "HTTP_PROXY"
  integration_method = "ANY"
  integration_uri    = "https://httpbin.org/anything"

  payload_format_version = "1.0"
  timeout_milliseconds   = 29000
}