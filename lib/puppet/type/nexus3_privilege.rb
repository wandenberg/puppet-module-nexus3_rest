require 'puppet/resource_api'
require 'puppet_x/nexus3/config'

Puppet::ResourceApi.register_type(
  name: 'nexus3_privilege',
  docs: <<-EOS,
@summary a nexus3_privilege type
@example
nexus3_privilege { 'nx-all':
  type        => 'wildcard',
  description => 'All permissions',
  pattern     => 'nexus:*',
}

This type provides Puppet with the capabilities to manage Nexus 3 Privilege.

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
      desc: 'Unique privilege name.',
      behaviour: :namevar,
    },
    type: {
      type: 'Pattern[/\A(application|repository-admin|repository-content-selector|repository-view|script|wildcard)\z/]',
      desc: 'The type of the privilege',
    },
    description: {
      type: 'String',
      desc: 'The description of the privilege.',
      default: '',
    },
    pattern: {
      type: 'String',
      desc: 'The regex pattern.',
      default: '',
    },
    domain: {
      type: 'String',
      desc: 'The domain for the privilege.',
      default: '',
    },
    actions: {
      type: 'String',
      desc: 'The comma-delimited list of actions.',
      default: '',
    },
    format: {
      type: 'String',
      desc: 'The format(s) for the repository.',
      default: '',
    },
    repository_name: {
      type: 'String',
      desc: 'The repository name.',
      default: '',
    },
    script_name: {
      type: 'String',
      desc: 'The name of the script.',
      default: '',
    },
    content_selector: {
      type: 'String',
      desc: 'The name of the script.',
      default: '',
    },
  },
  autorequire: {
    file: Nexus3::Config.file_path,
  },
)
