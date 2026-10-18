moved {
  from = aws_apigatewayv2_api.api
  to   = aws_apigatewayv2_api.api[0]
}

moved {
  from = aws_apigatewayv2_stage.api
  to   = aws_apigatewayv2_stage.api[0]
}

moved {
  from = aws_apigatewayv2_route.api
  to   = aws_apigatewayv2_route.api[0]
}

moved {
  from = aws_apigatewayv2_integration.api
  to   = aws_apigatewayv2_integration.api[0]
}

moved {
  from = aws_apigatewayv2_vpc_link.api
  to   = aws_apigatewayv2_vpc_link.api[0]
}

moved {
  from = aws_lb.api
  to   = aws_lb.api[0]
}

moved {
  from = aws_lb_target_group.api
  to   = aws_lb_target_group.api[0]
}

moved {
  from = aws_lb_listener.api
  to   = aws_lb_listener.api[0]
}

moved {
  from = aws_ecs_task_definition.api_main
  to   = aws_ecs_task_definition.api_main[0]
}

moved {
  from = aws_ecs_service.api_main
  to   = aws_ecs_service.api_main[0]
}

moved {
  from = aws_rds_cluster.database
  to   = aws_rds_cluster.database[0]
}

moved {
  from = aws_db_subnet_group.database
  to   = aws_db_subnet_group.database[0]
}

moved {
  from = aws_s3_bucket.frontend
  to   = aws_s3_bucket.frontend[0]
}

moved {
  from = aws_s3_bucket_versioning.frontend
  to   = aws_s3_bucket_versioning.frontend[0]
}

moved {
  from = aws_s3_bucket_public_access_block.frontend
  to   = aws_s3_bucket_public_access_block.frontend[0]
}

moved {
  from = aws_s3_bucket_policy.frontend
  to   = aws_s3_bucket_policy.frontend[0]
}

moved {
  from = aws_vpc_endpoint.s3
  to   = aws_vpc_endpoint.s3[0]
}

moved {
  from = aws_lb.frontend
  to   = aws_lb.frontend[0]
}

moved {
  from = aws_lb_listener.frontend
  to   = aws_lb_listener.frontend[0]
}

moved {
  from = aws_lb_target_group.frontend
  to   = aws_lb_target_group.frontend[0]
}
