terraform {
  backend "azurerm" {
    resource_group_name  = "tfstate-rg"
    storage_account_name = "tfstate7fax4"
    container_name       = "blob-tfstate7fax4"
    key                  = "demoacr/terraform.tfstate"
  }
}
