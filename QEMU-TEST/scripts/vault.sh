set -x
#set Vault address and Vault token enviroment variables
export VAULT_ADDR=http://desktop-khfd9va.lan:8200
export VAULT_TOKEN=s.wrlHqUffYHZNY9IGJXUf3cbT


# Kubernetes
## Root CA Cert
vault secrets enable -path=kubernetes_root pki && vault secrets tune -max-lease-ttl=87600h kubernetes_root
vault write -format=json kubernetes_root/root/generate/exported common_name="root" ttl=315360000s  > ca.json
vault write kubernetes_root/config/urls issuing_certificates="http://desktop-khfd9va.lan:8200/v1/kubernetes_root/ca" crl_distribution_points="http://desktop-khfd9va.lan:8200/v1/kubernetes_root/crl"
jq -r .data.certificate ca.json > root.pem

## Kubernetes Intermediate CA
vault secrets enable -path=kubernetes_int pki && vault secrets tune -max-lease-ttl=43800h kubernetes_int
vault write -format=json kubernetes_int/intermediate/generate/exported \
        common_name="intermediate" > pki_intermediate.json
        jq -r '.data.csr' pki_intermediate.json > pki_intermediate.csr

vault write -format=json kubernetes_root/root/sign-intermediate csr=@pki_intermediate.csr \
        format=pem_bundle ttl="43800h" \
        | jq -r '.data.certificate' > kubernetes-ca.pem

vault write kubernetes_int/intermediate/set-signed certificate=@kubernetes-ca.pem

cat root.pem kubernetes-ca.pem > kubernetes-ca-all.pem

##Roles apiserver
vault write kubernetes_int/roles/apiserver \
        allow_bare_domains=true \
        allow_subdomains=true \
        allow_glob_domains=true \
        allow_any_name=true \
        allow_ip_sans=true \
        server_flag=true \
        client_flag=true \
        max_ttl="730h" \
        ttl="720h" \
        key_usage='DigitalSignature,KeyAgreement,KeyEncipherment,KeyUsageCertSign,critical,digitalSignature,cRLSign,keyCertSign' \



##Roles kube-apiserver-kubelet-client
vault write kubernetes_int/roles/kube-apiserver-kubelet-client \
        allow_bare_domains=true \
        allow_subdomains=true \
        allow_glob_domains=true \
        allow_any_name=true \
        allow_ip_sans=true \
        server_flag=true \
        client_flag=true \
        max_ttl="730h" \
        ttl="720h" \
        key_usage='DigitalSignature,KeyAgreement,KeyEncipherment,KeyUsageCertSign,critical, digitalSignature,cRLSign,keyCertSign' \
        organization='["system:masters"]'


# ETCD
## ETCD CA Cert
vault secrets enable -path=etcd_root pki && vault secrets tune -max-lease-ttl=87600h etcd_root
vault write -format=json etcd_root/root/generate/exported common_name="etcd-root" ttl=315360000s > etcd-ca.json
vault write etcd_root/config/urls issuing_certificates="http://desktop-khfd9va.lan:8200/v1/etcd_root/ca" crl_distribution_points="http://desktop-khfd9va.lan:8200/v1/etcd_root/crl"
jq -r .data.certificate etcd-ca.json > etcd-ca.pem

## ETCD Intermediate CA
vault secrets enable -path=etcd_int pki && vault secrets tune -max-lease-ttl=43800h  etcd_int
vault write -format=json  etcd_int/intermediate/generate/internal  common_name="etcd-int"   | jq -r '.data.csr' > etcd_pki_intermediate.csr
vault write -format=json  etcd_root/root/sign-intermediate csr=@etcd_pki_intermediate.csr       format=pem_bundle ttl="43800h"  | jq -r '.data.certificate' > etcd_intermediate.cert.pem
vault write etcd_int/intermediate/set-signed certificate=@etcd_intermediate.cert.pem

cat etcd-ca.pem etcd_intermediate.cert.pem > etcd-ca-all.pem


