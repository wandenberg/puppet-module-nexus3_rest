# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/provider/nexus3_utils'

# Implementation for the nexus3_blobstore type using the Resource API.
class Puppet::Provider::Nexus3Blobstore::Nexus3Blobstore < Puppet::ResourceApi::SimpleProvider
  include Puppet::Provider::Nexus3Utils

  def canonicalize(context, resources)
    file_type_allowed_keys = %i[name path type soft_quota_enabled quota_type quota_limit_bytes ensure]
    resources.each do |r|
      next if skip_resource?(r)

      apply_default_values(context, r)

      if r[:type] == 'File'
        assert_present(r[:path], 'Path is required')

        r.each_key { |key| r[key] = '' unless file_type_allowed_keys.include?(key) }
      elsif r[:type] == 'S3'
        assert_present(r[:bucket], 'Bucket is required')

        r[:expiration] = 3 if r[:expiration].to_s.empty?
        raise ArgumentError, 'Expiration must be equal or greater than -1' if r[:expiration].to_i < -1

        has_key_id = !r[:access_key_id].nil? && !r[:access_key_id].strip.empty?
        has_key_secret = !r[:secret_access_key].nil? && !r[:secret_access_key].strip.empty?
        raise ArgumentError, 'Either set access_key_id and secret_access_key, or none.' if has_key_id ^ has_key_secret

        raise ArgumentError, 'max_connection_pool_size must be equal or greater than 1' if !r[:max_connection_pool_size].to_s.empty? && r[:max_connection_pool_size].to_i < 1

        r[:region] = 'DEFAULT' if r[:region].to_s.empty?
        r[:path] = ''
      end

      munge_booleans(context, r)

      if !r[:soft_quota_enabled].to_s.empty? && r[:soft_quota_enabled]
        raise ArgumentError, 'quota_type must be provided' if r[:quota_type].nil? || r[:quota_type].strip.empty?
        raise ArgumentError, 'quota_limit_bytes must be greater than 0' if r[:quota_limit_bytes].to_i <= 0
      end
    end
  end
end
