output "vm_private_key_pem" {
  value     = tls_private_key.vm_key.private_key_pem
  sensitive = true
}
