output "policy_names" {
  description = "List of Vault policy names created by this module"
  value       = keys(vault_policy.this)
}
