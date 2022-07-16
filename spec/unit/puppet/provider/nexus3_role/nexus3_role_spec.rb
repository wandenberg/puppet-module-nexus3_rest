# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::Nexus3Role')
require 'puppet/provider/nexus3_role/nexus3_role'

RSpec.describe Puppet::Provider::Nexus3Role::Nexus3Role do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  let(:minimum_required_values) do
    {
      roles: [],
      privileges: [],
    }
  end

  before(:each) do
    stub_config
    provider.get(context).each do |resource|
      provider.delete(context, resource[:name]) if resource[:name].match?(%r{^role_})
    end

    name = "role_#{SecureRandom.uuid}"
    provider.create(context, name, name: name, **minimum_required_values)
  end

  describe '#get' do
    it 'processes resources' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^role_}) }
      expect(resources.size).to eq(1)
      expect(resources[0].keys.sort).to eq(%i[description roles privileges read_only source name ensure].sort)
    end
  end

  describe 'create(context, name, should)' do
    let(:values) do
      {
        name: "role_#{SecureRandom.uuid}",
        description: 'role description',
        source: 'source',
        read_only: true,
        roles: ['nx-anonymous'],
        privileges: %w[nx-blobstores-create nx-capabilities-read],
      }
    end

    it 'creates the resource' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^role_}) }
      expect(resources.size).to eq(1)

      provider.create(context, values[:name], **values)

      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^role_}) }
      expect(resources.size).to eq(2)

      resource = resources.find { |r| r[:name] == values[:name] }
      expect(resource).to eq(values.merge(ensure: 'present', source: 'default', read_only: false))
    end
  end

  describe 'update(context, name, should)' do
    before(:each) { provider.create(context, values[:name], **create_values) }

    let(:create_values) do
      {
        name: "role_#{SecureRandom.uuid}",
        description: 'role description',
        roles: ['nx-anonymous'],
        privileges: %w[nx-blobstores-create nx-capabilities-read],
      }
    end

    let(:values) do
      {
        name: create_values[:name],
        description: 'new role description',
        roles: ['nx-admin'],
        privileges: %w[nx-blobstores-delete nx-capabilities-create],
        read_only: false,
        source: 'default',
      }
    end

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

  describe 'delete(context, name)' do
    let(:name) { "role_#{SecureRandom.uuid}" }

    before(:each) { provider.create(context, name, name: name, **minimum_required_values) }

    it 'deletes the resource' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^role_}) }
      expect(resources.size).to eq(2)

      provider.delete(context, name)

      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^role_}) }
      expect(resources.size).to eq(1)
    end
  end
end
