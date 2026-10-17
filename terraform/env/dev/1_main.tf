moved {
  from = module.network.aws_vpc.this
  to   = module.vpc.aws_vpc.this
}

moved {
  from = module.network.aws_subnet.public
  to   = module.vpc.aws_subnet.public
}

moved {
  from = module.network.aws_subnet.private
  to   = module.vpc.aws_subnet.private
}

moved {
  from = module.network.aws_internet_gateway.this
  to   = module.vpc.aws_internet_gateway.this
}

moved {
  from = module.network.aws_route_table.public
  to   = module.vpc.aws_route_table.public
}

moved {
  from = module.network.aws_route_table_association.public
  to   = module.vpc.aws_route_table_association.public
}

moved {
  from = module.network.aws_route_table.private
  to   = module.vpc.aws_route_table.private
}

moved {
  from = module.network.aws_route_table_association.private
  to   = module.vpc.aws_route_table_association.private
}

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

moved {
  from = module.container.aws_security_group.api_tasks
  to   = module.sg.aws_security_group.api_tasks
}

moved {
  from = module.container.aws_security_group.api_alb
  to   = module.sg.aws_security_group.api_alb
}

moved {
  from = module.api_gateway.aws_security_group.vpc_link
  to   = module.sg.aws_security_group.api_gateway_vpc_link
}

moved {
  from = module.database.aws_security_group.database
  to   = module.sg.aws_security_group.database
}

moved {
  from = module.frontend.aws_security_group.alb
  to   = module.sg.aws_security_group.frontend_alb
}

moved {
  from = module.frontend.aws_security_group.endpoint
  to   = module.sg.aws_security_group.frontend_endpoint
}

moved {
  from = module.api_gateway.aws_vpc_security_group_ingress_rule.api_alb_from_vpc_link
  to   = module.sg.aws_vpc_security_group_ingress_rule.api_alb_from_vpc_link
}

moved {
  from = module.container.aws_vpc_security_group_egress_rule.api_alb_all
  to   = module.sg.aws_vpc_security_group_egress_rule.api_alb_all
}

moved {
  from = module.container.aws_vpc_security_group_ingress_rule.api_tasks_from_alb
  to   = module.sg.aws_vpc_security_group_ingress_rule.api_tasks_from_alb
}

moved {
  from = module.container.aws_vpc_security_group_egress_rule.api_tasks_all
  to   = module.sg.aws_vpc_security_group_egress_rule.api_tasks_all
}

moved {
  from = module.api_gateway.aws_vpc_security_group_egress_rule.vpc_link_to_alb
  to   = module.sg.aws_vpc_security_group_egress_rule.api_gateway_to_alb
}

moved {
  from = module.container.aws_vpc_security_group_ingress_rule.database_from_api
  to   = module.sg.aws_vpc_security_group_ingress_rule.database_from_api
}

moved {
  from = module.database.aws_vpc_security_group_egress_rule.database_all
  to   = module.sg.aws_vpc_security_group_egress_rule.database_all
}

moved {
  from = module.frontend.aws_vpc_security_group_ingress_rule.endpoint_from_alb
  to   = module.sg.aws_vpc_security_group_ingress_rule.frontend_endpoint_from_alb
}

moved {
  from = module.frontend.aws_vpc_security_group_egress_rule.endpoint_all
  to   = module.sg.aws_vpc_security_group_egress_rule.frontend_endpoint_all
}

moved {
  from = module.frontend.aws_vpc_security_group_ingress_rule.alb_http
  to   = module.sg.aws_vpc_security_group_ingress_rule.frontend_alb_http
}

moved {
  from = module.frontend.aws_vpc_security_group_egress_rule.alb_all
  to   = module.sg.aws_vpc_security_group_egress_rule.frontend_alb_all
}

moved {
  from = module.container.aws_lb.api
  to   = aws_lb.api
}

moved {
  from = module.container.aws_lb_target_group.api
  to   = aws_lb_target_group.api
}

moved {
  from = module.container.aws_lb_listener.api
  to   = aws_lb_listener.api
}

moved {
  from = module.container.aws_ecs_cluster.api
  to   = aws_ecs_cluster.api
}

