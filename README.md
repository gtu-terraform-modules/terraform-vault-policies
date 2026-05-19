# terraform-vault-policy

Terraform module for managing [Vault policies](https://developer.hashicorp.com/vault/docs/concepts/policies).

## Usage

Each `.hcl` file in the directory (including subdirectories) becomes a separate policy in Vault. The policy name equals the relative file path without the extension, where `/` is replaced with `-`.

```
vault-policies/
  terragrunt.hcl        # or main.tf
  policies/
    my-app-read.hcl       → policy "my-app-read"
    my-app-admin.hcl      → policy "my-app-admin"
    team/
      dev.hcl             → policy "team-dev"
      ops.hcl             → policy "team-ops"
```

`policies/team/dev.hcl`:
```hcl
path "secret/data/my-app/*" {
  capabilities = ["read"]
}
```

### Terraform

```hcl
module "vault_policy" {
  source = "git::https://github.com/your-org/gtu-terraform-modules.git//terraform-vault-policy"

  policies_dir = "${path.module}/policies"
}
```

### Terragrunt

```hcl
# terragrunt.hcl
terraform {
  source = "git::https://github.com/your-org/gtu-terraform-modules.git//terraform-vault-policy?ref=v1.0.0"
}

inputs = {
  policies_dir = "${get_terragrunt_dir()}/policies"
}
```

> Use `get_terragrunt_dir()` instead of `path.module` — otherwise the path will point to `.terragrunt-cache`.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.11.0 |
| vault | ~> 5.3 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| policies_dir | Path to the directory containing `.hcl` policy files (recursive search). The policy name is derived from the relative path, where `/` is replaced with `-` | `string` | yes |

## Outputs

| Name | Description |
|------|-------------|
| policy_names | List of policy names created by the module |
