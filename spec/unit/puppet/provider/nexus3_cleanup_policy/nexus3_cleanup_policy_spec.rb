# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::Nexus3CleanupPolicy')
require 'puppet/provider/nexus3_cleanup_policy/nexus3_cleanup_policy'

RSpec.describe Puppet::Provider::Nexus3CleanupPolicy::Nexus3CleanupPolicy do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  before(:each) do
    stub_config
    provider.get(context).each do |resource|
      provider.delete(context, resource[:name]) if resource[:name].match?(%r{^cleanup_policy_})
    end

    name = "cleanup_policy_#{SecureRandom.uuid}"
    provider.create(context, name, name: name)
  end

  describe '#get' do
    it 'processes resources' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^cleanup_policy_}) }
      expect(resources.size).to eq(1)
      expect(resources[0].keys.sort).to eq(%i[format is_prerelease last_blob_updated last_downloaded notes regex name ensure].sort)
    end
  end

  describe 'create(context, name, should)' do
    let(:values) do
      {
        name: "cleanup_policy_#{SecureRandom.uuid}",
        format: 'maven2',
        is_prerelease: true,
        last_blob_updated: 2,
        last_downloaded: 3,
        notes: 'my_notes',
        regex: 'some_expression'
      }
    end

    it 'creates the resource' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^cleanup_policy_}) }
      expect(resources.size).to eq(1)

      provider.create(context, values[:name], **values)

      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^cleanup_policy_}) }
      expect(resources.size).to eq(2)

      expect(resources.find { |r| r[:name] == values[:name] }).to eq(values.merge(ensure: 'present'))
    end
  end

  describe 'update(context, name, should)' do
    before(:each) { provider.create(context, values[:name], **default_values) }

    let(:default_values) { Puppet::Type.type(:nexus3_cleanup_policy).new(name: values[:name], format: 'maven2').to_hash }

    let(:values) do
      {
        name: "cleanup_policy_#{SecureRandom.uuid}",
        format: 'all',
        last_blob_updated: 2,
        last_downloaded: 3,
        notes: 'my_notes',
      }
    end

    it 'updates the resource' do
      original_resources = provider.get(context)
      original_resource = original_resources.find { |r| r[:name] == values[:name] }

      provider.update(context, values[:name], **values)

      new_resources = provider.get(context)
      new_resource = new_resources.find { |r| r[:name] == values[:name] }
      expect(original_resource).not_to eq(new_resource)

      expect(new_resource).to eq(values.merge(ensure: 'present', is_prerelease: '', regex: ''))
    end
  end

  describe 'delete(context, name)' do
    let(:name) { "cleanup_policy_#{SecureRandom.uuid}" }

    before(:each) { provider.create(context, name, name: name) }

    it 'deletes the resource' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^cleanup_policy_}) }
      expect(resources.size).to eq(2)

      provider.delete(context, name)

      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^cleanup_policy_}) }
      expect(resources.size).to eq(1)
    end
  end
end
