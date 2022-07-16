# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/provider/nexus3_utils'

# Implementation for the nexus3_role type using the Resource API.
class Puppet::Provider::Nexus3Role::Nexus3Role < Puppet::ResourceApi::SimpleProvider
  include Puppet::Provider::Nexus3Utils

  def canonicalize(context, resources)
    resources.each do |r|
      next if skip_resource?(r)

      apply_default_values(context, r)

      raise ArgumentError, 'privileges must be an array of strings' unless r[:privileges].is_a?(Array)
      raise ArgumentError, 'roles must be an array of strings' unless r[:roles].is_a?(Array)

      munge_booleans(context, r)
      r[:privileges].sort!
      r[:roles].sort!
    end
  end
end