moved {
  from = module.container.aws_ecs_task_definition.api
  to   = aws_ecs_task_definition.api
}

moved {
  from = module.container.aws_ecs_service.api
  to   = aws_ecs_service.api
}

moved {
  from = module.container.aws_iam_role.task_execution
  to   = module.iam.aws_iam_role.task_execution
}

moved {
  from = module.container.aws_iam_role_policy_attachment.task_execution
  to   = module.iam.aws_iam_role_policy_attachment.task_execution
}

moved {
  from = module.container.aws_iam_role.task
  to   = module.iam.aws_iam_role.task
}

moved {
  from = module.container.aws_iam_role_policy_attachment.task_ssm
  to   = module.iam.aws_iam_role_policy_attachment.task_ssm
}

moved {
  from = module.container.aws_iam_role_policy.task_ssm_messages
  to   = module.iam.aws_iam_role_policy.task_ssm_messages
}

moved {
  from = module.database.aws_rds_cluster.aurora
  to   = aws_rds_cluster.aurora
}

moved {
  from = module.database.aws_rds_cluster_instance.aurora
  to   = aws_rds_cluster_instance.aurora
}

moved {
  from = module.database.aws_db_subnet_group.aurora
  to   = aws_db_subnet_group.aurora
}

moved {
  from = module.frontend.aws_s3_bucket.frontend
  to   = aws_s3_bucket.frontend
}

moved {
  from = module.frontend.aws_s3_bucket_versioning.frontend
  to   = aws_s3_bucket_versioning.frontend
}

moved {
  from = module.frontend.aws_s3_bucket_public_access_block.frontend
  to   = aws_s3_bucket_public_access_block.frontend
}

moved {
  from = module.frontend.aws_s3_bucket_policy.frontend
  to   = aws_s3_bucket_policy.frontend
}

moved {
  from = module.frontend.aws_vpc_endpoint.s3
  to   = aws_vpc_endpoint.s3
}

moved {
  from = module.frontend.aws_lb.frontend
  to   = aws_lb.frontend
}

moved {
  from = module.frontend.aws_lb_listener.frontend
  to   = aws_lb_listener.frontend
}

moved {
  from = module.frontend.aws_lb_target_group.frontend
  to   = aws_lb_target_group.frontend
}

moved {
  from = module.frontend.aws_lb_target_group_attachment.frontend
  to   = aws_lb_target_group_attachment.frontend
}

moved {
  from = module.api_gateway.aws_apigatewayv2_api.api
  to   = aws_apigatewayv2_api.api
}

moved {
  from = module.api_gateway.aws_apigatewayv2_stage.api
  to   = aws_apigatewayv2_stage.api
}

moved {
  from = module.api_gateway.aws_apigatewayv2_route.default
  to   = aws_apigatewayv2_route.default
}

moved {
  from = module.api_gateway.aws_apigatewayv2_integration.api
  to   = aws_apigatewayv2_integration.api
}

moved {
  from = module.api_gateway.aws_apigatewayv2_vpc_link.api
  to   = aws_apigatewayv2_vpc_link.api
}

moved {
  from = module.auth.aws_cognito_user_pool.spa
  to   = aws_cognito_user_pool.spa
}

moved {
  from = module.auth.aws_cognito_identity_provider.entra
  to   = aws_cognito_identity_provider.entra
}

moved {
  from = module.auth.aws_cognito_user_pool_client.spa
  to   = aws_cognito_user_pool_client.spa
}

moved {
  from = module.auth.aws_cognito_user_pool_domain.spa
  to   = aws_cognito_user_pool_domain.spa
}

moved {
  from = module.auth.aws_cognito_managed_login_branding.spa
  to   = aws_cognito_managed_login_branding.spa
}

module "vpc" {
  source  = "../../modules/vpc"
  common  = local.common
  network = local.network_conf
}

module "iam" {
  source       = "../../modules/iam"
  project_name = local.common.project_name
}

module "sg" {
  source       = "../../modules/sg"
  project_name = local.common.project_name
  vpc_id       = module.vpc.vpc.id
}
