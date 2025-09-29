terraform {
  required_version = "~> 1.10"

  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 4.35"
    }
  }
  backend "azurerm" {
  }
}

# tflint-ignore: terraform_module_provider_declaration, terraform_output_separate, terraform_variable_separate
provider "azurerm" {
    subscription_id = var.subscription_id
    resource_provider_registrations = "none"
  features {
    resource_group {
      prevent_deletion_if_contains_resources = false
    }
    # netapp {
    #   delete_backups_on_backup_vault_destroy = true
    #   prevent_volume_destruction             = false
    # }
  }
}