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
  name                 = "demo-vault-lb"
  virtual_network_name = "demo-vault"
  resource_group_name  = "demo-vault"
}
data "azurerm_subnet" "vm-subnet-id" {
  name                 = "demo-vault"
  virtual_network_name = "demo-vault"
  resource_group_name  = "demo-vault"
}
data "azurerm_key_vault" "key_vault_id" {
  name                = "demo-vault-92033c51baf7"
  resource_group_name = "demo-vault"
}



module "vault-ent" {
  source = "github.com/Insight-NA/terraform-azure-vault-ent"

  # (Required when cert in 'key_vault_vm_tls_secret_id' is signed by a private CA) Certificate authority cert (PEM)
  lb_backend_ca_cert = file("./vault-ca.pem")

  # IP address (in Vault subnet) for Vault load balancer
  # (example value here is fine to use alongside the default values in the example vnet module)
  lb_private_ip_address = "10.0.2.250"

  # Virtual Network subnet for Vault load balancer
  lb_subnet_id = data.azurerm_subnet.lb-subnet-id.id

  # One of the DNS Subject Alternative Names on the cert in key_vault_vm_tls_secret_id
  leader_tls_servername = "vault.server.com"

  # Virtual Network subnet for Vault VMs
  vault_subnet_id = data.azurerm_subnet.vm-subnet-id.id

  # Key Vault (containing Vault TLS bundle in Key Vault Certificate and Key Vault Secret form)
  key_vault_id = data.azurerm_key_vault.key_vault_id.id

  # Key Vault Certificate containing TLS certificate for load balancer
  key_vault_ssl_cert_secret_id = "https://demo-vault-92033c51baf7.vault.azure.net/secrets/demo-vault-cert/bf36f8ce92cb42d389da2c9ce094503e"

  # Key Vault Secret containing TLS certificate for Vault VMs
  key_vault_vm_tls_secret_id = "https://demo-vault-92033c51baf7.vault.azure.net/secrets/demo-vault-vm-tls/2e6e4d14d91e468794c7b3b326033b8b"

  # Resource group object in which resources will be deployed
  resource_group = {
    location = "eastus"
    name     = "demo-vault"
  }

  # Prefix for resource names
  resource_name_prefix = "nsit"

  # SSH public key (authentication to Vault servers)
  # Follow steps on private/public key creation (https://docs.microsoft.com/en-us/azure/virtual-machines/linux/mac-create-ssh-keys)
  ssh_public_key = "ssh-rsa AAAAB3NzaC1yc2EAAAADAQABAAACAQConv+gVbqBn9Gbo/4zN3FdOtV/RODKRZNoP+ArbsZdkyWqgc9Nyz6pcBfJNF4RwMlOfwsSOFvVDMYQ0akYEqEbD6Aa6gpOBGnN9Wk2NV/zA8hWyFjsmK9onF4WbLdEwYZN8hISyhL7l9Dx5vV0+92nt4GUnzhibwh9W94CzgABgpwW/hjl3pR1/2UzKpOw1w5DXYzzgXC0ThKCUHpj81v7C7FTQa3tsaU3mA9YiZRqr3OxIiVTEPhBc5Bd+kuJNtNFnEy1ph+9MwCRfDJwOMOvv6c6JOBxdzLIKqbcK4HGB5qErpO56IQVXhTFuxI+n3HAN17/cWCWsHiw+qIK/TfOeySiM0sV47eqvsQ9JixwRM0jkz2tFkG2hwcKXQvgG4fSekKgnb1LV8fAjY8/xcl1m5GsPp8ttG6j8U5KRG0OCzj7hAzG/hkZvkoexjCqMjqT1YWJFruiJcXet1R/pw6G2MHLROk62XvGIpjRa+qbGSAZxiyBlTS2VqB71poVmBdGvScPl6nxpjQmZ4hqIeMUpPFJiYAXNVa2WqGmWhAZvEtFDxlSLtYgoH7RsaYmv+EtFD7XS1/o/A5mKgZGXDrbZCehLxi7gZ7z/BoGStW/SLGrnAIIvyzsYrD8UL/tKJosHq53rgdLtvvQ2BZZJcJ93g+VHGVPkRhE0L4ozaxjGQ=="

  # Application Security Group IDs for Vault VMs
  vault_application_security_group_ids = ["/subscriptions/f234c2d5-4a66-413f-89c7-ad0fde11d864/resourceGroups/demo-vault/providers/Microsoft.Network/applicationSecurityGroups/demo-vault"]

  # Path to the Vault Enterprise license file
  vault_license_filepath = "./vault.hclic"

  # Scale set settings
  instance_count = 3

  # Disk sizing for the scale set
  os_disk_type = "StandardSSD_LRS"
  os_disk_size = 256

  vault_version = "1.15.1"
}