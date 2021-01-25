
#set Vault address and Vault token enviroment variables
export VAULT_ADDR=http://desktop-khfd9va.lan:8200
export VAULT_TOKEN=s.wrlHqUffYHZNY9IGJXUf3cbT


vault secrets disable kubernetes_int
vault secrets disable kubernetes_root
vault secrets disable etcd_int
vault secrets disable etcd_root
vault secrets disable proxy_int
vault secrets disable proxy_root