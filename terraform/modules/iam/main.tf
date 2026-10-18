resource "aws_iam_role" "role" {
  for_each = var.iam_conf.roles

  name        = "${var.common.project_name}-${each.value.name}"
  description = each.value.description

  assume_role_policy = templatefile("${path.root}/templates/${each.value.assume_role_policy_file}", {
    service = each.value.assume_role_service
  })
}

# RoleとAWS管理ポリシー/カスタマー管理ポリシーの紐づけ
resource "aws_iam_role_policy_attachment" "attachment" {
  for_each = var.iam_conf.managed_policy_attachments

  role       = aws_iam_role.role[each.value.role_key].name
  policy_arn = each.value.policy_arn
}

resource "aws_iam_role_policy" "policy" { # Roleとインラインポリシーの紐づけ
  for_each = var.iam_conf.inline_policies

  name   = "${var.common.project_name}-${each.value.name}"
  role   = aws_iam_role.role[each.value.role_key].id
  policy = templatefile("${path.root}/templates/${each.value.inline_policy_file}", {})
}
