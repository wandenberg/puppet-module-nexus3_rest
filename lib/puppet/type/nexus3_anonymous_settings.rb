# frozen_string_literal: true

require 'puppet/resource_api'
require 'puppet_x/nexus3/config'

Puppet::ResourceApi.register_type(
  name: 'nexus3_anonymous_settings',
  docs: <<-EOS,
@summary a nexus3_anonymous_settings type
@example
nexus3_anonymous_settings { 'global':
  enabled  => true,
  username => 'anonymous',
  realm    => 'NexusAuthorizingRealm',
}

This type provides Puppet with the capabilities to manage Nexus 3 Anonymous settings.

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
    username: {
      type: 'String',
      desc: 'Username of the Anonymous settings.',
      default: 'anonymous',
    },
    realm: {
      type: 'Pattern[/\A(LdapRealm|NexusAuthorizingRealm)\z/]',
      desc: 'The realm name of the Anonymous settings.',
      default: 'NexusAuthorizingRealm',
    },
    enabled: {
      type: 'Boolean',
      desc: 'When Anonymous user can access the server or not.',
      default: false,
    },
  },
  autorequire: {
    file: Nexus3::Config.file_path,
  },
)
