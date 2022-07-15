# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/provider/nexus3_utils'

# Implementation for the nexus3_privilege type using the Resource API.
class Puppet::Provider::Nexus3Privilege::Nexus3Privilege < Puppet::ResourceApi::SimpleProvider
  include Puppet::Provider::Nexus3Utils

  def canonicalize(context, resources)
    resources.each do |r|
      next if skip_resource?(r)

      apply_default_values(context, r)

      assert_present(r[:type], 'type must not be empty')

      case r[:type]
      when 'application'
        assert_present(r[:actions], 'actions must not be empty')
        assert_present(r[:domain], 'domain must not be empty')
      when 'repository-admin', 'repository-view'
        assert_present(r[:actions], 'actions must not be empty')
        assert_present(r[:format], 'format must not be empty')
        assert_present(r[:repository_name], 'repository_name must not be empty')
      when 'repository-content-selector'
        assert_present(r[:actions], 'actions must not be empty')
        assert_present(r[:content_selector], 'content_selector must not be empty')
        assert_present(r[:repository_name], 'repository_name must not be empty')
      when 'script'
        assert_present(r[:actions], 'actions must not be empty')
        assert_present(r[:script_name], 'script_name must not be empty')
      when 'wildcard'
        assert_present(r[:pattern], 'pattern must not be empty')
      else
        raise ArgumentError, "Type '#{r[:type]}' not supported"
      end
    end
  end
end
