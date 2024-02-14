resource "azuredevops_project" "project" {
  name               = "Intraquotes"
  visibility         = "private"
  version_control    = "Git"
  work_item_template = "Agile"
  features = {
    "testplans" = "disabled"
    "artifacts" = "disabled"
    //"pipelines" = "disabled"
    //"repositories" = "disabled"
    "boards" = "disabled"
    //available features are: `boards`, `repositories`,`pipelines`,`testplans`,`artifacts`
  }
  description = "Project Creation from terraform"
}

// This section assigns users from AAD into a pre-existing group in AzDO
data "azuredevops_group" "group" {
  project_id = azuredevops_project.project.id
  name       = "Build Administrators"
}

resource "azuredevops_user_entitlement" "users" {
  for_each             = toset(var.aad_users)
  principal_name       = each.value
  account_license_type = "stakeholder"
  // account_license_type are: Basic,Basic + Test Plans,stakeholder,Visual Studio Subscriber,Visual Studio Professional,Visual Studio Enterprise
}

resource "azuredevops_group_membership" "membership" {
  group   = data.azuredevops_group.group.descriptor
  members = values(azuredevops_user_entitlement.users)[*].descriptor
}

// This section assigns users from AAD into a pre-existing group in AzDO **End

resource "azuredevops_git_repository" "azrepo" {
  project_id = azuredevops_project.project.id
  name       = "Intraquotes-packer"
  initialization {
    init_type = "Import"
    source_type = "Git"
    source_url  = "https://github.com/chenna0501/AzureTerraform.git"
   // init_type Valid values are: Uninitialized , Clean or Import.

  }
}

resource "azuredevops_build_definition" "azbuild" {
  project_id = azuredevops_project.project.id
  name       = "Sample Build Definition"
  path       = "\\BuildsFolder"

  repository {
    repo_type = "TfsGit"
    repo_id   = azuredevops_git_repository.azrepo.id
    yml_path  = "azure-pipelines.yml"
  }
}

resource "azuredevops_branch_policy_build_validation" "azvalidation" {
  project_id = azuredevops_project.project.id

  enabled  = true
  blocking = true

  settings {
    display_name        = "azvalidation"
    build_definition_id = azuredevops_build_definition.azbuild.id
    valid_duration      = 720
    filename_patterns = [
      "/WebApp/*",
      "!/WebApp/Tests/*",
      "*.cs"
    ]

    scope {
      repository_id  = azuredevops_git_repository.azrepo.id
      repository_ref = azuredevops_git_repository.azrepo.default_branch
      match_type     = "Exact"
    }

    scope {
      repository_id  = azuredevops_git_repository.azrepo.id
      repository_ref = "refs/heads/releases"
      match_type     = "Prefix"
    }

    scope {
      match_type = "DefaultBranch"
    }
  }
}

resource "azuredevops_variable_group" "azvargroup" {
  project_id   = azuredevops_project.project.id
  name         = "Custom Variable Group"
  description  = "Variable Group created by terraform"
  allow_access = true

  variable {
    name  = "UserName"
    value = "Chenna"
  }

  variable {
    name         = "Password"
    secret_value = "kesava"
    is_secret    = true
  }
}
