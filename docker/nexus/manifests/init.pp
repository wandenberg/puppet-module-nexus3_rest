# Nexus class to load values from hiera file
class nexus (
  Optional[Hash] $anonymous_settings = {},
  Optional[Hash] $blobstores = {},
  Optional[Hash] $cleanup_policies = {},
  Optional[Hash] $ldaps = {},
  Optional[Hash] $privileges = {},
  Optional[Hash] $realm_settings = {},
  Optional[Hash] $repositories = {},
  Optional[Hash] $repository_groups = {},
  Optional[Hash] $roles = {},
  Optional[Hash] $routing_rules = {},
  Optional[Hash] $smtp_settings = {},
  Optional[Hash] $tasks = {},
  Optional[Hash] $users = {},
){
  ensure_resources( 'nexus3_anonymous_settings', $anonymous_settings )
  ensure_resources( 'nexus3_blobstore', $blobstores )
  ensure_resources( 'nexus3_cleanup_policy', $cleanup_policies )
  ensure_resources( 'nexus3_ldap', $ldaps )
  ensure_resources( 'nexus3_privilege', $privileges )
  ensure_resources( 'nexus3_realm_settings', $realm_settings )
  ensure_resources( 'nexus3_repository', $repositories )
  ensure_resources( 'nexus3_repository_group', $repository_groups )
  ensure_resources( 'nexus3_role', $roles )
  ensure_resources( 'nexus3_routing_rule', $routing_rules )
  ensure_resources( 'nexus3_smtp_settings', $smtp_settings )
  ensure_resources( 'nexus3_task', $tasks )
  ensure_resources( 'nexus3_user', $users )
}
