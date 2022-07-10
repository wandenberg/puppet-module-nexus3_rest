# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/provider/nexus3_utils'

# Implementation for the nexus3_repository type using the Resource API.
class Puppet::Provider::Nexus3Repository::Nexus3Repository < Puppet::ResourceApi::SimpleProvider
  include Puppet::Provider::Nexus3Utils

  def canonicalize(context, resources)
    resources.each do |r|
      next if skip_resource?(r)

      apply_default_values(context, r)

      assert_present(r[:type], 'type must not be empty')
      assert_present(r[:provider_type], 'provider_type must not be empty')
      raise ArgumentError, 'cleanup_policies must be an array of strings' unless r[:cleanup_policies].is_a?(Array)
      raise ArgumentError, 'depth must be within [0, 5]' unless r[:depth].to_s.empty? || (0..5).cover?(r[:depth].to_i)
      raise ArgumentError, 'remote_retries must be within [1, 10]' unless r[:remote_retries].to_s.empty? || (1..10).cover?(r[:remote_retries].to_i)
      raise ArgumentError, 'remote_connection_timeout must be within [1, 3600]' unless r[:remote_connection_timeout].to_s.empty? || (1..3600).cover?(r[:remote_connection_timeout].to_i)

      if r[:type] == 'hosted'
        case r[:provider_type]
        when 'docker'
          r[:force_basic_auth] = false if r[:force_basic_auth].to_s.empty?
          r[:v1_enabled] = false if r[:v1_enabled].to_s.empty?
          r[:write_policy] = 'allow_write' if r[:write_policy].to_s.empty?
        when 'maven2'
          r[:content_disposition] = 'inline' if r[:content_disposition].to_s.empty?
          r[:layout_policy] = 'strict' if r[:layout_policy].to_s.empty?
          r[:version_policy] = 'release' if r[:version_policy].to_s.empty?
        when 'r'
          r[:write_policy] = 'allow_write' if r[:write_policy].to_s.empty?
        when 'raw'
          r[:content_disposition] = 'attachment' if r[:content_disposition].to_s.empty?
          r[:strict_content_type_validation] = false if r[:strict_content_type_validation].to_s.empty?
          r[:write_policy] = 'allow_write' if r[:write_policy].to_s.empty?
        when 'yum'
          r[:depth] = 0 if r[:depth].to_s.empty?
          r[:layout_policy] = 'strict' if r[:layout_policy].to_s.empty?
        else
          raise ArgumentError, "'#{r[:provider_type]}' not supported for hosted type" unless %w[apt bower docker gitlfs helm maven2 npm nuget pypi r raw rubygems yum].include?(r[:provider_type])
        end

        r[:proprietary_components] = false if r[:proprietary_components].to_s.empty?
        r[:strict_content_type_validation] = true if r[:strict_content_type_validation].to_s.empty?
        r[:write_policy] = 'allow_write_once' if r[:write_policy].to_s.empty?
      end

      if r[:type] == 'proxy'
        case r[:provider_type]
        when 'apt'
          r[:is_flat] = false if r[:is_flat].to_s.empty?
        when 'bower'
          r[:rewrite_package_urls] = true if r[:rewrite_package_urls].to_s.empty?
        when 'docker'
          r[:force_basic_auth] = false if r[:force_basic_auth].to_s.empty?
          r[:v1_enabled] = false if r[:v1_enabled].to_s.empty?
          r[:index_type] = 'registry' if r[:index_type].to_s.empty?
          r[:cache_foreign_layers] = false if r[:cache_foreign_layers].to_s.empty?
          r[:foreign_layers_url_whitelist] = ['.*'] if r[:foreign_layers_url_whitelist].empty? && r[:cache_foreign_layers]
        when 'maven2'
          r[:content_disposition] = 'inline' if r[:content_disposition].to_s.empty?
          r[:layout_policy] = 'strict' if r[:layout_policy].to_s.empty?
          r[:version_policy] = 'release' if r[:version_policy].to_s.empty?
        when 'npm'
          r[:remove_non_cataloged] = false if r[:remove_non_cataloged].to_s.empty?
          r[:remove_quarantined_versions] = false if r[:remove_quarantined_versions].to_s.empty?
        when 'nuget'
          r[:nuget_version] = 'V3' if r[:nuget_version].to_s.empty?
          r[:query_cache_item_max_age] = 3600 if r[:query_cache_item_max_age].to_s.empty?
        when 'raw'
          r[:content_disposition] = 'attachment' if r[:content_disposition].to_s.empty?
        when 'p2'
          r[:auto_block] = false if r[:auto_block].to_s.empty?
        else
          raise ArgumentError, "'#{r[:provider_type]}' not supported for proxy type" unless %w[apt bower cocoapods conan conda docker go helm maven2 npm nuget p2 pypi r raw
                                                                                               rubygems yum].include?(r[:provider_type])
        end

        r[:auto_block] = true if r[:auto_block].to_s.empty?
        r[:blocked] = false if r[:blocked].to_s.empty?
        r[:remote_enable_cookies] = false if r[:remote_enable_cookies].to_s.empty?
        r[:remote_enable_circular_redirects] = false if r[:remote_enable_circular_redirects].to_s.empty?
        r[:negative_cache_enabled] = true if r[:negative_cache_enabled].to_s.empty?
        r[:negative_cache_ttl] = 1440 if r[:negative_cache_ttl].to_s.empty?
        r[:metadata_max_age] = 1440 if r[:metadata_max_age].to_s.empty?
        r[:content_max_age] = (r[:version_policy] == 'release' ? -1 : 1440) if r[:content_max_age].to_s.empty?
        r[:strict_content_type_validation] = true if r[:strict_content_type_validation].to_s.empty?
      end

      munge_and_assert_port(r, :http_port) unless r[:http_port].to_s.empty?
      munge_and_assert_port(r, :https_port) unless r[:https_port].to_s.empty?
      munge_booleans(context, r)

      r[:depth] = r[:depth].to_i unless r[:depth].to_s.empty?
      r[:cleanup_policies].sort!
      r[:foreign_layers_url_whitelist].sort!
    end
  end

  def set(context, changes)
    changes.each do |_name, change|
      is = change[:is]
      should = change[:should]

      next unless is[:ensure] == 'present' && should[:ensure] == 'present'

      raise ArgumentError, 'type cannot be changed' unless is[:type] == should[:type]
      raise ArgumentError, 'provider_type cannot be changed' unless is[:provider_type] == should[:provider_type]
      raise ArgumentError, 'version_policy cannot be changed' unless is[:version_policy] == should[:version_policy]
      raise ArgumentError, 'blobstore_name cannot be changed' unless is[:blobstore_name] == should[:blobstore_name]
    end

    super(context, changes)
  end

  def delete(_context, name)
    unless Nexus3::Config.can_delete_repositories
      raise "The current configuration prevents the deletion of nexus_repository #{name}; " \
            "If this change is intended, please update the configuration file (#{Nexus3::Config.file_path}) in order to perform this change."
    end

    super
  end
end
