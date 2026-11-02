resource "tls_private_key" "this" {
  algorithm = "RSA"
  rsa_bits  = 2048
}

resource "tls_self_signed_cert" "this" {
  private_key_pem       = tls_private_key.this.private_key_pem
  validity_period_hours = 8760
  allowed_uses = [
    "digital_signature",
    "key_encipherment",
    "server_auth",
  ]

  subject {
    common_name = var.domain_name
  }

  dns_names = [var.domain_name]
}
