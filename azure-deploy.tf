provider "azurerm" {
  features {
    virtual_machine_scale_set {
      # This can be enabled to sequentially replace instances when
      # application configuration updates (e.g. changed user_data)
      # are made
      roll_instances_when_required = false
    }
  }
}
data "azurerm_subnet" "lb-subnet-id" {
  name = "dev-vault-lb"
  virtual_network_name = "dev-vault"
  resource_group_name = "dev-vault"
}
data "azurerm_subnet" "vm-subnet-id" {
  name = "dev-vault"
  virtual_network_name = "dev-vault"
  resource_group_name = "dev-vault"
}
data "azurerm_key_vault" "key_vault_id" {
  name                = "dev-vault-9d01d0ac1684b3"
  resource_group_name = "dev-vault"
}



module "vault-ent" {
  source  = "github.com/Insight-NA/terraform-azure-vault-ent"

  # (Required when cert in 'key_vault_vm_tls_secret_id' is signed by a private CA) Certificate authority cert (PEM)
  lb_backend_ca_cert = file("./ca.pem")

  # IP address (in Vault subnet) for Vault load balancer
  # (example value here is fine to use alongside the default values in the example vnet module)
  lb_private_ip_address = "10.0.2.253"

  # Virtual Network subnet for Vault load balancer
  lb_subnet_id = data.azurerm_subnet.lb-subnet-id.id

  # One of the DNS Subject Alternative Names on the cert in key_vault_vm_tls_secret_id
  leader_tls_servername = "vault.server.com"

  # Virtual Network subnet for Vault VMs
  vault_subnet_id = data.azurerm_subnet.vm-subnet-id.id

  # Key Vault (containing Vault TLS bundle in Key Vault Certificate and Key Vault Secret form)
  key_vault_id = data.azurerm_key_vault.key_vault_id.id

  # Key Vault Certificate containing TLS certificate for load balancer
  key_vault_ssl_cert_secret_id = "https://dev-vault-9d01d0ac1684b3.vault.azure.net/secrets/dev-vault-cert/a547e5725d0b4251be2df78b2153569b"

  # Key Vault Secret containing TLS certificate for Vault VMs
  key_vault_vm_tls_secret_id = "https://dev-vault-9d01d0ac1684b3.vault.azure.net/secrets/dev-vault-vm-tls/00b1e629dcf04394b19f76cbe83491d2"

  # Resource group object in which resources will be deployed
  resource_group = {
    location = "eastus"
    name     = "dev-vault"
  }

  # Prefix for resource names
  resource_name_prefix = "dev1"

  # SSH public key (authentication to Vault servers)
  # Follow steps on private/public key creation (https://docs.microsoft.com/en-us/azure/virtual-machines/linux/mac-create-ssh-keys)
  ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQDUXERoQ6ces2QIGuUawfirtiM+CByYc7Sbhrsc5xji0xZT4XL7B96hVimetsiIfLK30VdhhXY6i7B3NFd4+r8SdLNqFMA5J0p3YJCrjmBm+dprV+aDimpDV8niHnIenOCMnQ929QPWHGb+ILGwS87XSIQIUp3mrrePT6rIYHSHWqRgTaDcV9sFGYmgGjYRCCLfHJydkvFNDEsp0uw8Ef5TUauhYW2RqCSXZvIpKeqhyxL5FXE+YlZx9kLDg7Oc16mbffx0YL4YRXCfg7RPnzV6S59h9sqasu7XsV25chcPM7GOmMDuEB2nsdTpYWcR1ui8hL9eYVgDt3Twdj0+MzeyHXRuFW7P+aHvq+cVdJw/Saa90fxPcnZYOYaST34AFBdmakkOYggSY57NWALHcujnjU5ZHdAYpGoHTsE1Y/6e4F77h9PvTmdCxveR0TSuC/J6VbvIntOUXtZhfgCzo7vqaEHX3moVkFqSpRvN+NYZ3PiRuExUM/le2h2RAgvnoEfdowqDeq7geA2WP0g52j4Wq0izzhgMiIXwIG4/l1V/RKqM4nRflWQSvYnG2f1D5b4ZqPUCnX2255gHwVeRIjUC5H/YieMiXMnyVlz8Lkc/PcYA8RN+CrGkQNxq7yamwmj39qfwF3pDmPTwL3cr2SApmmDZV6RGIXoqv1G+ooeVKQ=="

  # Application Security Group IDs for Vault VMs
  vault_application_security_group_ids = ["/subscriptions/f234c2d5-4a66-413f-89c7-ad0fde11d864/resourceGroups/dev-vault/providers/Microsoft.Network/applicationSecurityGroups/dev-vault"]

  # Path to the Vault Enterprise license file
  vault_license_filepath = "./vault.hclic"
}