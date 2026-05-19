resource "vault_policy" "this" {
  for_each = {
    for f in fileset(var.policies_dir, "**/*.hcl") :
    replace(trimsuffix(f, ".hcl"), "/", "-") => file("${var.policies_dir}/${f}")
  }

  name   = each.key
  policy = each.value
}
