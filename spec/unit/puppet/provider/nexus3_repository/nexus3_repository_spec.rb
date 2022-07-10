# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::Nexus3Repository')
require 'puppet/provider/nexus3_repository/nexus3_repository'

RSpec.describe Puppet::Provider::Nexus3Repository::Nexus3Repository do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  let(:minimum_required_values) do
    {
      provider_type: 'rubygems',
      type: 'hosted',
      online: true,
      blobstore_name: 'default',
      strict_content_type_validation: true,
      write_policy: 'allow_write_once',
      proprietary_components: true,
    }
  end

  before(:each) do
    stub_config
    provider.get(context).each do |resource|
      provider.delete(context, resource[:name]) if resource[:name].match?(%r{^repository_})
    end

    name = "repository_#{SecureRandom.uuid}"
    provider.create(context, name, name: name, **minimum_required_values)
  end

  describe '#get' do
    it 'processes resources' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^repository_}) }
      expect(resources.size).to eq(1)
      expect(resources[0].keys.sort).to eq(%i[asset_history_limit auto_block blobstore_name blocked cleanup_policies content_max_age depth distribution force_basic_auth
                                              http_port https_port index_type index_url is_flat layout_policy metadata_max_age negative_cache_enabled negative_cache_ttl
                                              online pgp_keypair pgp_keypair_passphrase provider_type remote_auth_type remote_bearer_token remote_ntlm_domain remote_ntlm_host
                                              remote_password remote_url remote_user routing_rule strict_content_type_validation type v1_enabled version_policy write_policy
                                              proprietary_components content_disposition rewrite_package_urls cache_foreign_layers foreign_layers_url_whitelist
                                              remove_non_cataloged remove_quarantined_versions nuget_version query_cache_item_max_age remote_connection_timeout
                                              remote_enable_circular_redirects remote_enable_cookies remote_retries remote_user_agent name ensure].sort)
    end
  end

  describe 'set(context, changes)' do
    it 'prevent changing the type of the repository' do
      changes = {
        foo:  {
          is: { name: 'temporary', type: 'hosted', provider_type: 'rubygems', blobstore_name: 'default', version_policy: 'release', ensure: 'present' },
          should: { name: 'temporary', type: 'proxy', provider_type: 'rubygems', blobstore_name: 'default', version_policy: 'release', ensure: 'present' }
        }
      }
      expect { provider.set(context, changes) }.to raise_error(ArgumentError, %r{type cannot be changed})
    end

    it 'prevent changing the provider_type of the repository' do
      changes = {
        foo:  {
          is: { name: 'temporary', type: 'hosted', provider_type: 'rubygems', blobstore_name: 'default', version_policy: 'release', ensure: 'present' },
          should: { name: 'temporary', type: 'hosted', provider_type: 'npm', blobstore_name: 'default', version_policy: 'release', ensure: 'present' }
        }
      }
      expect { provider.set(context, changes) }.to raise_error(ArgumentError, %r{provider_type cannot be changed})
    end

    it 'prevent changing the blobstore_name of the repository' do
      changes = {
        foo:  {
          is: { name: 'temporary', type: 'hosted', provider_type: 'rubygems', blobstore_name: 'default', version_policy: 'release', ensure: 'present' },
          should: { name: 'temporary', type: 'hosted', provider_type: 'rubygems', blobstore_name: 'foo', version_policy: 'release', ensure: 'present' }
        }
      }
      expect { provider.set(context, changes) }.to raise_error(ArgumentError, %r{blobstore_name cannot be changed})
    end

    it 'prevent changing the version_policy of the repository' do
      changes = {
        foo:  {
          is: { name: 'temporary', type: 'hosted', provider_type: 'rubygems', blobstore_name: 'default', version_policy: 'release', ensure: 'present' },
          should: { name: 'temporary', type: 'hosted', provider_type: 'rubygems', blobstore_name: 'default', version_policy: 'mixed', ensure: 'present' }
        }
      }
      expect { provider.set(context, changes) }.to raise_error(ArgumentError, %r{version_policy cannot be changed})
    end
  end

  describe 'create(context, name, should)' do
    shared_examples_for 'simple repository' do
      it 'creates the resource' do
        resources = provider.get(context).filter { |resource| resource[:name].match(%r{^repository_}) }
        expect(resources.size).to eq(1)

        provider.create(context, values[:name], **values)

        resources = provider.get(context).filter { |resource| resource[:name].match(%r{^repository_}) }
        expect(resources.size).to eq(2)

        resource = resources.find { |r| r[:name] == values[:name] }
        expect(resource).to eq(values.merge(ensure: 'present'))
      end
    end

    context 'hosted repository' do
      let(:common_values) do
        {
          name: "repository_#{SecureRandom.uuid}",
          provider_type: 'rubygems',
          type: 'hosted',
          online: false,
          blobstore_name: 'default',
          strict_content_type_validation: false,
          write_policy: 'read_only',
          proprietary_components: true,
          cleanup_policies: [],
        }
      end

      let(:default_values) do
        {
          asset_history_limit: '',
          auto_block: '',
          blocked: '',
          content_max_age: '',
          depth: '',
          distribution: '',
          force_basic_auth: '',
          http_port: '',
          https_port: '',
          index_type: '',
          index_url: '',
          is_flat: '',
          layout_policy: '',
          metadata_max_age: '',
          negative_cache_enabled: '',
          negative_cache_ttl: '',
          pgp_keypair: '',
          pgp_keypair_passphrase: '',
          remote_auth_type: 'none',
          remote_bearer_token: '',
          remote_connection_timeout: '',
          remote_enable_circular_redirects: '',
          remote_enable_cookies: '',
          remote_ntlm_domain: '',
          remote_ntlm_host: '',
          remote_password: '',
          remote_retries: '',
          remote_url: '',
          remote_user: '',
          remote_user_agent: '',
          routing_rule: '',
          v1_enabled: '',
          version_policy: '',
          content_disposition: '',
          rewrite_package_urls: '',
          cache_foreign_layers: '',
          foreign_layers_url_whitelist: [],
          remove_non_cataloged: '',
          remove_quarantined_versions: '',
          nuget_version: '',
          query_cache_item_max_age: '',
        }
      end

      let(:specific_values) do
        {}
      end

      let(:values) { common_values.merge(default_values).merge(specific_values) }

      it_behaves_like 'simple repository'

      context 'for apt' do
        let(:specific_values) do
          {
            provider_type: 'apt',
            distribution: 'dist',
            pgp_keypair: 'my_signature',
            pgp_keypair_passphrase: 'my_pass',
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for docker' do
        let(:specific_values) do
          {
            provider_type: 'docker',
            http_port: 9990,
            https_port: 9991,
            force_basic_auth: true,
            v1_enabled: true,
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for maven2' do
        let(:specific_values) do
          {
            provider_type: 'maven2',
            version_policy: 'mixed',
            layout_policy: 'permissive',
            content_disposition: 'attachment',
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for raw' do
        let(:specific_values) do
          {
            provider_type: 'raw',
            content_disposition: 'inline',
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for yum' do
        let(:specific_values) do
          {
            provider_type: 'yum',
            depth: 3,
            layout_policy: 'permissive',
          }
        end

        it_behaves_like 'simple repository'
      end
    end

    context 'proxy repository' do
      let(:common_values) do
        {
          name: "repository_#{SecureRandom.uuid}",
          provider_type: 'rubygems',
          type: 'proxy',
          online: false,
          remote_url: 'http://localhost.foo/bar',
          blocked: true,
          auto_block: false,
          content_max_age: 567,
          metadata_max_age: 789,
          blobstore_name: 'default',
          strict_content_type_validation: false,
          routing_rule: '',
          cleanup_policies: [],
          negative_cache_enabled: false,
          negative_cache_ttl: 432,
          remote_auth_type: 'username',
          remote_user: 'user',
          remote_password: 'pass',
          remote_user_agent: 'foo-agent',
          remote_retries: 4,
          remote_connection_timeout: 65,
          remote_enable_circular_redirects: true,
          remote_enable_cookies: true,
        }
      end

      let(:default_values) do
        {
          asset_history_limit: '',
          content_disposition: '',
          depth: '',
          distribution: '',
          force_basic_auth: '',
          http_port: '',
          https_port: '',
          index_type: '',
          index_url: '',
          is_flat: '',
          layout_policy: '',
          pgp_keypair: '',
          pgp_keypair_passphrase: '',
          proprietary_components: '',
          remote_bearer_token: '',
          remote_ntlm_domain: '',
          remote_ntlm_host: '',
          v1_enabled: '',
          version_policy: '',
          write_policy: '',
          rewrite_package_urls: '',
          cache_foreign_layers: '',
          foreign_layers_url_whitelist: [],
          remove_non_cataloged: '',
          remove_quarantined_versions: '',
          nuget_version: '',
          query_cache_item_max_age: '',
        }
      end

      let(:specific_values) do
        {}
      end

      let(:values) { common_values.merge(default_values).merge(specific_values) }

      it_behaves_like 'simple repository'

      context 'for apt' do
        let(:specific_values) do
          {
            provider_type: 'apt',
            distribution: 'dist',
            is_flat: true,
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for bower' do
        let(:specific_values) do
          {
            provider_type: 'bower',
            rewrite_package_urls: false,
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for docker' do
        let(:specific_values) do
          {
            provider_type: 'docker',
            http_port: 9990,
            https_port: 9991,
            force_basic_auth: true,
            v1_enabled: true,
            index_type: 'custom',
            index_url: 'http://localhost.foo/bar',
            cache_foreign_layers: true,
            foreign_layers_url_whitelist: %w[.*foo .*bar],
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for maven2' do
        let(:specific_values) do
          {
            provider_type: 'maven2',
            version_policy: 'mixed',
            layout_policy: 'permissive',
            content_disposition: 'attachment',
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for npm' do
        let(:specific_values) do
          {
            provider_type: 'npm',
            remove_non_cataloged: true,
            remove_quarantined_versions: true,
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for nuget' do
        let(:specific_values) do
          {
            provider_type: 'nuget',
            nuget_version: 'V2',
            query_cache_item_max_age: 6543,
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for raw' do
        let(:specific_values) do
          {
            provider_type: 'raw',
            content_disposition: 'inline',
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for yum' do
        let(:specific_values) do
          {
            provider_type: 'yum',
            pgp_keypair: 'my_signature',
            pgp_keypair_passphrase: 'my_pass',
          }
        end

        it_behaves_like 'simple repository'
      end
    end
  end

  describe 'update(context, name, should)' do
    shared_examples_for 'simple repository' do
      it 'updates the resource' do
        original_resources = provider.get(context)
        original_resource = original_resources.find { |r| r[:name] == values[:name] }

        provider.update(context, values[:name], **values)

        new_resources = provider.get(context)
        new_resource = new_resources.find { |r| r[:name] == values[:name] }
        expect(original_resource).not_to eq(new_resource)

        expect(new_resource).to eq(values.merge(ensure: 'present'))
      end
    end

    before(:each) { provider.create(context, values[:name], **create_values) }

    let(:create_values) { common_values.merge(default_values).merge(specific_values) }

    let(:values) { create_values.merge(update_values).merge(specific_update_values) }

    context 'hosted repository' do
      let(:provider_type) { 'rubygems' }

      let(:common_values) do
        {
          name: "repository_#{SecureRandom.uuid}",
          provider_type: provider_type,
          type: 'hosted',
          online: true,
          strict_content_type_validation: true,
          write_policy: 'allow_write_once',
          proprietary_components: true,
          cleanup_policies: [],
        }
      end

      let(:default_values) do
        {
          blobstore_name: 'default',
          asset_history_limit: '',
          auto_block: '',
          blocked: '',
          content_max_age: '',
          depth: '',
          distribution: '',
          force_basic_auth: '',
          http_port: '',
          https_port: '',
          index_type: '',
          index_url: '',
          is_flat: '',
          layout_policy: '',
          metadata_max_age: '',
          negative_cache_enabled: '',
          negative_cache_ttl: '',
          pgp_keypair: '',
          pgp_keypair_passphrase: '',
          remote_auth_type: 'none',
          remote_bearer_token: '',
          remote_connection_timeout: '',
          remote_enable_circular_redirects: '',
          remote_enable_cookies: '',
          remote_ntlm_domain: '',
          remote_ntlm_host: '',
          remote_password: '',
          remote_retries: '',
          remote_url: '',
          remote_user: '',
          remote_user_agent: '',
          routing_rule: '',
          v1_enabled: '',
          version_policy: '',
          content_disposition: '',
          rewrite_package_urls: '',
          cache_foreign_layers: '',
          foreign_layers_url_whitelist: [],
          remove_non_cataloged: '',
          remove_quarantined_versions: '',
          nuget_version: '',
          query_cache_item_max_age: '',
        }
      end

      let(:update_values) do
        {
          online: false,
          strict_content_type_validation: false,
          write_policy: 'read_only',
          proprietary_components: false,
        }
      end

      let(:specific_values) do
        {}
      end

      let(:specific_update_values) do
        {}
      end

      it_behaves_like 'simple repository'

      context 'for apt' do
        let(:provider_type) { 'apt' }

        let(:specific_update_values) do
          {
            asset_history_limit: 3,
            distribution: 'dist',
            pgp_keypair: 'my_signature',
            pgp_keypair_passphrase: 'my_pass',
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for docker' do
        let(:provider_type) { 'docker' }

        let(:specific_update_values) do
          {
            http_port: 9990,
            https_port: 9991,
            force_basic_auth: true,
            v1_enabled: true,
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for maven2' do
        let(:provider_type) { 'maven2' }

        let(:specific_values) do
          {
            version_policy: 'mixed',
            layout_policy: 'permissive',
            content_disposition: 'attachment',
          }
        end

        let(:specific_update_values) do
          {
            layout_policy: 'strict',
            content_disposition: 'inline',
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for raw' do
        let(:provider_type) { 'raw' }

        let(:specific_update_values) do
          {
            content_disposition: 'inline',
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for yum' do
        let(:provider_type) { 'yum' }

        let(:specific_values) do
          {
            depth: 3,
            layout_policy: 'permissive',
          }
        end

        let(:specific_update_values) do
          {
            depth: 4,
            layout_policy: 'strict',
          }
        end

        it_behaves_like 'simple repository'
      end
    end

    context 'proxy repository' do
      let(:provider_type) { 'rubygems' }

      let(:common_values) do
        {
          name: "repository_#{SecureRandom.uuid}",
          provider_type: provider_type,
          type: 'proxy',
          online: true,
          remote_url: 'http://localhost.foo/bar',
          blocked: false,
          auto_block: true,
          strict_content_type_validation: true,
          cleanup_policies: [],
          remote_auth_type: 'none',
          content_max_age: 1440,
          metadata_max_age: 1440,
          negative_cache_enabled: false,
          negative_cache_ttl: 1440,
        }
      end

      let(:default_values) do
        {
          blobstore_name: 'default',
          asset_history_limit: '',
          content_disposition: '',
          depth: '',
          distribution: '',
          force_basic_auth: '',
          http_port: '',
          https_port: '',
          index_type: '',
          index_url: '',
          is_flat: '',
          layout_policy: '',
          pgp_keypair: '',
          pgp_keypair_passphrase: '',
          proprietary_components: '',
          remote_bearer_token: '',
          remote_ntlm_domain: '',
          remote_ntlm_host: '',
          v1_enabled: '',
          version_policy: '',
          write_policy: '',
          rewrite_package_urls: '',
          cache_foreign_layers: '',
          foreign_layers_url_whitelist: [],
          remove_non_cataloged: '',
          remove_quarantined_versions: '',
          nuget_version: '',
          query_cache_item_max_age: '',
        }
      end

      let(:update_values) do
        {
          online: false,
          remote_url: 'http://localhost.foo/xyz',
          blocked: true,
          auto_block: false,
          content_max_age: 567,
          metadata_max_age: 789,
          strict_content_type_validation: false,
          routing_rule: '',
          cleanup_policies: [],
          negative_cache_enabled: true,
          negative_cache_ttl: 432,
          remote_auth_type: 'username',
          remote_user: 'user',
          remote_password: 'pass',
          remote_ntlm_domain: 'ntlm_domain',
          remote_ntlm_host: 'ntlm_host',
          remote_bearer_token: 'my-token',
          remote_user_agent: 'foo-agent',
          remote_retries: 4,
          remote_connection_timeout: 65,
          remote_enable_circular_redirects: true,
          remote_enable_cookies: true,
        }
      end

      let(:specific_values) do
        {}
      end

      let(:specific_update_values) do
        {}
      end

      it_behaves_like 'simple repository'

      context 'for apt' do
        let(:provider_type) { 'apt' }

        let(:specific_values) do
          {
            distribution: 'boo',
            is_flat: false,
          }
        end

        let(:specific_update_values) do
          {
            distribution: 'dist',
            is_flat: true,
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for bower' do
        let(:provider_type) { 'bower' }

        let(:specific_update_values) do
          {
            rewrite_package_urls: false,
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for docker' do
        let(:provider_type) { 'docker' }

        let(:specific_values) do
          {
            http_port: 9990,
            https_port: 9991,
            force_basic_auth: false,
            v1_enabled: false,
            index_type: 'registry',
            cache_foreign_layers: false,
          }
        end

        let(:specific_update_values) do
          {
            http_port: 9992,
            https_port: 9993,
            force_basic_auth: true,
            v1_enabled: true,
            index_type: 'custom',
            index_url: 'http://localhost.foo/bar',
            cache_foreign_layers: true,
            foreign_layers_url_whitelist: %w[.*foo .*bar],
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for maven2' do
        let(:provider_type) { 'maven2' }

        let(:specific_values) do
          {
            version_policy: 'snapshot',
            layout_policy: 'permissive',
            content_disposition: 'attachment',
          }
        end

        let(:specific_update_values) do
          {
            layout_policy: 'strict',
            content_disposition: 'inline',
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for npm' do
        let(:provider_type) { 'npm' }

        let(:specific_update_values) do
          {
            remove_non_cataloged: true,
            remove_quarantined_versions: true,
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for nuget' do
        let(:provider_type) { 'nuget' }

        let(:specific_values) do
          {
            nuget_version: 'V3',
            query_cache_item_max_age: 987,
          }
        end

        let(:specific_update_values) do
          {
            nuget_version: 'V2',
            query_cache_item_max_age: 654,
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for raw' do
        let(:provider_type) { 'raw' }

        let(:specific_update_values) do
          {
            content_disposition: 'inline',
          }
        end

        it_behaves_like 'simple repository'
      end

      context 'for yum' do
        let(:provider_type) { 'yum' }

        let(:specific_update_values) do
          {
            pgp_keypair: 'my_signature',
            pgp_keypair_passphrase: 'my_pass',
          }
        end

        it_behaves_like 'simple repository'
      end
    end
  end

  # TODO: add test to remove when it is listed in a group
  # TODO: add new attributes on README (Try to generate tables dynamically with PDK)
  describe 'delete(context, name)' do
    let(:name) { "repository_#{SecureRandom.uuid}" }

    before(:each) { provider.create(context, name, name: name, **minimum_required_values) }

    it 'deletes the resource' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^repository_}) }
      expect(resources.size).to eq(2)

      provider.delete(context, name)

      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^repository_}) }
      expect(resources.size).to eq(1)
    end
  end
end
