# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::Nexus3RealmSettings')
require 'puppet/provider/nexus3_realm_settings/nexus3_realm_settings'

RSpec.describe Puppet::Provider::Nexus3RealmSettings::Nexus3RealmSettings do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  before(:each) { stub_config }

  describe '#get' do
    it 'processes resources' do
      resources = provider.get(context)
      expect(resources.size).to eq(1)
      expect(resources[0].keys.sort).to eq(%i[names name ensure].sort)
    end
  end

  describe 'create(context, name, should)' do
    it 'creates the resource' do
      expect(context).to receive(:notice).with('Not possible to create new Realm settings')

      provider.create(context, 'a', name: 'a', ensure: 'present')
    end
  end

  describe 'update(context, name, should)' do
    let(:values) do
      {
        names: %w[NexusAuthenticatingRealm LdapRealm DockerToken],
      }
    end

    let(:default_values) { Puppet::Type.type(:nexus3_realm_settings).new({}).to_hash }

    it 'updates the resource' do
      # reset to default
      provider.update(context, 'global', **default_values)

      original_resources = provider.get(context)

      provider.update(context, 'global', name: 'global', ensure: 'present', **values)

      new_resources = provider.get(context)
      expect(original_resources[0]).not_to eq(new_resources[0])

      expect(new_resources[0]).to eq(values.merge(name: 'global', ensure: 'present'))

      # reset to default
      provider.update(context, 'global', name: 'global', **default_values)
    end
  end

  describe 'delete(context, name)' do
    it 'deletes the resource' do
      expect(context).to receive(:notice).with('Not possible to remove Realm settings')

      provider.delete(context, 'foo')
    end
  end
end
