# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/provider/nexus3_utils'

# Implementation for the nexus3_http_settings type using the Resource API.
class Puppet::Provider::Nexus3HttpSettings::Nexus3HttpSettings < Puppet::ResourceApi::SimpleProvider
  include Puppet::Provider::Nexus3Utils

  def canonicalize(context, resources)
    resources.each do |r|
      unless r[:http_enabled]
        properties = %i[http_port http_host http_auth_type http_auth_username http_auth_password http_auth_ntlm_host http_auth_ntlm_domain
                        https_port https_host https_auth_type https_auth_username https_auth_password https_auth_ntlm_host https_auth_ntlm_domain]
        rejected_properties = properties.map { |property| property if value_provided?(r, property) }.compact
        raise ArgumentError, "#{rejected_properties.join(' and ')} not allowed when http proxy is disabled" unless rejected_properties.empty?
      end

      unless r[:https_enabled]
        properties = %i[https_port https_host https_auth_type https_auth_username https_auth_password https_auth_ntlm_host https_auth_ntlm_domain]
        rejected_properties = properties.map { |property| property if value_provided?(r, property) }.compact
        raise ArgumentError, "#{rejected_properties.join(' and ')} not allowed when https proxy is disabled" unless rejected_properties.empty?
      end

      apply_default_values(context, r)

      if r[:http_enabled]
        assert_present(r[:http_host], 'http_host must not be empty')
        assert_present(r[:http_port], 'http_port must not be empty')

        unless r[:http_auth_type].empty?
          assert_present(r[:http_auth_username], 'http_auth_username must not be empty')

          if r[:http_auth_type] == 'ntlm'
            assert_present(r[:http_auth_ntlm_host], 'http_auth_ntlm_host must not be empty')
            assert_present(r[:http_auth_ntlm_domain], 'http_auth_ntlm_domain must not be empty')
          end
        end

        if r[:https_enabled]
          assert_present(r[:https_host], 'https_host must not be empty')
          assert_present(r[:https_port], 'https_port must not be empty')

          unless r[:https_auth_type].empty?
            assert_present(r[:https_auth_username], 'https_auth_username must not be empty')

            if r[:https_auth_type] == 'ntlm'
              assert_present(r[:https_auth_ntlm_host], 'https_auth_ntlm_host must not be empty')
              assert_present(r[:https_auth_ntlm_domain], 'https_auth_ntlm_domain must not be empty')
            end
          end
        end
      end

      r[:name] = 'global'

      r[:connection_timeout] = r[:connection_timeout].to_i
      raise ArgumentError, 'connection_timeout must be within [1, 3600]' unless (1..3_600).cover?(r[:connection_timeout])

      r[:connection_maximum_retries] = r[:connection_maximum_retries].to_i
      raise ArgumentError, 'connection_maximum_retries must be within [1, 10]' unless (1..10).cover?(r[:connection_maximum_retries])

      munge_and_assert_port(r, :http_port) unless r[:http_port].to_s.empty?
      munge_and_assert_port(r, :https_port) unless r[:https_port].to_s.empty?
      munge_booleans(context, r)
    end
  end

  def create(context, _name, _should)
    context.notice('Not possible to create new HTTP settings')
  end

  def delete(context, _name)
    context.notice('Not possible to remove HTTP settings')
  end

  def max_instances_allowed
    1
  end

  def value_provided?(r, property)
    r[property].is_a?(Array) ? !r[property].empty? : !r[property].to_s.empty?
  end
end
