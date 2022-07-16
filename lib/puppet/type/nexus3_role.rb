require 'puppet/resource_api'
require 'puppet_x/nexus3/config'

Puppet::ResourceApi.register_type(
  name: 'nexus3_role',
  docs: <<-EOS,
@summary a nexus3_role type
@example
nexus3_role { 'nx-admin':
  description => 'Administrator Role',
  privileges  => ['nx-all'],
}

This type provides Puppet with the capabilities to manage Nexus 3 Role.

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
      desc: 'Unique role name.',
      behaviour: :namevar,
    },
    description: {
      type: 'String',
      desc: 'The description of the role.',
      default: '',
    },
    privileges: {
      type: 'Array[String]',
      desc: 'A list of privileges names.',
      default: [],
    },
    roles: {
      type: 'Array[String]',
      desc: 'A list of roles names.',
      default: [],
    },
    read_only: {
      type: 'Boolean',
      desc: 'When role is read only or not.',
      default: false,
      behaviour: :parameter,
    },
    source: {
      type: 'String',
      desc: 'The source of the role.',
      default: 'default',
      behaviour: :parameter,
    },
  },
  autorequire: {
    file: Nexus3::Config.file_path,
  },
)
