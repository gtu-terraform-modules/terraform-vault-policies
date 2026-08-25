variable "policies_dir" {
  description = "Path to a directory containing .hcl policy files (searched recursively). Each file becomes a policy named after its relative path without extension (e.g. subdir/mypolicy)"
  type        = string
}

variable "template_vars" {
  description = "Map of policy name to the template variables supplied to that policy. Keys are the policy name derived from the file path, so policies/team/dev.hcl is keyed as \"team-dev\". Policies with no entry here are rendered with an empty variable map"
  type        = map(map(string))
  default     = {}
}
