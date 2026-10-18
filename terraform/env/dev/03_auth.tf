resource "aws_cognito_user_pool" "spa" {
  name = "${var.common.project_name}-user-pool"

  username_attributes      = ["email"]
  auto_verified_attributes = ["email"]

  account_recovery_setting {
    recovery_mechanism {
      name     = "verified_email"
      priority = 1
    }
  }
}

resource "aws_cognito_identity_provider" "entra" {
  user_pool_id  = aws_cognito_user_pool.spa.id
  provider_name = "EntraID"
  provider_type = "OIDC"

  provider_details = {
    client_id                 = var.entra_client_id
    client_secret             = var.entra_client_secret
    authorize_scopes          = "openid email profile"
    oidc_issuer               = var.entra_oidc_issuer_url
    authorize_url             = var.entra_oidc_authorize_url
    token_url                 = var.entra_oidc_token_url
    jwks_uri                  = var.entra_oidc_jwks_url
    attributes_url            = var.entra_oidc_userinfo_url
    attributes_request_method = "GET"
  }

  attribute_mapping = {
    email    = "email"
    name     = "name"
    username = "sub"
  }
}

resource "aws_cognito_user_pool_client" "spa" {
  name         = "${var.common.project_name}-spa-client"
  user_pool_id = aws_cognito_user_pool.spa.id

  generate_secret = false

  allowed_oauth_flows                  = ["code"]
  allowed_oauth_flows_user_pool_client = true
  allowed_oauth_scopes                 = ["openid", "email", "profile"]
  callback_urls                        = var.cognito_conf.spa.callback_urls
  logout_urls                          = var.cognito_conf.spa.logout_urls
  supported_identity_providers         = ["COGNITO", aws_cognito_identity_provider.entra.provider_name]
}

resource "aws_cognito_user_pool_domain" "spa" {
  domain       = var.cognito_conf.spa.domain_prefix
  user_pool_id = aws_cognito_user_pool.spa.id
}

resource "aws_cognito_managed_login_branding" "spa" {
  user_pool_id                = aws_cognito_user_pool.spa.id
  client_id                   = aws_cognito_user_pool_client.spa.id
  use_cognito_provided_values = true
}
