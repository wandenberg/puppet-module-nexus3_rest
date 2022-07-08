# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/provider/nexus3_utils'

# Implementation for the nexus3_routing_rule type using the Resource API.
class Puppet::Provider::Nexus3RoutingRule::Nexus3RoutingRule < Puppet::ResourceApi::SimpleProvider
  include Puppet::Provider::Nexus3Utils

  def canonicalize(context, resources)
    resources.each do |r|
      next if skip_resource?(r)

      apply_default_values(context, r)

      raise ArgumentError, 'At least one matcher is required' if r[:matchers].nil? || !r[:matchers].is_a?(Array) || r[:matchers].empty?

      r[:matchers].sort!
    end
  end
end
