output "private_key_pem" {
  value     = tls_private_key.this.private_key_pem
  sensitive = true
}

output "certificate_pem" {
  value = tls_self_signed_cert.this.cert_pem
}
