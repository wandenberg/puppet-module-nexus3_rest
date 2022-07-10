# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/provider/nexus3_utils'

# Implementation for the nexus3_ldap type using the Resource API.
class Puppet::Provider::Nexus3Ldap::Nexus3Ldap < Puppet::ResourceApi::SimpleProvider
  include Puppet::Provider::Nexus3Utils

  def canonicalize(context, resources)
    resources.each do |r|
      next if skip_resource?(r)

      apply_default_values(context, r)

      assert_present(r[:hostname], 'Hostname must not be empty')
      assert_present(r[:search_base], 'search_base must not be empty')

      munge_and_assert_port(r, :port)
      munge_booleans(context, r)

      next unless r[:ldap_groups_as_roles]

      assert_present(r[:group_type], 'group_type is required when using groups as roles')

      if r[:group_type] == 'static'
        assert_present(r[:group_base_dn], 'group_base_dn is required when using static groups as roles')
        assert_present(r[:group_object_class], 'group_object_class is required when using static groups as roles')
        assert_present(r[:group_id_attribute], 'group_id_attribute is required when using static groups as roles')
        assert_present(r[:group_member_attribute], 'group_member_attribute is required when using static groups as roles')
        assert_present(r[:group_member_format], 'group_member_format is required when using static groups as roles')
      end

      if r[:group_type] == 'dynamic'
        assert_present(r[:user_member_of_attribute], 'user_member_of_attribute is required when using dynamic groups as roles')
      end
    end
  end
end
