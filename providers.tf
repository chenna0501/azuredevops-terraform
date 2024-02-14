terraform {
  required_providers {
    azuredevops = {
      source  = "microsoft/azuredevops"
      version = ">= 0.1.0"
    }
  }
}


provider "azuredevops" {
  # Configuration options
  org_service_url       = "https://dev.azure.com/{OrganigationName}/"
  personal_access_token = "PAT token of your Organization"
}