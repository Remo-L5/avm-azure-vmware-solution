variable "subscription_id" {
  description = "The Azure subscription ID where the resources will be deployed."
  type        = string
  
}

variable "location" {
  description = "The Azure region where the resources will be deployed."
  type        = string
  default     = "eastus"
  validation {
    condition     = contains(["eastus", "centralus"], var.location)
    error_message = "The location must be either 'eastus' or 'centralus'."
  }
}

variable "avs_virtual_network_cidr" {
  description = "The CIDR block for the AVS virtual network."
  type        = string
}

variable "alz_hub_fw_private_ip" {
  description = "The private IP address of the ALZ Hub Firewall."
  type        = string
  
}

variable "avs_management_cluster_sku" {
  description = "The SKU of the AVS management cluster."
  type        = string
  validation {
    condition     = contains(["av36", "av36_promo", "av48", "av48_promo", "av60", "av60_promo", "av64", "av64_promo"], var.avs_management_cluster_sku)
    error_message = "The AVS management cluster SKU must be one of 'av36', 'av36_promo', 'av48', 'av48_promo', 'av60', 'av60_promo', 'av64', or 'av64_promo'."
  }
}

variable "avs_management_cluster_size" {
  description = "The size of the AVS management cluster."
  type        = number
  validation {
    condition     = var.avs_management_cluster_size > 3 && var.avs_management_cluster_size < 15
    error_message = "The AVS management cluster size must be between 3 and 15."
  }
}

variable "avs_additional_cluster_size" {
  description = "The size of the additional AVS cluster."
  type        = number
  validation {
    condition     = var.avs_additional_cluster_size > 3 && var.avs_additional_cluster_size < 15
    error_message = "The additional AVS cluster size must be between 3 and 15."
  }
}

variable "avs_additional_cluster_sku" {
  description = "The SKU of the additional AVS cluster."
  type        = string
  validation {
    condition     = contains(["av36", "av36_promo", "av48", "av48_promo", "av60", "av60_promo", "av64", "av64_promo"], var.avs_additional_cluster_sku)
    error_message = "The additional AVS cluster SKU must be one of 'av36', 'av36_promo', 'av48', 'av48_promo', 'av60', 'av60_promo', 'av64', or 'av64_promo'."
  }
}

variable "log_analytics_workspace_resource_id" {
  description = "The resource ID of the Log Analytics Workspace for AVS diagnostics."
  type        = string
  
}

variable "enable_telemetry" {
  description = "Enable or disable telemetry for AVS."
  type        = bool
  default     = true
  
}

variable "alz_hub_vnet_resource_id" {
  description = "The resource ID of the ALZ Hub VNet."
  type        = string
  
}

variable "avs_nsxt_segments" {
  description = "A map of NSX-T segments to be created in AVS."
  type = map(object({
    display_name    = string
    gateway_address = string
    dhcp_ranges     = list(string)
  }))
  default = {}
}
