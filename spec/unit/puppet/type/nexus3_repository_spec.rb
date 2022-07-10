# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:nexus3_repository) do
  let(:required_values) do
    {
      name: 'default',
      provider_type: 'docker',
      type: 'proxy'
    }
  end

  describe 'for hosted' do
    %w[apt bower docker gitlfs helm maven2 npm nuget pypi r raw rubygems yum].each do |provider_type|
      describe "provider_type '#{provider_type}' repository default values" do
        let(:instance) { described_class.new(name: 'default', type: 'hosted', provider_type: provider_type) }

        it 'has true for online property' do
          expect(instance[:online]).to eq(:true)
        end

        it 'has default for blobstore_name property' do
          expect(instance[:blobstore_name]).to eq('default')
        end

        it 'has empty array for cleanup_policies property' do
          expect(instance[:cleanup_policies]).to eq []
        end

        it 'has none for remote_auth_type property' do
          expect(instance[:remote_auth_type]).to eq('none')
        end

        it 'has empty array for foreign_layers_url_whitelist property' do
          expect(instance[:foreign_layers_url_whitelist]).to eq []
        end

        it 'has false for proprietary_components property' do
          expect(instance[:proprietary_components]).to eq :false
        end

        %w[asset_history_limit auto_block blocked cache_foreign_layers content_max_age distribution http_port https_port index_type index_url is_flat metadata_max_age negative_cache_enabled
           negative_cache_ttl nuget_version pgp_keypair pgp_keypair_passphrase query_cache_item_max_age remote_bearer_token remote_ntlm_domain remote_ntlm_host remote_password remote_url remote_user
           remove_non_cataloged remove_quarantined_versions rewrite_package_urls routing_rule remote_user_agent remote_retries remote_connection_timeout remote_enable_circular_redirects
           remote_enable_cookies].each do |property|
          it "has empty string for #{property} property" do
            expect(instance[property.to_sym]).to eq ''
          end
        end

        if %w[docker r raw].include?(provider_type)
          it 'has allow_write for write_policy property' do
            expect(instance[:write_policy]).to eq('allow_write')
          end
        else
          it 'has allow_write_once for write_policy property' do
            expect(instance[:write_policy]).to eq('allow_write_once')
          end
        end

        if %w[raw].include?(provider_type)
          it 'has false for strict_content_type_validation property' do
            expect(instance[:strict_content_type_validation]).to eq(:false)
          end
        else
          it 'has true for strict_content_type_validation property' do
            expect(instance[:strict_content_type_validation]).to eq(:true)
          end
        end

        if %w[raw].include?(provider_type)
          it 'has attachment for content_disposition property' do
            expect(instance[:content_disposition]).to eq('attachment')
          end
        elsif %w[maven2].include?(provider_type)
          it 'has inline for content_disposition property' do
            expect(instance[:content_disposition]).to eq('inline')
          end
        else
          it 'has empty string for content_disposition property' do
            expect(instance[:content_disposition]).to eq('')
          end
        end

        if %w[maven2 yum].include?(provider_type)
          it 'has strict for layout_policy property' do
            expect(instance[:layout_policy]).to eq('strict')
          end
        else
          it 'has empty string for layout_policy property' do
            expect(instance[:layout_policy]).to eq('')
          end
        end

        if %w[maven2].include?(provider_type)
          it 'has release for version_policy property' do
            expect(instance[:version_policy]).to eq('release')
          end
        else
          it 'has empty string for version_policy property' do
            expect(instance[:version_policy]).to eq('')
          end
        end

        if %w[docker].include?(provider_type)
          it 'has false for force_basic_auth property' do
            expect(instance[:force_basic_auth]).to eq(:false)
          end

          it 'has false for v1_enabled property' do
            expect(instance[:v1_enabled]).to eq(:false)
          end
        else
          it 'has empty string for force_basic_auth property' do
            expect(instance[:force_basic_auth]).to eq('')
          end

          it 'has empty string for v1_enabled property' do
            expect(instance[:v1_enabled]).to eq('')
          end
        end

        if %w[yum].include?(provider_type)
          it 'has 0 for depth property' do
            expect(instance[:depth]).to eq(0)
          end
        else
          it 'has empty string for depth property' do
            expect(instance[:depth]).to eq('')
          end
        end
      end
    end
  end

  describe 'for proxy' do
    %w[apt bower cocoapods conan conda docker go helm maven2 npm nuget p2 pypi r raw rubygems yum].each do |provider_type|
      describe "provider_type '#{provider_type}' repository default values" do
        let(:instance) { described_class.new(name: 'default', type: 'proxy', provider_type: provider_type) }

        it 'has true for online property' do
          expect(instance[:online]).to eq(:true)
        end

        it 'has false for blocked property' do
          expect(instance[:blocked]).to eq(:false)
        end

        it 'has default for blobstore_name property' do
          expect(instance[:blobstore_name]).to eq('default')
        end

        it 'has empty array for cleanup_policies property' do
          expect(instance[:cleanup_policies]).to eq []
        end

        it 'has 1440 for metadata_max_age property' do
          expect(instance[:metadata_max_age]).to eq(1440)
        end

        it 'has none for remote_auth_type property' do
          expect(instance[:remote_auth_type]).to eq('none')
        end

        it 'has true for strict_content_type_validation property' do
          expect(instance[:strict_content_type_validation]).to eq(:true)
        end

        it 'has true for negative_cache_enabled property' do
          expect(instance[:negative_cache_enabled]).to eq(:true)
        end

        it 'has false for remote_enable_circular_redirects property' do
          expect(instance[:remote_enable_circular_redirects]).to eq(:false)
        end

        it 'has false for remote_enable_cookies property' do
          expect(instance[:remote_enable_cookies]).to eq(:false)
        end

        it 'has 1440 for negative_cache_ttl property' do
          expect(instance[:negative_cache_ttl]).to eq(1440)
        end

        %w[asset_history_limit depth distribution http_port https_port index_url pgp_keypair pgp_keypair_passphrase proprietary_components remote_bearer_token remote_ntlm_domain remote_ntlm_host
           remote_password remote_url remote_user routing_rule write_policy remote_user_agent remote_retries remote_connection_timeout].each do |property|
          it "has empty string for #{property} property" do
            expect(instance[property.to_sym]).to eq ''
          end
        end

        if %w[p2].include?(provider_type)
          it 'has false for auto_block property' do
            expect(instance[:auto_block]).to eq(:false)
          end
        else
          it 'has true for auto_block property' do
            expect(instance[:auto_block]).to eq(:true)
          end
        end

        if %w[apt].include?(provider_type)
          it 'has false for is_flat property' do
            expect(instance[:is_flat]).to eq(:false)
          end
        else
          it 'has empty string for is_flat property' do
            expect(instance[:is_flat]).to eq('')
          end
        end

        if %w[bower].include?(provider_type)
          it 'has true for rewrite_package_urls property' do
            expect(instance[:rewrite_package_urls]).to eq(:true)
          end
        else
          it 'has empty string for rewrite_package_urls property' do
            expect(instance[:rewrite_package_urls]).to eq('')
          end
        end

        if %w[maven2].include?(provider_type)
          it 'has strict for layout_policy property' do
            expect(instance[:layout_policy]).to eq('strict')
          end

          it 'has release for version_policy property' do
            expect(instance[:version_policy]).to eq('release')
          end

          it 'has -1 for content_max_age property for release version_policy' do
            expect(described_class.new(name: 'default', type: 'proxy', provider_type: provider_type, version_policy: 'release')[:content_max_age]).to eq(-1)
          end

          it 'has 1440 for content_max_age property for non-release version_policy' do
            expect(described_class.new(name: 'default', type: 'proxy', provider_type: provider_type, version_policy: 'snapshot')[:content_max_age]).to eq(1440)
          end
        else
          it 'has empty string for layout_policy property' do
            expect(instance[:layout_policy]).to eq('')
          end

          it 'has empty string for version_policy property' do
            expect(instance[:version_policy]).to eq('')
          end

          it 'has 1440 for content_max_age property' do
            expect(instance[:content_max_age]).to eq(1440)
          end
        end

        if %w[raw].include?(provider_type)
          it 'has attachment for content_disposition property' do
            expect(instance[:content_disposition]).to eq('attachment')
          end
        elsif %w[maven2].include?(provider_type)
          it 'has inline for content_disposition property' do
            expect(instance[:content_disposition]).to eq('inline')
          end
        else
          it 'has empty string for content_disposition property' do
            expect(instance[:content_disposition]).to eq('')
          end
        end

        if %w[docker].include?(provider_type)
          it 'has false for force_basic_auth property' do
            expect(instance[:force_basic_auth]).to eq(:false)
          end

          it 'has false for v1_enabled property' do
            expect(instance[:v1_enabled]).to eq(:false)
          end

          it 'has registry for index_type property' do
            expect(instance[:index_type]).to eq('registry')
          end

          it 'has false for cache_foreign_layers property' do
            expect(instance[:cache_foreign_layers]).to eq(:false)
          end

          it 'has empty array for foreign_layers_url_whitelist property for false cache_foreign_layers' do
            expect(described_class.new(name: 'default', type: 'proxy', provider_type: provider_type, cache_foreign_layers: false)[:foreign_layers_url_whitelist]).to eq([])
          end

          it 'has wildcard for any url for foreign_layers_url_whitelist property for true cache_foreign_layers' do
            expect(described_class.new(name: 'default', type: 'proxy', provider_type: provider_type, cache_foreign_layers: true)[:foreign_layers_url_whitelist]).to eq(['.*'])
          end
        else
          it 'has empty string for force_basic_auth property' do
            expect(instance[:force_basic_auth]).to eq('')
          end

          it 'has empty string for v1_enabled property' do
            expect(instance[:v1_enabled]).to eq('')
          end

          it 'has empty string for index_type property' do
            expect(instance[:index_type]).to eq('')
          end

          it 'has empty string for cache_foreign_layers property' do
            expect(instance[:cache_foreign_layers]).to eq('')
          end

          it 'has empty array for foreign_layers_url_whitelist property' do
            expect(instance[:foreign_layers_url_whitelist]).to eq []
          end
        end

        if %w[npm].include?(provider_type)
          it 'has false for remove_non_cataloged property' do
            expect(instance[:remove_non_cataloged]).to eq(:false)
          end

          it 'has false for remove_quarantined_versions property' do
            expect(instance[:remove_quarantined_versions]).to eq(:false)
          end
        else
          it 'has empty string for remove_non_cataloged property' do
            expect(instance[:remove_non_cataloged]).to eq('')
          end

          it 'has empty string for remove_quarantined_versions property' do
            expect(instance[:remove_quarantined_versions]).to eq('')
          end
        end

        if %w[nuget].include?(provider_type)
          it 'has V3 for nuget_version property' do
            expect(instance[:nuget_version]).to eq('V3')
          end

          it 'has 3600 for query_cache_item_max_age property' do
            expect(instance[:query_cache_item_max_age]).to eq(3600)
          end
        else
          it 'has empty string for nuget_version property' do
            expect(instance[:nuget_version]).to eq('')
          end

          it 'has empty string for query_cache_item_max_age property' do
            expect(instance[:query_cache_item_max_age]).to eq('')
          end
        end
      end
    end
  end

  it 'validate type' do
    expect {
      described_class.new(required_values.merge(type: 'invalid'))
    }.to raise_error(Puppet::ResourceError, %r{Parameter type failed})
  end

  it 'validate provider_type' do
    expect {
      described_class.new(required_values.merge(provider_type: 'invalid'))
    }.to raise_error(ArgumentError, %r{'invalid' not supported for proxy type})
  end

  it 'validate version_policy' do
    expect {
      described_class.new(required_values.merge(version_policy: 'invalid'))
    }.to raise_error(Puppet::ResourceError, %r{Parameter version_policy failed})
  end

  it 'validate layout_policy' do
    expect {
      described_class.new(required_values.merge(layout_policy: 'invalid'))
    }.to raise_error(Puppet::ResourceError, %r{Parameter layout_policy failed})
  end

  it 'validate write_policy' do
    expect {
      described_class.new(required_values.merge(write_policy: 'invalid'))
    }.to raise_error(Puppet::ResourceError, %r{Parameter write_policy failed})
  end

  it 'validate remote_auth_type' do
    expect {
      described_class.new(required_values.merge(remote_auth_type: 'invalid'))
    }.to raise_error(Puppet::ResourceError, %r{Parameter remote_auth_type failed})
  end

  describe 'online' do
    specify 'should default to true' do
      expect(described_class.new(required_values)[:online]).to be :true
    end

    specify 'should accept :true' do
      expect { described_class.new(required_values.merge(online: :true)) }.not_to raise_error
      expect(described_class.new(required_values.merge(online: :true))[:online]).to be :true
    end

    specify 'should accept "true"' do
      expect { described_class.new(required_values.merge(online: 'true')) }.not_to raise_error
      expect(described_class.new(required_values.merge(online: 'true'))[:online]).to be :true
    end

    specify 'should accept :false' do
      expect { described_class.new(required_values.merge(online: :false)) }.not_to raise_error
      expect(described_class.new(required_values.merge(online: :false))[:online]).to be :false
    end

    specify 'should accept "false"' do
      expect { described_class.new(required_values.merge(online: 'false')) }.not_to raise_error
      expect(described_class.new(required_values.merge(online: 'false'))[:online]).to be :false
    end
  end

  describe 'blocked' do
    specify 'should default to false' do
      expect(described_class.new(required_values)[:blocked]).to be :false
    end

    specify 'should accept :true' do
      expect { described_class.new(required_values.merge(blocked: :true)) }.not_to raise_error
      expect(described_class.new(required_values.merge(blocked: :true))[:blocked]).to be :true
    end

    specify 'should accept "true"' do
      expect { described_class.new(required_values.merge(blocked: 'true')) }.not_to raise_error
      expect(described_class.new(required_values.merge(blocked: 'true'))[:blocked]).to be :true
    end

    specify 'should accept :false' do
      expect { described_class.new(required_values.merge(blocked: :false)) }.not_to raise_error
      expect(described_class.new(required_values.merge(blocked: :false))[:blocked]).to be :false
    end

    specify 'should accept "false"' do
      expect { described_class.new(required_values.merge(blocked: 'false')) }.not_to raise_error
      expect(described_class.new(required_values.merge(blocked: 'false'))[:blocked]).to be :false
    end
  end

  describe 'strict_content_type_validation' do
    specify 'should default to false' do
      expect(described_class.new(required_values)[:strict_content_type_validation]).to be :true
    end

    specify 'should accept :true' do
      expect { described_class.new(required_values.merge(strict_content_type_validation: :true)) }.not_to raise_error
      expect(described_class.new(required_values.merge(strict_content_type_validation: :true))[:strict_content_type_validation]).to be :true
    end

    specify 'should accept "true' do
      expect { described_class.new(required_values.merge(strict_content_type_validation: 'true')) }.not_to raise_error
      expect(described_class.new(required_values.merge(strict_content_type_validation: 'true'))[:strict_content_type_validation]).to be :true
    end

    specify 'should accept :false' do
      expect { described_class.new(required_values.merge(strict_content_type_validation: :false)) }.not_to raise_error
      expect(described_class.new(required_values.merge(strict_content_type_validation: :false))[:strict_content_type_validation]).to be :false
    end

    specify 'should accept "false"' do
      expect { described_class.new(required_values.merge(strict_content_type_validation: 'false')) }.not_to raise_error
      expect(described_class.new(required_values.merge(strict_content_type_validation: 'false'))[:strict_content_type_validation]).to be :false
    end
  end

  describe 'provider_type' do
    specify 'should accept a valid provider_type' do
      expect { described_class.new(required_values.merge(provider_type: 'docker')) }.not_to raise_error
    end

    specify 'should not have default value for provider_type' do
      expect {
        required_values.delete(:provider_type)
        described_class.new(required_values)
      }.to raise_error(ArgumentError, %r{provider_type must not be empty})
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(required_values.merge(provider_type: ''))
      }.to raise_error(ArgumentError, %r{provider_type must not be empty})
    end
  end

  describe 'cleanup_policies' do
    specify 'should accept a valid array of cleanup_policies' do
      expect { described_class.new(required_values.merge(cleanup_policies: %w[policy-1 policy-2])) }.not_to raise_error
    end

    specify 'should replace empty string with an empty array' do
      expect(described_class.new(required_values.merge(cleanup_policies: ''))[:cleanup_policies]).to eq([])
    end

    specify 'should not accept a string as array' do
      expect {
        described_class.new(required_values.merge(cleanup_policies: 'name1,name2'))
      }.to raise_error(ArgumentError, %r{cleanup_policies must be an array of strings})
    end
  end

  describe 'when removing' do
    it { expect { described_class.new(name: 'any', ensure: :absent) }.not_to raise_error }
  end
end
