module "network" {
  source = "../../modules/network"

  common  = var.common
  network = var.network
}

module "database" {
  source = "../../modules/database"

  common = var.common
  vpc_id = module.network.vpc.id
  subnet_ids = [
    module.network.ids.private_subnet_ids_by_name.aurora_a,
    module.network.ids.private_subnet_ids_by_name.aurora_c,
  ]
  security_group_id = module.network.ids.security_group_ids.database
  settings          = var.spa_db
}

module "api" {
  source = "../../modules/api"

  common = var.common
  vpc_id = module.network.vpc.id
  alb_subnet_ids = [
    module.network.ids.private_subnet_ids_by_name.alb_a,
    module.network.ids.private_subnet_ids_by_name.alb_c,
  ]
  ecs_subnet_ids = [module.network.ids.private_subnet_ids_by_name.ecs_a]
  security_group_ids = {
    api_tasks = module.network.ids.security_group_ids.api_tasks
    api_alb   = module.network.ids.security_group_ids.api_alb
  }
  database = module.database.connection
  settings = var.spa_api
}

module "api_gateway" {
  source = "../../modules/api_gateway"

  common = var.common
  private_subnet_ids = [
    module.network.ids.private_subnet_ids_by_name.alb_a,
    module.network.ids.private_subnet_ids_by_name.alb_c,
  ]
  api_listener_arn           = module.api.alb_listener_arn
  vpc_link_security_group_id = module.network.ids.security_group_ids.api_gateway_vpc_link
  settings                   = var.spa_apigw
}

module "frontend" {
  source = "../../modules/frontend"

  common            = var.common
  vpc_id            = module.network.vpc.id
  public_subnet_ids = module.network.ids.public_subnet_ids
  security_group_ids = {
    alb      = module.network.ids.security_group_ids.frontend_alb
    endpoint = module.network.ids.security_group_ids.frontend_endpoint
  }
}

module "auth" {
  source = "../../modules/auth"

  common                   = var.common
  entra_tenant_id          = var.entra_tenant_id
  entra_oidc_issuer_url    = var.entra_oidc_issuer_url
  entra_oidc_authorize_url = var.entra_oidc_authorize_url
  entra_oidc_token_url     = var.entra_oidc_token_url
  entra_oidc_jwks_url      = var.entra_oidc_jwks_url
  entra_oidc_userinfo_url  = var.entra_oidc_userinfo_url
  entra_client_id          = var.entra_client_id
  entra_client_secret      = var.entra_client_secret
  cognito_domain_prefix    = var.cognito_domain_prefix
  cognito_callback_urls    = var.cognito_callback_urls
  cognito_logout_urls      = var.cognito_logout_urls
}