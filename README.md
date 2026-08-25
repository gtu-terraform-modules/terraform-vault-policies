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

## Templated policies

Some policy values are only known after another resource has been applied — an auth
backend accessor is the usual case, since Vault's own policy templating needs the
accessor spelled out literally. Supply such values through `template_vars`.

The two templating syntaxes do not collide: Terraform interpolates `${...}`, while
Vault's identity templating uses `{{...}}` and passes through untouched.

`policies/apps/reader.hcl`:
```hcl
path "kv/data/apps/{{identity.entity.aliases.${auth_accessor}.metadata.service_account_namespace}}/*" {
  capabilities = ["read"]
}
```

```hcl
inputs = {
  policies_dir = "${get_terragrunt_dir()}/policies"

  template_vars = {
    "apps-reader" = {
      auth_accessor = dependency.auth.outputs.jwt_auth_backend_accessor
    }
  }
}
```

Note the key: it is the **policy name** the module derives from the file path
(`apps/reader.hcl` → `apps-reader`), not the path itself.

Every policy file is rendered with `templatefile()`. A policy with no entry in
`template_vars` is rendered with an empty variable map, so referencing a variable that
`template_vars` does not supply fails at plan time:

```
Error: Invalid function argument
  Invalid value for "vars" parameter: vars map does not contain key "auth_accessor"
```

A key in `template_vars` that matches no policy file has no effect, and a `check`
block reports it:

```
Warning: Check block assertion failed
  template_vars has entries for policies that do not exist: stale, team/dev.
```

`team/dev` above is the common mistake: the key is the derived policy name
(`team-dev`), not the file path.

A policy that needs a literal `${` or `%{` must escape it as `$${` or `%%{`.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.11.0 |
| vault | ~> 5.3 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| policies_dir | Path to the directory containing `.hcl` policy files (recursive search). The policy name is derived from the relative path, where `/` is replaced with `-` | `string` | yes |
| template_vars | Map of policy name to the template variables supplied to that policy | `map(map(string))` | no |

## Outputs

| Name | Description |
|------|-------------|
| policy_names | List of policy names created by the module |
