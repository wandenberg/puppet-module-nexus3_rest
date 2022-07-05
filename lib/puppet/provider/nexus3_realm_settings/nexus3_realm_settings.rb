# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/provider/nexus3_utils'

# Implementation for the nexus3_realm_settings type using the Resource API.
class Puppet::Provider::Nexus3RealmSettings::Nexus3RealmSettings < Puppet::ResourceApi::SimpleProvider
  include Puppet::Provider::Nexus3Utils

  def canonicalize(context, resources)
    resources.each do |r|
      apply_default_values(context, r)

      r[:name] = 'global'
    end
  end

  def create(context, _name, _should)
    context.notice('Not possible to create new Realm settings')
  end

  def delete(context, _name)
    context.notice('Not possible to remove Realm settings')
  end

  def max_instances_allowed
    1
  end
end
