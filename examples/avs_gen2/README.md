# Azure VMware Solution (AVS) Gen2 Terraform Module

This Terraform root module deploys a complete Azure VMware Solution (AVS) environment with networking, security, and management components. The module leverages Azure Verified Modules (AVM) to ensure best practices and consistency across deployments.

## What This Module Creates

This module provisions the following Azure resources:

### Core Infrastructure
- **Resource Group** - Container for all AVS resources
- **Virtual Network** - Dedicated VNet for AVS with configurable CIDR
- **Network Security Group** - Security rules for AVS network traffic
- **VNet Peering** - Connection to Azure Landing Zone (ALZ) hub network

### Azure VMware Solution Components
- **AVS Private Cloud** - Main SDDC with management cluster
- **Additional Clusters** - Expansion clusters for workload separation
- **NSX-T Segments** - Software-defined networking segments
- **Diagnostic Settings** - Monitoring and logging configuration

### Security & Management
- **Key Vault** - Secure storage for AVS passwords and secrets
- **Random Passwords** - Auto-generated secure passwords for vCenter and NSX-T
- **Managed Identity** - System-assigned identity for AVS resources

## Prerequisites

### Important Network Configuration Note

⚠️ **Route Table Configuration Required**: This module does not include the creation of route tables to force traffic back to a Network Virtual Appliance (NVA) or central firewall. This configuration should be implemented by the deployment team based on their specific network security requirements and routing policies.

### Azure Provider Registration

Before deploying this module, ensure the following Microsoft resource providers are registered on your Azure subscription:

#### Using Azure CLI
```bash
# Register required resource providers
az provider register --namespace Microsoft.KeyVault
az provider register --namespace Microsoft.AVS
az provider register --namespace Microsoft.BareMetal
az provider register --namespace Microsoft.Insights
az provider register --namespace Microsoft.ResourceHealth
```

You can check the registration status with:
```bash
az provider show --namespace Microsoft.AVS --query "registrationState"
```

#### Using Azure Portal
Alternatively, you can register these providers through the Azure Portal:
1. Navigate to your **Subscription** in the Azure Portal
2. Select **Resource providers** from the left menu
3. Search for each provider name (e.g., "Microsoft.AVS")
4. Select the provider and click **Register**
5. Wait for the registration status to show as "Registered"

### Azure Verified Modules (AVM)

This module uses Azure Verified Modules (AVM) which are officially supported, well-tested Terraform modules maintained by Microsoft. AVM modules provide:

- **Consistent patterns** across Azure services
- **Security best practices** built-in
- **Regular updates** and maintenance
- **Comprehensive testing** and validation

## Variables

| Variable | Type | Description | Required |
|----------|------|-------------|----------|
| `subscription_id` | string | Azure subscription ID where resources will be deployed | Yes |
| `location` | string | `"eastus"` | Azure region (eastus or centralus) |
| `avs_virtual_network_cidr` | string | `"10.240.0.0/21"` | CIDR block for AVS virtual network |
| `alz_hub_fw_private_ip` | string | `""` | Private IP of ALZ Hub Firewall for DNS |
| `alz_hub_vnet_resource_id` | string | `""` | Resource ID of ALZ Hub VNet for peering |
| `avs_management_cluster_sku` | string | `"av36"` | SKU for management cluster |
| `avs_management_cluster_size` | number | `3` | Number of hosts in management cluster (3-15) |
| `avs_additional_cluster_sku` | string | `"av64"` | SKU for additional cluster |
| `avs_additional_cluster_size` | number | `4` | Number of hosts in additional cluster (3-15) |
| `log_analytics_workspace_resource_id` | string | `""` | Log Analytics workspace for diagnostics |
| `enable_telemetry` | bool | `true` | Enable telemetry for AVS |
| `avs_nsxt_segments` | map(object) | See below | NSX-T network segments configuration |

### Available SKUs

The following SKUs are supported for AVS clusters:
- `av36`, `av36_promo` - 36 cores per host
- `av48`, `av48_promo` - 48 cores per host  
- `av60`, `av60_promo` - 60 cores per host
- `av64`, `av64_promo` - 64 cores per host (additional clusters only)

### Default NSX-T Segments

```hcl
avs_nsxt_segments = {
  segment_1 = {
    display_name    = "segment_1"
    gateway_address = "10.20.0.1/24"
    dhcp_ranges     = ["10.20.0.5-10.20.0.100"]
  }
  segment_2 = {
    display_name    = "segment_2"
    gateway_address = "10.30.0.1/24"
    dhcp_ranges     = ["10.30.0.0/24"]
  }
}
```

## Usage Example

```hcl
module "avs_deployment" {
  source = "./path/to/this/module"
  
  subscription_id                      = "12345678-1234-1234-1234-123456789012"
  location                            = "eastus"
  avs_virtual_network_cidr           = "10.240.0.0/21"
  alz_hub_vnet_resource_id           = "/subscriptions/.../virtualNetworks/hub-vnet"
  alz_hub_fw_private_ip              = "10.0.1.4"
  log_analytics_workspace_resource_id = "/subscriptions/.../workspaces/law-avs"
  
  avs_management_cluster_sku  = "av36"
  avs_management_cluster_size = 3
  avs_additional_cluster_sku  = "av64"
  avs_additional_cluster_size = 4
}
```

## Outputs

The module provides outputs for:
- AVS Private Cloud resource ID and endpoints
- Key Vault resource ID
- Virtual Network resource ID
- Generated passwords (sensitive)

## License

This project is licensed under the MIT License - see the [LICENSE](../../LICENSE) file for details.
