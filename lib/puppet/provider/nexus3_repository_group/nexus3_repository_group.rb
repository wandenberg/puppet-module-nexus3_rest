# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/provider/nexus3_utils'

# Implementation for the nexus3_repository_group type using the Resource API.
class Puppet::Provider::Nexus3RepositoryGroup::Nexus3RepositoryGroup < Puppet::ResourceApi::SimpleProvider
  include Puppet::Provider::Nexus3Utils

  def canonicalize(context, resources)
    resources.each do |r|
      next if skip_resource?(r)

      apply_default_values(context, r)

      assert_present(r[:provider_type], 'provider_type must not be empty')
      raise ArgumentError, 'repositories must be an array of strings' unless r[:repositories].is_a?(Array) && !r[:repositories].empty?

      case r[:provider_type]
      when 'docker'
        r[:force_basic_auth] = false if r[:force_basic_auth].to_s.empty?
        r[:v1_enabled] = false if r[:v1_enabled].to_s.empty?
      when 'maven2'
        r[:content_disposition] = 'inline' if r[:content_disposition].to_s.empty?
        r[:layout_policy] = 'strict' if r[:layout_policy].to_s.empty?
        r[:version_policy] = 'release' if r[:version_policy].to_s.empty?
      when 'raw'
        r[:content_disposition] = 'attachment' if r[:content_disposition].to_s.empty?
      else
        raise ArgumentError, "'#{r[:provider_type]}' not supported" unless %w[bower docker go maven2 npm nuget pypi r raw rubygems yum].include?(r[:provider_type])
      end

      r[:strict_content_type_validation] = true if r[:strict_content_type_validation].to_s.empty?

      munge_and_assert_port(r, :http_port) unless r[:http_port].to_s.empty?
      munge_and_assert_port(r, :https_port) unless r[:https_port].to_s.empty?
      munge_booleans(context, r)
    end
  end

  def set(context, changes)
    changes.each do |_name, change|
      is = change[:is]
      should = change[:should]

      next unless is[:ensure] == 'present' && should[:ensure] == 'present'

      raise ArgumentError, 'provider_type cannot be changed' unless is[:provider_type] == should[:provider_type]
      raise ArgumentError, 'version_policy cannot be changed' unless is[:version_policy] == should[:version_policy]
      raise ArgumentError, 'blobstore_name cannot be changed' unless is[:blobstore_name] == should[:blobstore_name]
    end

    super(context, changes)
  end

  def delete_config_script(resource)
    "repository.repositoryManager.delete('#{resource[:name]}')"
  end
end