##Roles 	etcd-ca
vault write etcd_int/roles/etcd-ca \
        allow_bare_domains=true \
        allow_subdomains=true \
        allow_glob_domains=true \
        allow_any_name=true \
        allow_ip_sans=true \
        server_flag=true \
        client_flag=true \
        max_ttl="730h" \
        ttl="720h" \
        key_usage='DigitalSignature,KeyAgreement,KeyEncipherment,KeyUsageCertSign,critical, digitalSignature,cRLSign,keyCertSign' \

##Roles kube-apiserver-etcd-client
vault write etcd_int/roles/kube-apiserver-etcd-client \
        allow_bare_domains=true \
        allow_subdomains=true \
        allow_glob_domains=true \
        allow_any_name=true \
        allow_ip_sans=true \
        server_flag=true \
        client_flag=true \
        max_ttl="730h" \
        ttl="720h" \
        key_usage='DigitalSignature,KeyAgreement,KeyEncipherment,KeyUsageCertSign,critical, digitalSignature,cRLSign,keyCertSign' \
        organization='["system:masters"]'

## Roles kube-etcd-peer
vault write etcd_int/roles/kube-etcd-peer \
        allow_bare_domains=true \
        allow_subdomains=true \
        allow_glob_domains=true \
        allow_any_name=true \
        allow_ip_sans=true \
        server_flag=true \
        client_flag=true \
        max_ttl="730h" \
        ttl="720h" \
        key_usage='DigitalSignature,KeyAgreement,KeyEncipherment,KeyUsageCertSign,critical, digitalSignature,cRLSign,keyCertSign' \

## Roles kube-etcd-healthcheck-client
vault write etcd_int/roles/kube-etcd-healthcheck-client \
        allow_bare_domains=true \
        allow_subdomains=true \
        allow_glob_domains=true \
        allow_any_name=true \
        allow_ip_sans=true \
        server_flag=true \
        client_flag=true \
        max_ttl="730h" \
        ttl="720h" \
        key_usage='DigitalSignature,KeyAgreement,KeyEncipherment,KeyUsageCertSign,critical, digitalSignature,cRLSign,keyCertSign' \


# Proxy
## Proxy CA Cert
vault secrets enable -path=proxy_root pki && vault secrets tune -max-lease-ttl=87600h proxy_root
vault write -format=json proxy_root/root/generate/exported common_name="kubernetes-front-proxy-ca" ttl=315360000s > kubernetes-front-proxy-ca.json
vault write proxy_root/config/urls issuing_certificates="http://desktop-khfd9va.lan:8200/v1/proxy_root/ca" crl_distribution_points="http://desktop-khfd9va.lan:8200/v1/proxy_root/crl"
jq -r .data.certificate kubernetes-front-proxy-ca.json > proxy-root.pem

## Proxy Intermediate CA
vault secrets enable -path=proxy_int pki && vault secrets tune -max-lease-ttl=43800h  proxy_int
vault write -format=json  proxy_int/intermediate/generate/internal  common_name="kubernetes-front-proxy-ca"    | jq -r '.data.csr' > proxy_int_intermediate.csr
vault write -format=json  proxy_root/root/sign-intermediate csr=@proxy_int_intermediate.csr format=pem_bundle ttl="43800h"     | jq -r '.data.certificate' > proxy_intermediate.cert.pem
vault write proxy_int/intermediate/set-signed certificate=@proxy_intermediate.cert.pem
cat proxy-root.pem proxy_intermediate.cert.pem > proxy-ca-all.pem
##Roles Proxy CA
vault write proxy_int/roles/front-proxy-ca \
        allow_bare_domains=true \
        allow_subdomains=true \
        allow_glob_domains=true \
        allow_any_name=true \
        allow_ip_sans=true \
        server_flag=true \
        client_flag=true \
        max_ttl="730h" \
        ttl="720h" \
        key_usage='DigitalSignature,KeyAgreement,KeyEncipherment,KeyUsageCertSign,critical, digitalSignature,cRLSign,keyCertSign' \
