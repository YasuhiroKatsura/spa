# test
resource "aws_cognito_user_pool" "auth" {
  name = "${var.common.project_name}"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_identity_provider" "auth" {
  user_pool_id  = aws_cognito_user_pool.auth.id
  provider_name = "EntraID"
  provider_type = "OIDC"

  provider_details = {
    client_id                 = var.auth_cognito_conf.entra_client_id
    oidc_issuer               = var.auth_cognito_conf.entra_oidc_issuer_url
    authorize_url             = var.auth_cognito_conf.entra_oidc_authorize_url
    token_url                 = var.auth_cognito_conf.entra_oidc_token_url
    jwks_uri                  = var.auth_cognito_conf.entra_oidc_jwks_url
    attributes_url            = var.auth_cognito_conf.entra_oidc_userinfo_url
    client_secret             = var.entra_client_secret
    authorize_scopes          = "openid email profile"
    attributes_request_method = "GET"
  }

  attribute_mapping = {
    email    = "email"
    name     = "name"
    username = "sub"
  }
}

resource "aws_cognito_user_pool_client" "auth" {
  name         = "${var.common.project_name}"
  user_pool_id = aws_cognito_user_pool.auth.id

  generate_secret = false

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  callback_urls                        = ["http://localhost:8080/"]
  logout_urls                          = ["http://localhost:8080/"]
  supported_identity_providers         = ["COGNITO", aws_cognito_identity_provider.auth.provider_name]
}

resource "aws_cognito_user_pool_domain" "auth" {
  domain       = "${var.common.project_name}-auth"
  user_pool_id = aws_cognito_user_pool.auth.id
}

resource "aws_cognito_managed_login_branding" "auth" {
  user_pool_id                = aws_cognito_user_pool.auth.id
  client_id                   = aws_cognito_user_pool_client.auth.id
  use_cognito_provided_values = true
}
