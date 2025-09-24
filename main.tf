
locals {
  location_shortname = {
    eastus = "use"
    centralus = "usc"
  }
  base_name = "avs-${local.location_shortname[var.location]}"

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
  network_acls = {
    default_action = "Allow"
    bypass         = "AzureServices"
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
  value        = random_password.vcenter_pass.result
  key_vault_id = module.keyvault.id
  content_type = "Password"

  lifecycle { ignore_changes = [tags] }
}

module "avs_private_cloud" {
  source  = "Azure/avm-res-avs-privatecloud/azurerm"
  version = "0.9.0"

  depends_on = [
    azurerm_key_vault_secret.avs_pass
  ]

  avs_network_cidr           = var.avs_network_cidr
  extended_network_blocks    = var.avs_extended_network_blocks
  internet_enabled           = false
  location                   = module.resource_group.resource.location
  name                       = "avs-sddc-${local.location_shortname[var.location]}"
  resource_group_name        = module.resource_group.name
  resource_group_resource_id = module.resource_group.resource_id
  enable_telemetry = var.enable_telemetry

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

  ### AVS EXPRESSROUTE CONFIGURATION BLOCK
  expressroute_connections = {
    default = {
      name                             = "er-vnet-gateway-connection"
      authorization_key_name           = "er-alz-authorization-key"
      expressroute_gateway_resource_id = var.alz_express_route_gateway_resource_id
    }
  }
  global_reach_connections = {
    ("gr-${var.location}") = {
      authorization_key                     = var.alz_express_route_circuit_authorization_key_name
       peer_expressroute_circuit_resource_id = var.alz_express_route_circuit_resource_id
    }
  }
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