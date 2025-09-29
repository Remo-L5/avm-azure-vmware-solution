
locals {
  base_name = "avs-${var.location}"

  avs_secrets = {
    vcenter_pass = {
      name = "avs-vcenter-pass"
    }
    nsxt_pass = {
      name = "avs-nsxt-pass"
      }
  }
}

data "azurerm_client_config" "current" {}

module "resource_group" {
  source  = "Azure/avm-res-resources-resourcegroup/azurerm"
  version = "0.2.1"
  location = var.location
  name     = "rg-${local.base_name}"
}

module "keyvault" {
  source  = "Azure/avm-res-keyvault-vault/azurerm"
  version = "0.10.0"

  location               = module.resource_group.resource.location
  name                   = "kv-gmu-its-${local.base_name}"
  resource_group_name    = module.resource_group.name
  tenant_id              = data.azurerm_client_config.current.tenant_id
  enabled_for_deployment = true
  public_network_access_enabled = true
  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"
    ip_rules      = [] # Add IPs if needed
  }
  role_assignments = {
    deployment_user_secrets = {
      role_definition_id_or_name = "Key Vault Administrator"
      principal_id               = data.azurerm_client_config.current.object_id
    }
  }
  wait_for_rbac_before_secret_operations = {
    create = "60s"
  }
}

# Generate vcenter local password
resource "random_password" "avs_pass" {
  for_each = local.avs_secrets
  length  = 20
  special = false
}
# Create Key Vault Secret
resource "azurerm_key_vault_secret" "avs_pass" {
  for_each = local.avs_secrets
  name         = each.value.name
  value        = random_password.avs_pass[each.key].result
  key_vault_id = module.keyvault.resource_id
  content_type = "Password"

  lifecycle { ignore_changes = [tags] }
}

module "ip_calc" {
  source  = "Azure/avm-utl-network-ip-addresses/azurerm"
  version = "0.1.0"

  address_space = var.avs_virtual_network_cidr
  address_prefixes = {
    "sddc"          = 22
    "storage" = 24
  }
}

module "avs_nsg" {
  source  = "Azure/avm-res-network-networksecuritygroup/azurerm"
  version = "0.5.0"
  location            = module.resource_group.resource.location
  resource_group_name = module.resource_group.name
  name     = "nsg-${local.base_name}"
}

module "avs_vnet" {
  source  = "Azure/avm-res-network-virtualnetwork/azurerm"
  version = "0.7.1"

  subscription_id = data.azurerm_client_config.current.subscription_id
  address_space       = [var.avs_virtual_network_cidr]
  location            = module.resource_group.resource.location
  resource_group_name = module.resource_group.name
  name                = "vnet-${local.base_name}"
  dns_servers = [
    var.alz_hub_fw_private_ip
  ]
  subnets = {
    storage = {
      name             = "AvsStorageSubnet"
      address_prefixes = [module.ip_calc.address_prefixes["storage"]]
      network_security_group = {
        id = module.avs_nsg.resource_id
      }
      delegation = [
        {
          name = "Microsoft.Netapp/volumes"
          service_delegation = {
            name = "Microsoft.Netapp/volumes"
          }
        }
      ]
    }
  }

  peerings = {
    to_alz_hub = {
      name = "peering-to-alz-hub-${var.location}"
      remote_virtual_network_resource_id = var.alz_hub_vnet_resource_id
      allow_forwarded_traffic                = true
      allow_gateway_transit      = true
      use_remote_gateways        = true
      allow_virtual_network_access = true
      peer_complete_vnets = true
      create_reverse_peering = true
      reverse_name                          = "peering-to-avs-${var.location}"
      reverse_allow_forwarded_traffic       = false
      reverse_allow_gateway_transit         = false
      reverse_allow_virtual_network_access  = true
      reverse_peer_complete_vnets           = true
      reverse_use_remote_gateways = false
    }
  }
}

module "avs_private_cloud" {
  source  = "Azure/avm-res-avs-privatecloud/azurerm"
  version = "0.9.0"

  depends_on = [
    azurerm_key_vault_secret.avs_pass
  ]

  avs_network_cidr           = module.ip_calc.address_prefixes["sddc"]
  internet_enabled           = false
  location                   = module.resource_group.resource.location
  name                       = "avs-sddc-${var.location}"
  resource_group_name        = module.resource_group.name
  resource_group_resource_id = module.resource_group.resource_id
  enable_telemetry = var.enable_telemetry

  ### AVS Gen2 Vars
  virtual_network_resource_id = module.avs_vnet.resource_id
  dns_zone_type = "Private"
  #################################

  sku_name                   = var.avs_management_cluster_sku
  management_cluster_size    = var.avs_management_cluster_size

  clusters = {
    expansion_1 = {
      cluster_node_count = var.avs_additional_cluster_size
      sku_name = var.avs_additional_cluster_sku
    }
  }

  managed_identities = {
    system_assigned = true
  }

  ### AVS VCENTER CONFIGURATION BLOCK
  # vcenter_password = random_password.avs_pass["vcenter_pass"].result
  # vcenter_identity_sources = {
  #   primary = {
  #     alias                   = "test.local"
  #     base_group_dn           = "dc=test,dc=local"
  #     base_user_dn            = "dc=test,dc=local"
  #     domain                  = "test.local"
  #     name                    = "test.local"
  #     primary_server          = "ldaps://dc01.testdomain.local:636"
  #     secondary_server        = "ldaps://dc02.testdomain.local:636"
  #     ssl                     = "Enabled"
  #   }
  # }
  # vcenter_identity_sources_credentials = { #HELP
  #   primary = {
  #     ldap_user               = "user@test.local"
  #     ldap_user_password      = module.create_dc.ldap_user_password
  #   }
  # }
  # #########################################

  ### AVS NSXT CONFIGURATION BLOCK
  nsxt_password = random_password.avs_pass["nsxt_pass"].result
  segments = var.avs_nsxt_segments
  #########################################

  # addons = {
  #   HCX = {
  #     hcx_key_names    = ["example_key_1", "example_key_2"]
  #     hcx_license_type = "Enterprise"
  #   }
  #   Arc = {
  #    arc_vcenter = "<vcenter resource id>"
  #   }
  # }

  diagnostic_settings = {
    avs_diags = {
      name                  = "${var.location}-law"
      workspace_resource_id = var.log_analytics_workspace_resource_id
      metric_categories     = ["AllMetrics"]
      log_groups            = ["allLogs"]
    }
  }

  tags = { 
    scenario = "avs_default_gen1"
  }
}