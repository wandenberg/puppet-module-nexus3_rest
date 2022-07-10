# frozen_string_literal: true

require 'puppet/resource_api'
require 'puppet_x/nexus3/config'

Puppet::ResourceApi.register_type(
  name: 'nexus3_ldap',
  docs: <<-EOS,
@summary a nexus3_ldap type
@example
nexus3_ldap { 'ldap':
  protocol                 => 'ldap',
  hostname                 => 'localhost',
  port                     => 389,
  search_base              => 'dc=example,dc=com',
  user_object_class        => 'inetOrgPerson',
  user_email_attribute     => 'mail',
  user_id_attribute        => 'uid',
  user_real_name_attribute => 'cn',
  ldap_groups_as_roles     => false,
}

This type provides Puppet with the capabilities to manage Nexus 3 LDAP connection settings.

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
      desc: 'Unique LDAP connection identifier; once created cannot be changed unless the connection is destroyed. The Nexus UI will show it as connection id.',
      behaviour: :namevar,
    },
    order: {
      type: 'Integer',
      desc: 'The order number of the LDAP configuration.',
      default: 1,
    },
    protocol: {
      type: 'Enum[ldap, ldaps]',
      desc: 'The LDAP protocol to use. Can be one of: `ldap` or `ldaps`.',
      default: 'ldap',
    },
    hostname: {
      type: 'String',
      desc: 'The host name of the LDAP server.',
    },
    port: {
      type: 'Integer',
      desc: 'The port number the LDAP server is listening on. Must be within 1 and 65535.',
      default: 389,
    },
    search_base: {
      type: 'String',
      desc: 'The LDAP search base to use.',
    },
    max_incidents_count: {
      type: 'Integer',
      desc: 'The number of failed attempts before being blacklisted.',
      default: 3,
    },
    connection_retry_delay: {
      type: 'Integer',
      desc: 'The number of seconds between failed connections attempts.',
      default: 300,
    },
    connection_timeout: {
      type: 'Integer',
      desc: 'The number of seconds before timeout.',
      default: 30,
    },
    authentication_scheme: {
      type: 'Pattern[/\A(simple|none|DIGEST-MD5|CRAM-MD5)\z/]',
      desc: 'The authentication scheme protocol to use. Can be one of: `simple`, `none`, `DIGEST-MD5` or `CRAM-MD5`.',
      default: 'none',
    },
    username: {
      type: 'String',
      desc: 'The username used to access the LDAP server.',
      default: '',
    },
    password: {
      type: 'String',
      desc: 'The expected value of the password.',
      default: '',
    },
    sasl_realm: {
      type: 'String',
      desc: 'The LDAP realm to use.',
      default: '',
    },
    user_base_dn: {
      type: 'String',
      desc: 'The LDAP user base DN.',
      default: '',
    },
    user_subtree: {
      type: 'Boolean',
      desc: 'Set to true if users are in a subtree under the user base DN.',
      default: false,
    },
    user_object_class: {
      type: 'String',
      desc: 'The LDAP user object class.',
      default: '',
    },
    ldap_filter: {
      type: 'String',
      desc: 'The LDAP filter to use to filter users.',
      default: '',
    },
    user_id_attribute: {
      type: 'String',
      desc: 'The LDAP attribute to use for user ID.',
      default: '',
    },
    user_real_name_attribute: {
      type: 'String',
      desc: 'The LDAP attribute to use for user display name.',
      default: '',
    },
    user_email_attribute: {
      type: 'String',
      desc: 'The LDAP attribute to use for user email address.',
      default: '',
    },
    user_password_attribute: {
      type: 'String',
      desc: 'The LDAP attribute to use for user password.',
      default: '',
    },
    user_member_of_attribute: {
      type: 'String',
      desc: 'The LDAP attribute to use for user member of attribute.',
      default: '',
    },
    ldap_groups_as_roles: {
      type: 'Boolean',
      desc: 'Set to true if Nexus should map LDAP groups to roles.',
      default: true,
    },
    group_type: {
      type: 'Pattern[/\A(static|dynamic)?\z/]',
      desc: 'Set LDAP group type. Can be one of: `static` or `dynamic`.',
      default: '',
    },
    group_base_dn: {
      type: 'String',
      desc: 'The LDAP group base dn to use.',
      default: '',
    },
    group_subtree: {
      type: 'Boolean',
      desc: 'Set to true if groups are in a subtree under the group base DN.',
      default: false,
    },
    group_object_class: {
      type: 'String',
      desc: 'The LDAP group object class to use.',
      default: '',
    },
    group_id_attribute: {
      type: 'String',
      desc: 'The LDAP group ID attribute to use.',
      default: '',
    },
    group_member_attribute: {
      type: 'String',
      desc: 'The LDAP group member attribute to use.',
      default: '',
    },
    group_member_format: {
      type: 'String',
      desc: 'The LDAP group member format to use.',
      default: '',
    },
  },
  autorequire: {
    file: Nexus3::Config.file_path,
  },
)
