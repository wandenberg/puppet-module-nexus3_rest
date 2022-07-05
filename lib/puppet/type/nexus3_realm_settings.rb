# frozen_string_literal: true

require 'puppet/resource_api'
require 'puppet_x/nexus3/config'

Puppet::ResourceApi.register_type(
  name: 'nexus3_realm_settings',
  docs: <<-EOS,
@summary a nexus3_realm_settings type
@example
nexus3_realm_settings { 'global':
  names => ['NexusAuthenticatingRealm', 'NexusAuthorizingRealm'],
}

This type provides Puppet with the capabilities to manage Nexus 3 Realm settings.

**Autorequires**:
* `File[$PUPPET_CONF_DIR/nexus3_rest.conf]`
  EOS
  features: ['canonicalize'],
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    name: {
      type: 'String',
      desc: 'The name of the resource you want to manage.',
      behaviour: :namevar,
    },
    names: {
      type: 'Array[Pattern[/\A(NexusAuthenticatingRealm|NexusAuthorizingRealm|ConanToken|DockerToken|LdapRealm|NpmToken|NuGetApiKey|rutauth-realm|DefaultRole)\z/]]',
      desc: 'A list of realms names',
      default: %w[NexusAuthenticatingRealm NexusAuthorizingRealm],
    },
  },
  autorequire: {
    file: Nexus3::Config.file_path,
  },
)
