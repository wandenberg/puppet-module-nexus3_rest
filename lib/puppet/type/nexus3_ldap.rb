require 'puppet/property/boolean'

Puppet::Type.newtype(:nexus3_ldap) do
  @doc = 'Manages Nexus 3 LDAP connection settings.'

  ensurable

  newparam(:name, namevar: true) do
    desc 'Unique LDAP connection identifier; once created cannot be changed unless the connection is destroyed. The Nexus UI will show it as connection id.'
  end

  newparam(:id) do
    desc 'LDAP settings ID'
  end

  newproperty(:order) do
    desc 'The order number of the LDAP configuration.'
    munge { |value| Integer(value) }
  end

  newproperty(:protocol) do
    desc 'The LDAP protocol to use. Can be one of: `ldap` or `ldaps`.'
    defaultto :ldap
    newvalues(:ldaps, :ldap)
  end

  newproperty(:hostname) do
    desc 'The host name of the LDAP server.'
    validate do |value|
      raise ArgumentError, 'Hostname must not be empty' if value.nil? || value.to_s.empty?
    end
  end

  newproperty(:port) do
    desc 'The port number the LDAP server is listening on. Must be within 1 and 65535.'
    defaultto 389
    validate do |value|
      raise ArgumentError, "Port must be a non-negative integer, got #{value}" unless %r{\d+}.match?(value.to_s)
      raise ArgumentError, "Port must within [1, 65535], got #{value}" unless (1..65_535).cover?(value.to_i)
    end
    munge { |value| Integer(value) }
  end

  newproperty(:search_base) do
    desc 'The LDAP search base to use.'
    validate do |value|
      raise ArgumentError, 'search_base must not be empty' if value.nil? || value.to_s.empty?
    end
  end

  newproperty(:max_incidents_count) do
    desc 'The number of failed attempts before being blacklisted.'
    defaultto 3
    munge { |value| Integer(value) }
  end

  newproperty(:connection_retry_delay) do
    desc 'The number of seconds between failed connections attempts.'
    defaultto 300
    munge { |value| Integer(value) }
  end

  newproperty(:connection_timeout) do
    desc 'The number of seconds before timeout.'
    defaultto 30
    munge { |value| Integer(value) }
  end

  newproperty(:authentication_scheme) do
    desc 'The authentication scheme protocol to use. Can be one of: `simple`, `none`, `DIGEST-MD5` or `CRAM-MD5`.'
    defaultto :none
    newvalues(:simple, :none, :'DIGEST-MD5', :'CRAM-MD5')
  end

  newproperty(:username) do
    desc 'The username used to access the LDAP server.'
  end

  newparam(:password) do
    desc 'The expected value of the password.'
  end

  newproperty(:sasl_realm) do
    desc 'The LDAP realm to use.'
  end

  newproperty(:user_base_dn) do
    desc 'The LDAP user base DN.'
  end

  newproperty(:user_subtree, parent: Puppet::Property::Boolean) do
    desc 'Set to true if users are in a subtree under the user base DN.'
    newvalues(:true, :false)
    defaultto :false
    munge { |value| super(value).to_s.to_sym }
  end

  newproperty(:user_object_class) do
    desc 'The LDAP user object class.'
  end

  newproperty(:ldap_filter) do
    desc 'The LDAP filter to use to filter users.'
  end

  newproperty(:user_id_attribute) do
    desc 'The LDAP attribute to use for user ID.'
  end

  newproperty(:user_real_name_attribute) do
    desc 'The LDAP attribute to use for user display name.'
  end

  newproperty(:user_email_attribute) do
    desc 'The LDAP attribute to use for user email address.'
  end

  newproperty(:user_password_attribute) do
    desc 'The LDAP attribute to use for user password.'
  end

  newproperty(:user_member_of_attribute) do
    desc 'The LDAP attribute to use for user member of attribute.'
  end

  newproperty(:ldap_groups_as_roles, parent: Puppet::Property::Boolean) do
    desc 'Set to true if Nexus should map LDAP groups to roles.'
    newvalues(:true, :false)
    defaultto :true
    munge { |value| super(value).to_s.to_sym }
  end

  newproperty(:ldap_groups_as_roles_type) do
    desc 'Set LDAP group type. Can be one of: `static` or `dynamic`.'
    defaultto :static
    newvalues(:static, :dynamic)
  end

  newproperty(:group_base_dn) do
    desc 'The LDAP group base dn to use.'
  end

  newproperty(:group_subtree, parent: Puppet::Property::Boolean) do
    desc 'Set to true if groups are in a subtree under the group base DN.'
    newvalues(:true, :false)
    defaultto :false
    munge { |value| super(value).to_s.to_sym }
  end

  newproperty(:group_object_class) do
    desc 'The LDAP group object class to use.'
  end

  newproperty(:group_id_attribute) do
    desc 'The LDAP group ID attribute to use.'
  end

  newproperty(:group_member_attribute) do
    desc 'The LDAP group member attribute to use.'
  end

  newproperty(:group_member_format) do
    desc 'The LDAP group member format to use.'
  end

  validate do
    if self[:ensure] == :present
      raise ArgumentError, 'hostname must be provided' if self[:hostname].to_s.empty?
      raise ArgumentError, 'search_base must be provided' if self[:search_base].to_s.empty?
      if self[:ldap_groups_as_roles] == :true and self[:ldap_groups_as_roles_type] == :static
        raise ArgumentError, 'group_base_dn must not be empty when using ldap_groups_as_roles and ldap_groups_as_roles_type being set to static' if self[:group_base_dn].nil? || self[:group_base_dn].to_s.empty?
        raise ArgumentError, 'group_object_class must not be empty when using ldap_groups_as_roles and ldap_groups_as_roles_type being set to static' if self[:group_object_class].nil? || self[:group_object_class].to_s.empty?
        raise ArgumentError, 'group_id_attribute must not be empty when using ldap_groups_as_roles and ldap_groups_as_roles_type being set to static' if self[:group_id_attribute].nil? || self[:group_id_attribute].to_s.empty?
        raise ArgumentError, 'group_member_attribute must not be empty when using ldap_groups_as_roles and ldap_groups_as_roles_type being set to static' if self[:group_member_attribute].nil? || self[:group_member_attribute].to_s.empty?
        raise ArgumentError, 'group_member_format must not be empty when using ldap_groups_as_roles and ldap_groups_as_roles_type being set to static' if self[:group_member_format].nil? || self[:group_member_format].to_s.empty?
      end
    end
  end

  autorequire(:file) do
    Nexus3::Config.file_path
  end
end
