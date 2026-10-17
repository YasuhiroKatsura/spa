moved {
  from = module.network.aws_security_group.api_tasks
  to   = module.container.aws_security_group.api_tasks
}

moved {
  from = module.network.aws_security_group.api_alb
  to   = module.container.aws_security_group.api_alb
}

moved {
  from = module.network.aws_security_group.api_gateway_vpc_link
  to   = module.api_gateway.aws_security_group.vpc_link
}

moved {
  from = module.network.aws_security_group.database
  to   = module.database.aws_security_group.database
}

moved {
  from = module.network.aws_security_group.frontend_alb
  to   = module.frontend.aws_security_group.alb
}

moved {
  from = module.network.aws_security_group.frontend_endpoint
  to   = module.frontend.aws_security_group.endpoint
}

moved {
  from = module.network.aws_vpc_security_group_ingress_rule.api_alb_from_vpc_link
  to   = module.api_gateway.aws_vpc_security_group_ingress_rule.api_alb_from_vpc_link
}

moved {
  from = module.network.aws_vpc_security_group_egress_rule.api_alb_all
  to   = module.container.aws_vpc_security_group_egress_rule.api_alb_all
}

moved {
  from = module.network.aws_vpc_security_group_ingress_rule.api_tasks_from_alb
  to   = module.container.aws_vpc_security_group_ingress_rule.api_tasks_from_alb
}

moved {
  from = module.network.aws_vpc_security_group_egress_rule.api_tasks_all
  to   = module.container.aws_vpc_security_group_egress_rule.api_tasks_all
}

moved {
  from = module.network.aws_vpc_security_group_egress_rule.api_gateway_to_alb
  to   = module.api_gateway.aws_vpc_security_group_egress_rule.vpc_link_to_alb
}

moved {
  from = module.network.aws_vpc_security_group_ingress_rule.database_from_api
  to   = module.container.aws_vpc_security_group_ingress_rule.database_from_api
}

moved {
  from = module.network.aws_vpc_security_group_egress_rule.database_all
  to   = module.database.aws_vpc_security_group_egress_rule.database_all
}

moved {
  from = module.network.aws_vpc_security_group_ingress_rule.frontend_endpoint_from_alb
  to   = module.frontend.aws_vpc_security_group_ingress_rule.endpoint_from_alb
}

moved {
  from = module.network.aws_vpc_security_group_egress_rule.frontend_endpoint_all
  to   = module.frontend.aws_vpc_security_group_egress_rule.endpoint_all
}

moved {
  from = module.network.aws_vpc_security_group_ingress_rule.frontend_alb_http
  to   = module.frontend.aws_vpc_security_group_ingress_rule.alb_http
}

moved {
  from = module.network.aws_vpc_security_group_egress_rule.frontend_alb_all
  to   = module.frontend.aws_vpc_security_group_egress_rule.alb_all
}

module "network" {
  source  = "../../modules/network"
  common  = var.common
  network = var.network_conf
}

module "frontend" {
  source = "../../modules/frontend"

  common            = var.common
  vpc_id            = module.network.vpc.id
  public_subnet_ids = module.network.subnet.public_subnet_ids
}

module "database" {
  source = "../../modules/database"

  common = var.common
  vpc_id = module.network.vpc.id
  subnet_ids = [
    module.network.subnet.private_subnet_ids_by_name.aurora_a,
    module.network.subnet.private_subnet_ids_by_name.aurora_c,
  ]
  settings = var.db_conf
}

module "container" {
  source = "../../modules/container"

  common = var.common
  vpc_id = module.network.vpc.id
  alb_subnet_ids = [
    module.network.subnet.private_subnet_ids_by_name.alb_a,
    module.network.subnet.private_subnet_ids_by_name.alb_c,
  ]
  ecs_subnet_ids = [module.network.subnet.private_subnet_ids_by_name.ecs_a]
  database       = module.database.connection
  settings       = var.container_conf
}

module "api_gateway" {
  source = "../../modules/api_gateway"

  common = var.common
  vpc_id = module.network.vpc.id
  private_subnet_ids = [
    module.network.subnet.private_subnet_ids_by_name.alb_a,
    module.network.subnet.private_subnet_ids_by_name.alb_c,
  ]
  api_listener_arn          = module.container.alb_listener_arn
  api_alb_security_group_id = module.container.security_group_ids.api_alb
  settings                  = var.apigw_conf
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