##################################################################################
# RESOURCES
##################################################################################

# This storage account is not strictly needed, but avoid using the other accounts as primary:
resource "azurerm_storage_account" "ams_primary_storage" {
  name                     = format("%samssa%s", var.appname, var.environment)
  location                 = var.location
  resource_group_name      = var.resource_group_name
  account_tier             = "Standard"
  account_replication_type = "LRS"
  account_kind             = "StorageV2"
}

resource "azurerm_media_services_account" "mediaservices" {
  name                = format("%sams%s", var.appname, var.environment)
  location            = var.location
  resource_group_name = var.resource_group_name

  storage_account {
    id         = azurerm_storage_account.ams_primary_storage.id
    is_primary = true
  }

  dynamic "storage_account" {
    for_each = toset(var.scope_ids)
    content {
      id         = storage_account.value
      is_primary = false
    }
  }
}

##################################################################################
# App Settings
##################################################################################

locals {
  media_services_app_settings = [
    {
      name        = "AmsAccountName"
      value       = azurerm_media_services_account.mediaservices.name
      slotSetting = false
    },
    {
      name        = "AmsResourceGroup"
      value       = var.resource_group_name
      slotSetting = false
    },
    {
      name        = "AmsLocation"
      value       = var.location
      slotSetting = false
    },
    {
      name        = "AmsAadClientId"
      value       = format("@Microsoft.KeyVault(SecretUri=https://%s.vault.azure.net/secrets/%s/)", var.key_vault_name, "ams-sp-client-id")
      slotSetting = false
    },
    {
      name        = "AmsAadClientSecret"
      value       = format("@Microsoft.KeyVault(SecretUri=https://%s.vault.azure.net/secrets/%s/)", var.key_vault_name, "ams-sp-client-secret")
      slotSetting = false
    },
    {
      name        = "AmsAadTenantId"
      value       = var.tenant_id
      slotSetting = false
    },
    {
      name        = "AmsArmEndpoint"
      value       = "https://management.azure.com"
      slotSetting = false
    },
    {
      name        = "AmsSubscriptionId"
      value       = var.subscription_id
      slotSetting = false
    },
    {
      name        = "AmsV2RestApiEndpoint"
      value       = format("https://%s.restv2.%s.media.azure.net/api/", azurerm_media_services_account.mediaservices.name, var.location)
      slotSetting = false
    },
    {
      name        = "AmsV2CallbackEndpoint"
      value       = var.ams_v2_callback_endpoint
      slotSetting = false
    },
    {
      name        = "AmsDrmOpenIdConnectDiscoveryDocument"
      value       = var.amsDrm_OpenIdConnectDiscoveryDocument_endpoint
      slotSetting = false
    },
    {
      name        = "AmsDrmFairPlayPfxPassword"
      value       = format("@Microsoft.KeyVault(SecretUri=https://%s.vault.azure.net/secrets/%s/)", var.key_vault_name, "ams-fairplay-pfx-password")
      slotSetting = false
    },
    {
      name        = "AmsDrmFairPlayAskHex"
      value       = format("@Microsoft.KeyVault(SecretUri=https://%s.vault.azure.net/secrets/%s/)", var.key_vault_name, "ams-fairplay-ask-hex")
      slotSetting = false
    },
    {
      name        = "AmsDrmFairPlayCertificateB64"
      value       = format("@Microsoft.KeyVault(SecretUri=https://%s.vault.azure.net/secrets/%s/)", var.key_vault_name, "ams-fairPlay-certificate-b64")
      slotSetting = false
    },
     {
      name        = "AmsDrmEnableContentKeyPolicyUpdate"
      value       = var.amsDrm_EnableContentKeyPolicyUpdate
      slotSetting = false
    }
  ]
}

resource "local_file" "media_services_app_settings_json" {
  sensitive_content = jsonencode(local.media_services_app_settings)
  filename          = "./app_settings/media_services_app_settings.json"
}
