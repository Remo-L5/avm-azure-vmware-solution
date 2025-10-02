subscription_id = "your-azure-subscription-id"
location = "your-location" # Example: "eastus", "westus2", etc.
avs_virtual_network_cidr = "your-avs-virtual-network-cidr" # Example: "10.240.0.0/21"
alz_hub_fw_private_ip = "your-alz-hub-fw-private-ip" # Example: "10.240.0.4"
avs_management_cluster_sku = "av36"
avs_management_cluster_size = 3 
avs_additional_cluster_size = 4 # If no additional cluster is needed, set this to 0
avs_additional_cluster_sku = "av64"
log_analytics_workspace_resource_id = "your-log-analytics-workspace-resource-id" # Example: "/subscriptions/xxxx/resourceGroups/xxxx/providers/Microsoft.OperationalInsights/workspaces/xxxx"
enable_telemetry = true
alz_hub_vnet_resource_id = "your-alz-hub-vnet-resource-id" # Example: "/subscriptions/xxxx/resourceGroups/xxxx/providers/Microsoft.Network/virtualNetworks/xxxx"
# avs_nsxt_segments = {
#   segment_1 = {
#     display_name    = "segment_1"
#     gateway_address = "10.20.0.1/24"
#     dhcp_ranges     = ["10.20.0.5-10.20.0.100"]
#   }
#   segment_2 = {
#     display_name    = "segment_2"
#     gateway_address = "10.30.0.1/24"
#     dhcp_ranges     = ["10.30.0.0/24"]
#   }
# }
