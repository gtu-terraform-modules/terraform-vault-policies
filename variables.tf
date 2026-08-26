variable "policies_dir" {
  description = "Path to a directory containing .hcl policy files (searched recursively). Each file becomes a policy named after its relative path without extension (e.g. subdir/mypolicy)"
  type        = string
}

variable "template_vars" {
  description = "Map of policy name to the template variables supplied to that .hcl.tpl policy. Keys are the policy name derived from the file path, so policies/team/dev.hcl.tpl is keyed as \"team-dev\""
  type        = map(map(string))
  default     = {}
}
