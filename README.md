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
accessor spelled out literally.

A policy file named `*.hcl.tpl` is rendered with `templatefile()`; a plain `*.hcl`
file is read verbatim and is never interpolated. The extension is the opt-in, so a
`${` or `%{` sequence in an ordinary policy stays literal.

The two templating syntaxes do not collide: Terraform interpolates `${...}`, while
Vault's identity templating uses `{{...}}` and passes through untouched.

`policies/apps/reader.hcl.tpl`:
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

The policy name drops the whole extension, so `apps/reader.hcl.tpl` becomes
`apps-reader` — the same name it would have as `apps/reader.hcl`. Renaming a policy
to a template therefore updates it in place rather than replacing it.

Referencing a variable that `template_vars` does not supply fails at plan time:

```
Error: Invalid function argument
  Invalid value for "vars" parameter: vars map does not contain key "auth_accessor"
```

Two `check` blocks report the remaining mistakes: a `template_vars` key matching no
`.hcl.tpl` file, and a policy that exists as both `.hcl` and `.hcl.tpl`, where the
template wins.

A template that needs a literal `${` or `%{` must escape it as `$${` or `%%{`.

## Requirements

| Name | Version |
|------|---------|
| terraform | >= 1.11.0 |
| vault | ~> 5.3 |

## Inputs

| Name | Description | Type | Required |
|------|-------------|------|----------|
| policies_dir | Path to the directory containing `.hcl` policy files (recursive search). The policy name is derived from the relative path, where `/` is replaced with `-` | `string` | yes |
| template_vars | Map of policy name to the template variables supplied to that `.hcl.tpl` policy | `map(map(string))` | no |

## Outputs

| Name | Description |
|------|-------------|
| policy_names | List of policy names created by the module |
