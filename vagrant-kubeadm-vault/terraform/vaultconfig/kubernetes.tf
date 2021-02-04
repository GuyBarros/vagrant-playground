resource "vault_mount" "kubernetes_root" {
  path                  = "kubernetes_root"
  type                  = "pki"
  max_lease_ttl_seconds = 315360000 # 10 years
}

resource "vault_pki_secret_backend_root_cert" "kubernetes_root" {
  backend = vault_mount.kubernetes_root.path

  type                 = "internal"
  ttl                  = "87600h"
  key_type             = "rsa"
  exclude_cn_from_sans = true
  ////////////////////////////////////////////////////////////////
  common_name = "kubernetes-ca"
  # ttl = "15768000s"
  format             = "pem"
  private_key_format = "der"
  # key_type = "rsa"
  key_bits = 2048
  # exclude_cn_from_sans = true
  //////////////////////////////////////////////////////////
}

resource "vault_mount" "kubernetes_int" {
  path                  = "kubernetes_int"
  type                  = "pki"
  max_lease_ttl_seconds = 157680000 # 5 years
}

resource "vault_pki_secret_backend_intermediate_cert_request" "kubernetes_int" {
  backend = vault_mount.kubernetes_int.path

  type        = "internal"
  common_name = "kubernetes-ca"
  key_type    = "rsa"
  key_bits    = "2048"
}

resource "vault_pki_secret_backend_root_sign_intermediate" "kubernetes_int" {
  backend = vault_mount.kubernetes_root.path

  csr                  = vault_pki_secret_backend_intermediate_cert_request.kubernetes_int.csr
  common_name          = "kubernetes-ca"
  ttl                  = "43800h"
  exclude_cn_from_sans = true
}

resource "vault_pki_secret_backend_intermediate_set_signed" "kubernetes_int" {
  backend     = vault_mount.kubernetes_int.path
  certificate = vault_pki_secret_backend_root_sign_intermediate.kubernetes_int.certificate
}

resource "vault_pki_secret_backend_role" "kubernetes-ca" {
  backend = vault_mount.kubernetes_int.path
  name    = "kubernetes-ca"
  # allowed_domains    = ["example.io"]
  allow_bare_domains = true #
  allow_subdomains   = true #
  allow_glob_domains = true #
  allow_any_name     = true # adjust allow_*, flags accordingly
  allow_ip_sans      = true #
  server_flag        = true #
  client_flag        = true #
 key_usage = ["DigitalSignature", "KeyAgreement", "KeyEncipherment","KeyUsageCertSign"]
  max_ttl = "730h" # ~1 month
  ttl     = "730h"
}

resource "vault_pki_secret_backend_role" "kube-apiserver-kubelet-client" {
  backend = vault_mount.kubernetes_int.path
  name    = "kubernetes-ca"
  # allowed_domains    = ["example.io"]
  allow_bare_domains = true #
  allow_subdomains   = true #
  allow_glob_domains = true #
  allow_any_name     = true # adjust allow_*, flags accordingly
  allow_ip_sans      = true #
  server_flag        = true #
  client_flag        = true #
  organization       = ["system:masters"]
 key_usage = ["DigitalSignature", "KeyAgreement", "KeyEncipherment","KeyUsageCertSign"]
  max_ttl = "730h" # ~1 month
  ttl     = "730h"
}