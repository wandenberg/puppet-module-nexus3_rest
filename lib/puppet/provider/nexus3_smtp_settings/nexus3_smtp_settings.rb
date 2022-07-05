# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/provider/nexus3_utils'

# Implementation for the nexus3_smtp_settings type using the Resource API.
class Puppet::Provider::Nexus3SmtpSettings::Nexus3SmtpSettings < Puppet::ResourceApi::SimpleProvider
  include Puppet::Provider::Nexus3Utils

  def canonicalize(context, resources)
    resources.each do |r|
      apply_default_values(context, r)

      r[:name] = 'global'
      munge_and_assert_port(r, :port)
      munge_booleans(context, r)
    end
  end

  def create(context, _name, _should)
    context.notice('Not possible to create new SMTP settings')
  end

  def delete(context, _name)
    context.notice('Not possible to remove SMTP settings')
  end

  def max_instances_allowed
    1
  end
end
