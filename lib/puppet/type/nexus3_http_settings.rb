# frozen_string_literal: true

require 'puppet/resource_api'
require 'puppet_x/nexus3/config'

Puppet::ResourceApi.register_type(
  name: 'nexus3_http_settings',
  docs: <<-EOS,
@summary a nexus3_http_settings type
@example
nexus3_http_settings { 'global':
  connection_user_agent      => 'nexus_useragent',
  connection_timeout         => 90,
  connection_maximum_retries => 2,
}

This type provides Puppet with the capabilities to manage Nexus 3 Http settings.

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
    http_enabled: {
      type: 'Boolean',
      desc: 'When HTTP proxy configurations are enabled or not.',
      default: false,
    },
    http_port: {
      type: 'Variant[Integer, String]',
      desc: 'Port of the HTTP proxy to connect to.',
      default: '',
    },
    http_host: {
      type: 'String',
      desc: 'Host of the HTTP proxy to connect to.',
      default: '',
    },
    http_auth_type: {
      type: 'Pattern[/\A(username|ntlm)?\z/]',
      desc: 'Type of authentication used to connect to HTTP proxy.',
      default: '',
    },
    http_auth_username: {
      type: 'String',
      desc: 'Username used to connect to HTTP proxy.',
      default: '',
    },
    http_auth_password: {
      type: 'String',
      desc: 'Password used to connect to HTTP proxy.',
      default: '',
    },
    http_auth_ntlm_host: {
      type: 'String',
      desc: 'NTLM host used to connect to HTTP proxy.',
      default: '',
    },
    http_auth_ntlm_domain: {
      type: 'String',
      desc: 'NTLM domain used to connect to HTTP proxy.',
      default: '',
    },
    https_enabled: {
      type: 'Boolean',
      desc: 'When HTTPS proxy configurations are enabled or not.',
      default: false,
    },
    https_port: {
      type: 'Variant[Integer, String]',
      desc: 'Port of the HTTPS proxy to connect to.',
      default: '',
    },
    https_host: {
      type: 'String',
      desc: 'Host of the HTTPS proxy to connect to.',
      default: '',
    },
    https_auth_type: {
      type: 'String',
      desc: 'Type of authentication used to connect to HTTPS proxy.',
      default: '',
    },
    https_auth_username: {
      type: 'String',
      desc: 'Username used to connect to HTTPS proxy.',
      default: '',
    },
    https_auth_password: {
      type: 'String',
      desc: 'When HTTPS proxy configurations are enabled or not.',
      default: '',
    },
    https_auth_ntlm_host: {
      type: 'String',
      desc: 'Port of the HTTPS proxy to connect to.',
      default: '',
    },
    https_auth_ntlm_domain: {
      type: 'String',
      desc: 'Host of the HTTPS proxy to connect to.',
      default: '',
    },
    non_proxy_hosts: {
      type: 'Array[String]',
      desc: 'List of hosts that should bypass the proxy usage.',
      default: [],
    },
    connection_user_agent: {
      type: 'String',
      desc: 'User agent suffix to be added on the connections using the proxy.',
      default: '',
    },
    connection_timeout: {
      type: 'Integer',
      desc: 'Connection timeout to be used on connections to the proxy.',
      default: 20,
    },
    connection_maximum_retries: {
      type: 'Integer',
      desc: 'Maximum number of retires to be used on connections to the proxy.',
      default: 2,
    },
  },
  autorequire: {
    file: Nexus3::Config.file_path,
  },
)
