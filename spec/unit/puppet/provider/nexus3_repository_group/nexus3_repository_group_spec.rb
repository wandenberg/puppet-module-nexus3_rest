# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::Nexus3RepositoryGroup')
require 'puppet/provider/nexus3_repository_group/nexus3_repository_group'

RSpec.describe Puppet::Provider::Nexus3RepositoryGroup::Nexus3RepositoryGroup do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  let(:minimum_required_values) do
    {
      provider_type: 'rubygems',
      online: true,
      blobstore_name: 'default',
      strict_content_type_validation: true,
      repositories: [],
    }
  end

  before(:each) do
    stub_config
    provider.get(context).each do |resource|
      provider.delete(context, resource[:name]) if resource[:name].match?(%r{^repository_group_})
    end

    name = "repository_group_#{SecureRandom.uuid}"
    provider.create(context, name, name: name, **minimum_required_values)
  end

  describe '#get' do
    it 'processes resources' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^repository_group_}) }
      expect(resources.size).to eq(1)
      expect(resources[0].keys.sort).to eq(%i[blobstore_name content_disposition force_basic_auth http_port https_port online provider_type repositories strict_content_type_validation v1_enabled
                                              layout_policy version_policy pgp_keypair pgp_keypair_passphrase name ensure].sort)
    end
  end

  describe 'set(context, changes)' do
    it 'prevent changing the provider_type of the repository' do
      changes = {
        foo:  {
          is: { name: 'temporary', provider_type: 'rubygems', blobstore_name: 'default', ensure: 'present' },
          should: { name: 'temporary', provider_type: 'npm', blobstore_name: 'default', ensure: 'present' }
        }
      }
      expect { provider.set(context, changes) }.to raise_error(ArgumentError, %r{provider_type cannot be changed})
    end

    it 'prevent changing the version_policy of the repository' do
      changes = {
        foo:  {
          is: { name: 'temporary', provider_type: 'maven2', blobstore_name: 'default', version_policy: 'release', ensure: 'present' },
          should: { name: 'temporary', provider_type: 'maven2', blobstore_name: 'default', version_policy: 'mixed', ensure: 'present' }
        }
      }
      expect { provider.set(context, changes) }.to raise_error(ArgumentError, %r{version_policy cannot be changed})
    end

    it 'prevent changing the blobstore_name of the repository' do
      changes = {
        foo:  {
          is: { name: 'temporary', provider_type: 'rubygems', blobstore_name: 'default', ensure: 'present' },
          should: { name: 'temporary', provider_type: 'rubygems', blobstore_name: 'foo', ensure: 'present' }
        }
      }
      expect { provider.set(context, changes) }.to raise_error(ArgumentError, %r{blobstore_name cannot be changed})
    end

    it 'does not prevent changing other values' do
      changes = {
        foo:  {
          is: { name: 'temporary', provider_type: 'rubygems', blobstore_name: 'default', content_disposition: 'inline', ensure: 'present' },
          should: { name: 'temporary', provider_type: 'rubygems', blobstore_name: 'default', content_disposition: 'attachment', ensure: 'present' }
        }
      }
      expect { provider.set(context, changes) }.to raise_error(RSpec::Mocks::MockExpectationError) # mock expectation error indicates that the code went through the validation
    end

    it 'does not check changing the provider_type and blobstore_name when creating the repository' do
      changes = {
        foo:  {
          is: { name: 'temporary', ensure: 'absent' },
          should: { name: 'temporary', provider_type: 'rubygems', blobstore_name: 'default', ensure: 'present' }
        }
      }
      expect { provider.set(context, changes) }.to raise_error(RSpec::Mocks::MockExpectationError) # mock expectation error indicates that the code went through the validation
    end

    it 'does not check changing the provider_type and blobstore_name when removing the repository' do
      changes = {
        foo:  {
          is: { name: 'temporary', provider_type: 'rubygems', blobstore_name: 'default', ensure: 'present' },
          should: { name: 'temporary', ensure: 'absent' }
        }
      }
      expect { provider.set(context, changes) }.to raise_error(RSpec::Mocks::MockExpectationError) # mock expectation error indicates that the code went through the validation
    end
  end

  describe 'create(context, name, should)' do
    shared_examples_for 'simple repository' do
      it 'creates the resource' do
        resources = provider.get(context).filter { |resource| resource[:name].match(%r{^repository_group_}) }
        expect(resources.size).to eq(1)

        provider.create(context, values[:name], **values)

        resources = provider.get(context).filter { |resource| resource[:name].match(%r{^repository_group_}) }
        expect(resources.size).to eq(2)

        resource = resources.find { |r| r[:name] == values[:name] }
        expect(resource).to eq(values.merge(ensure: 'present'))
      end
    end

    let(:common_values) do
      {
        name: "repository_group_#{SecureRandom.uuid}",
        provider_type: 'rubygems',
        online: true,
        blobstore_name: 'default',
        strict_content_type_validation: true,
        repositories: [],
      }
    end

    let(:default_values) do
      {
        content_disposition: '',
        force_basic_auth: '',
        http_port: '',
        https_port: '',
        layout_policy: '',
        v1_enabled: '',
        version_policy: '',
        pgp_keypair: '',
        pgp_keypair_passphrase: '',
      }
    end

    let(:specific_values) do
      {}
    end

    let(:values) { common_values.merge(default_values).merge(specific_values) }

    it_behaves_like 'simple repository'

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
          pgp_keypair: 'my_signature',
          pgp_keypair_passphrase: 'my_pass',
        }
      end

      it_behaves_like 'simple repository'
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

    let(:provider_type) { 'rubygems' }

    let(:common_values) do
      {
        name: "repository_group_#{SecureRandom.uuid}",
        provider_type: provider_type,
        online: true,
        strict_content_type_validation: true,
        repositories: [],
      }
    end

    let(:default_values) do
      {
        blobstore_name: 'default',
        content_disposition: '',
        force_basic_auth: '',
        http_port: '',
        https_port: '',
        layout_policy: '',
        v1_enabled: '',
        version_policy: '',
        pgp_keypair: '',
        pgp_keypair_passphrase: '',
      }
    end

    let(:update_values) do
      {
        online: false,
        strict_content_type_validation: false,
      }
    end

    let(:specific_values) do
      {}
    end

    let(:specific_update_values) do
      {}
    end

    it_behaves_like 'simple repository'

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

      let(:specific_update_values) do
        {
          pgp_keypair: 'my_signature',
          pgp_keypair_passphrase: 'my_pass',
        }
      end

      it_behaves_like 'simple repository'
    end
  end

  describe 'delete(context, name)' do
    let(:name) { "repository_group_#{SecureRandom.uuid}" }

    before(:each) { provider.create(context, name, name: name, **minimum_required_values) }

    it 'deletes the resource' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^repository_group_}) }
      expect(resources.size).to eq(2)

      provider.delete(context, name)

      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^repository_group_}) }
      expect(resources.size).to eq(1)
    end
  end
end
