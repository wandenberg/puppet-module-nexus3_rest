# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/provider/nexus3_utils'

# Implementation for the nexus3_cleanup_policy type using the Resource API.
class Puppet::Provider::Nexus3CleanupPolicy::Nexus3CleanupPolicy < Puppet::ResourceApi::SimpleProvider
  include Puppet::Provider::Nexus3Utils

  def canonicalize(context, resources)
    resources.each do |r|
      next if skip_resource?(r)

      apply_default_values(context, r)
      munge_booleans(context, r)
    end
  end
end
