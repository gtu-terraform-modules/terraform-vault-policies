locals {
  plain_files = {
    for f in fileset(var.policies_dir, "**/*.hcl") :
    replace(trimsuffix(f, ".hcl"), "/", "-") => f
  }

  template_files = {
    for f in fileset(var.policies_dir, "**/*.hcl.tpl") :
    replace(trimsuffix(f, ".hcl.tpl"), "/", "-") => f
  }

  policies = merge(
    { for name, f in local.plain_files : name => file("${var.policies_dir}/${f}") },
    { for name, f in local.template_files :
    name => templatefile("${var.policies_dir}/${f}", lookup(var.template_vars, name, {})) },
  )

  orphaned_template_vars = setsubtract(keys(var.template_vars), keys(local.template_files))
  colliding_policies     = setintersection(keys(local.plain_files), keys(local.template_files))
}

check "template_vars_match_templates" {
  assert {
    condition = length(local.orphaned_template_vars) == 0
    error_message = format(
      "template_vars has entries that match no .hcl.tpl file: %s. Keys are policy names derived from the file path, so policies/team/dev.hcl.tpl is keyed as \"team-dev\".",
      join(", ", local.orphaned_template_vars)
    )
  }
}

check "no_colliding_policies" {
  assert {
    condition = length(local.colliding_policies) == 0
    error_message = format(
      "These policies exist as both .hcl and .hcl.tpl, and the .hcl.tpl wins: %s.",
      join(", ", local.colliding_policies)
    )
  }
}

resource "vault_policy" "this" {
  for_each = local.policies

  name   = each.key
  policy = each.value
}
