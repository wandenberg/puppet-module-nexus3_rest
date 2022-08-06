# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/provider/nexus3_utils'

# Implementation for the nexus3_user type using the Resource API.
class Puppet::Provider::Nexus3User::Nexus3User < Puppet::ResourceApi::SimpleProvider
  include Puppet::Provider::Nexus3Utils

  def canonicalize(context, resources)
    resources.each do |r|
      next if skip_resource?(r)

      apply_default_values(context, r)

      assert_present(r[:firstname], 'firstname is required')
      assert_present(r[:lastname], 'lastname is required')
      assert_present(r[:email], 'email is required')

      raise ArgumentError, 'At least one role is required' if r[:roles].nil? || !r[:roles].is_a?(Array) || r[:roles].empty?

      munge_booleans(context, r)
      r[:roles].sort!
    end
  end

  def create(_context, _name, should)
    assert_present(should[:password], 'password is required')
    super
  end

  def delete_config_script(resource)
    "security.securitySystem.deleteUser('#{resource[:name]}')"
  end
end
