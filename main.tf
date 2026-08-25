locals {
  policy_files = {
    for f in fileset(var.policies_dir, "**/*.hcl") :
    replace(trimsuffix(f, ".hcl"), "/", "-") => f
  }

  policies = {
    for name, f in local.policy_files :
    name => templatefile("${var.policies_dir}/${f}", lookup(var.template_vars, name, {}))
  }

  orphaned_template_vars = setsubtract(keys(var.template_vars), keys(local.policy_files))
}

check "template_vars_match_policies" {
  assert {
    condition = length(local.orphaned_template_vars) == 0
    error_message = format(
      "template_vars has entries for policies that do not exist: %s. Keys are policy names derived from the file path, so policies/team/dev.hcl is keyed as \"team-dev\".",
      join(", ", local.orphaned_template_vars)
    )
  }
}

resource "vault_policy" "this" {
  for_each = local.policies

  name   = each.key
  policy = each.value
}
