output "frontend_url" {
  description = "Public HTTPS URL for the unauthenticated SPA."
  value       = var.resource_flags.frontend_edge_enabled ? "https://${aws_lb.frontend[0].dns_name}" : null
}

output "api_url" {
  description = "Base URL for the API Gateway HTTP API."
  value       = var.resource_flags.api_stack_enabled ? "${aws_apigatewayv2_api.api[0].api_endpoint}/${aws_apigatewayv2_stage.api[0].name}" : null
}
