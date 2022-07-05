# frozen_string_literal: true

require 'puppet/resource_api'
require 'puppet_x/nexus3/config'

Puppet::ResourceApi.register_type(
  name: 'nexus3_smtp_settings',
  docs: <<-EOS,
@summary a nexus3_smtp_settings type
@example
nexus3_smtp_settings { 'global':
  enabled      => true,
  host         => 'localhost',
  port         => 25,
  from_address => 'nexus@example.org',
}

This type provides Puppet with the capabilities to manage Nexus 3 SMTP settings.

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
    enabled: {
      type: 'Boolean',
      desc: 'When SMTP settings is enabled or not.',
      default: false,
    },
    host: {
      type: 'Pattern[/\A.+\Z/]',
      desc: 'The host name of the SMTP server.',
      default: 'localhost',
    },
    port: {
      type: 'Integer',
      desc: 'The port number the SMTP server is listening on. Must be within 1 and 65535.',
      default: 25,
    },
    username: {
      type: 'String',
      desc: 'The username used to access the SMTP server.',
      default: '',
    },
    password: {
      type: 'String',
      desc: 'The expected value of the password.',
      default: '',
    },
    from_address: {
      type: 'Pattern[/\A.+@.+\..+\z/]',
      desc: 'Email address used in the `From:` field.',
      default: 'nexus@example.org',
    },
    subject_prefix: {
      type: 'String',
      desc: 'Email subject prefix.',
      default: '',
    },
    nexus_trust_store_enabled: {
      type: 'Boolean',
      desc: 'When Nexus Repository truststore should be used or not.',
      default: false,
    },
    start_tls_enabled: {
      type: 'Boolean',
      desc: 'When STARTTLS support is enabled or not.',
      default: false,
    },
    start_tls_required: {
      type: 'Boolean',
      desc: 'When STARTTLS support is required or not.',
      default: false,
    },
    ssl_on_connect_enabled: {
      type: 'Boolean',
      desc: 'When SSL/TLS encryption is enabled or not.',
      default: false,
    },
    ssl_check_server_identity_enabled: {
      type: 'Boolean',
      desc: 'When server identity check is enabled or not.',
      default: false,
    },
  },
  autorequire: {
    file: Nexus3::Config.file_path,
  },
)
