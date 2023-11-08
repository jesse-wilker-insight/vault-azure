#!/bin/bash
# Init Core Cluster
cd /c/Code/vault/vault-servers/core
vault server -config=./config-core.hcl


# Core Terminal Ctrl+Shift+5
cd /c/Code/vault/vault-servers/core
export VAULT_ADDR=http://127.0.0.1:8200
export VAULT_TOKEN=hvs.JeuglsXv7V6fufjtY2Oq8KoX
vault status
UNSEALKEY="$(echo wcBMAwHjXgk4O5t7AQgAi2kWCUrCrZu2ny/CseF77KWhExvIClU7dNrYpXAtvbbkw5LGS2nhSmAUE7zaMnAoVW2WK+QXg88P9I+y956UMtKkSN4HLRii4v6K0oAiunjgV9+L/uQT8xnxK6yitn/wUQ44Mfc956nq2NAgd/qqmg6VIKt7tbYzTDj1M3JnmeGW1iTC92q6/DiQolamdQumpcCPTscaBmsQr6TjaW8sqG9jxQ2TpI6jOzwlTYwuMmMF04cTKkgFUnpH6lhuti/he+SxIHunjXd3BsMFp9GNkdg6Ms100Kd1S+dZ1DmO8p8OT2yM8gohdY7ql+SP8DD+iQVlVrXx6IskYaap0dhpodLgAeS/9DlAgbWVDZfO0me1Meo44bvF4HfgIeF5AOAb4j/KW9Hgr+bY0Vh5/mt5H8mF18BLfI8f6NS7OiCttNq4coWX2ASiPvvj8ZyvRmHOUAF7zlf1jUkiNp+kPvhTiiOPfZajiS5b4L7kaGNBGU7lTChFRUbb8zKRJOIjKEST4d2KAA== | base64 --decode | keybase pgp decrypt )"
vault operator unseal $UNSEALKEY

#Create Periodic Token
CLUSTERTOKEN=$(vault token create -orphan -policy="autounseal" -wrap-ttl=48h -period=768h -format=json | jq -r .wrap_info.token)
PRIMARYKEY=$(vault unwrap -format=json $CLUSTERTOKEN | jq -r .auth.client_token)
echo $PRIMARYKEY
#POPULATE Leader and Second Node with primary key

#Cluster 2 - Primary Node - CTRL+SHIFT+`
cd /c/Code/vault/vault-servers/leader
vault server -config=./config-leader.hcl


# Leader Terminal Ctrl+Shift+5
cd /c/Code/vault/vault-servers/leader
export VAULT_ADDR=http://127.0.0.2:8200
export VAULT_TOKEN=hvs.lT5LmD6bGPWf3UnhHfMb5MSD
vault status

#Cluster 2 - Second-node - CTRL+SHIFT+`
cd /c/Code/vault/vault-servers/second-node
vault server -config=./config-second-node.hcl

#Cluster 2 - Second Node - Terminal CTRL+SHIFT+5
cd /c/Code/vault/vault-servers/second-node
export VAULT_ADDR=http://127.0.0.3:8200
export VAULT_TOKEN=hvs.lT5LmD6bGPWf3UnhHfMb5MSD
vault status
vault operator raft list-peers


#Go to Vault Config Repo - new term - CTRL+SHIFT+`
cd /c/Code/vault-config/oss
export VAULT_ADDR=http://127.0.0.3:8200
export VAULT_TOKEN=hvs.lT5LmD6bGPWf3UnhHfMb5MSD
terraform init
terraform apply -auto-approve
terraform destroy -auto-approve

#KV ClI
terraform apply -auto-approve
vault kv list dept1-static
vault kv get dept1-static/transform2023-metadata
vault kv get dept1-static/transform2024-metadata
terraform destroy -auto-approve
terraform apply -auto-approve

# Vault Health
vault status
vault operator raft list-peers
vault secrets list
vault policy list
vault auth list
