resource "vault_mount" "etcd_root" {
  path                  = "etcd_root"
  type                  = "pki"
  max_lease_ttl_seconds = 315360000 # 10 years
}

resource "vault_pki_secret_backend_root_cert" "etcd_root" {
  backend = vault_mount.etcd_root.path

  type                 = "internal"
  ttl                  = "87600h"
  key_type             = "rsa"
  exclude_cn_from_sans = true
  ////////////////////////////////////////////////////////////////
  common_name = "etcd-ca"
  # ttl = "15768000s"
  format             = "pem"
  private_key_format = "der"
  # key_type = "rsa"
  key_bits = 2048
  # exclude_cn_from_sans = true
  //////////////////////////////////////////////////////////
}

resource "vault_mount" "etcd_int" {
  path                  = "etcd_int"
  type                  = "pki"
  max_lease_ttl_seconds = 157680000 # 5 years
}

resource "vault_pki_secret_backend_intermediate_cert_request" "etcd_int" {
  backend = vault_mount.etcd_int.path

  type        = "internal"
  common_name = "etcd-ca"
  key_type    = "rsa"
  key_bits    = "2048"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "etcd_int" {
  backend              = vault_mount.etcd_root.path
  csr                  = vault_pki_secret_backend_intermediate_cert_request.etcd_int.csr
  common_name          = "etcd-ca"
  ttl                  = "43800h"
  exclude_cn_from_sans = true
}

resource "vault_pki_secret_backend_intermediate_set_signed" "etcd_int" {
  backend     = vault_mount.etcd_int.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.etcd_int.certificate
}

resource "vault_pki_secret_backend_role" "etcd-ca" {
  backend = vault_mount.etcd_int.path
  name    = "etcd-ca"
  # allowed_domains    = ["example.io"]
  allow_bare_domains = true #
  allow_subdomains   = true #
  allow_glob_domains = true #
  allow_any_name     = true # adjust allow_*, flags accordingly
  allow_ip_sans      = true #
  server_flag        = true #
  client_flag        = true #


  max_ttl = "730h" # ~1 month
  ttl     = "730h"
}

resource "vault_pki_secret_backend_role" "kube-etcd-peer" {
  backend = vault_mount.etcd_int.path
  name    = "kube-etcd-peer"
  # allowed_domains    = ["example.io"]
  allow_bare_domains = true #
  allow_subdomains   = true #
  allow_glob_domains = true #
  allow_any_name     = true # adjust allow_*, flags accordingly
  allow_ip_sans      = true #
  server_flag        = true #
  client_flag        = true #

  max_ttl = "730h" # ~1 month
  ttl     = "730h"
}

resource "vault_pki_secret_backend_role" "kube-apiserver-etcd-client" {
  backend = vault_mount.etcd_int.path
  name    = "kube-apiserver-etcd-client"
  # allowed_domains    = ["example.io"]
  allow_bare_domains = true #
  allow_subdomains   = true #
  allow_glob_domains = true #
  allow_any_name     = true # adjust allow_*, flags accordingly
  allow_ip_sans      = true #
  server_flag        = true #
  client_flag        = true #
  organization       = ["system:masters"]

  max_ttl = "730h" # ~1 month
  ttl     = "730h"
}

resource "vault_pki_secret_backend_role" "kube-etcd-healthcheck-client" {
  backend = vault_mount.etcd_int.path
  name    = "kube-etcd-healthcheck-client"
  # allowed_domains    = ["example.io"]
  allow_bare_domains = true #
  allow_subdomains   = true #
  allow_glob_domains = true #
  allow_any_name     = true # adjust allow_*, flags accordingly
  allow_ip_sans      = true #
  server_flag        = true #
  client_flag        = true #
  organization       = ["system:masters"]

  max_ttl = "730h" # ~1 month
  ttl     = "730h"
}
