locals {
  ingress_rules = {
    for rule in flatten([
      for security_group_key, security_group in var.sg_conf : [
        for rule_key, rule in security_group.ingress_rules : {
          key                           = "${security_group_key}.${rule_key}"
          security_group_key            = security_group_key
          description                   = rule.description
          ip_protocol                   = rule.ip_protocol
          from_port                     = rule.from_port
          to_port                       = rule.to_port
          cidr_ipv4                     = rule.cidr_ipv4
          referenced_security_group_key = rule.referenced_security_group_key
        }
      ]
    ]) : rule.key => rule
  }

  egress_rules = {
    for rule in flatten([
      for security_group_key, security_group in var.sg_conf : [
        for rule_key, rule in security_group.egress_rules : {
          key                           = "${security_group_key}.${rule_key}"
          security_group_key            = security_group_key
          description                   = rule.description
          ip_protocol                   = rule.ip_protocol
          from_port                     = rule.from_port
          to_port                       = rule.to_port
          cidr_ipv4                     = rule.cidr_ipv4
          referenced_security_group_key = rule.referenced_security_group_key
        }
      ]
    ]) : rule.key => rule
  }
}

resource "aws_security_group" "this" {
  for_each = var.sg_conf

  name        = each.value.name
  description = each.value.description
  vpc_id      = var.vpc_id
  egress      = [] #AWSデフォルトの全送信許可ルールを明示的に外す
}

resource "aws_vpc_security_group_ingress_rule" "this" {
  for_each = local.ingress_rules

  security_group_id            = aws_security_group.this[each.value.security_group_key].id
  description                  = each.value.description
  cidr_ipv4                    = each.value.cidr_ipv4
  referenced_security_group_id = each.value.referenced_security_group_key == null ? null : aws_security_group.this[each.value.referenced_security_group_key].id
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.ip_protocol
}

resource "aws_vpc_security_group_egress_rule" "this" {
  for_each = local.egress_rules

  security_group_id            = aws_security_group.this[each.value.security_group_key].id
  description                  = each.value.description
  cidr_ipv4                    = each.value.cidr_ipv4
  referenced_security_group_id = each.value.referenced_security_group_key == null ? null : aws_security_group.this[each.value.referenced_security_group_key].id
  from_port                    = each.value.from_port
  to_port                      = each.value.to_port
  ip_protocol                  = each.value.ip_protocol
}
