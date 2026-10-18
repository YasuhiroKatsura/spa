output "arn" {
  value = {
    for key, role in aws_iam_role.role : key => role.arn
  }
}
