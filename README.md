# azure-mod-acr

#### Table of Contents
1. [Usage](#usage)
2. [Requirements](#requirements)
3. [Providers](#Providers)
4. [Inputs](#inputs)
5. [Outputs](#outputs)
## Usage
*various commands
<!-- BEGINNING OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| azurerm | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [azurerm_container_registry.registry](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/container_registry) | resource |
| [azurerm_resource_group.rg](https://registry.terraform.io/providers/hashicorp/azurerm/latest/docs/resources/resource_group) | resource |

## Inputs

No inputs.

## Outputs

| Name | Description |
|------|-------------|
| acr\_fqdn | The Container Registry FQDN. |
| acr\_id | The Container Registry ID. |
| acr\_name | The Container Registry name. |
| admin\_password | The Password associated with the Container Registry Admin account - if the admin account is enabled. |
| admin\_username | The Username associated with the Container Registry Admin account - if the admin account is enabled. |
| login\_server | The URL that can be used to log into the container registry. |
<!-- END OF PRE-COMMIT-TERRAFORM DOCS HOOK -->
