variable "policies_dir" {
  description = "Path to a directory containing .hcl policy files (searched recursively). Each file becomes a policy named after its relative path without extension (e.g. subdir/mypolicy)"
  type        = string
}
