# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::Nexus3RoutingRule')
require 'puppet/provider/nexus3_routing_rule/nexus3_routing_rule'

RSpec.describe Puppet::Provider::Nexus3RoutingRule::Nexus3RoutingRule do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  before(:each) do
    stub_config
    provider.get(context).each do |resource|
      provider.delete(context, resource[:name]) if resource[:name].match?(%r{^routing_rule_})
    end

    name = "routing_rule_#{SecureRandom.uuid}"
    provider.create(context, name, name: name, mode: 'BLOCK', matchers: ['foo'])
  end

  describe '#get' do
    it 'processes resources' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^routing_rule_}) }
      expect(resources.size).to eq(1)
      expect(resources[0].keys.sort).to eq(%i[matchers description mode name ensure].sort)
    end
  end

  describe 'create(context, name, should)' do
    let(:values) do
      {
        name: "routing_rule_#{SecureRandom.uuid}",
        mode: 'ALLOW',
        matchers: %w[foo bar],
        description: 'some routing'
      }
    end

    it 'creates the resource' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^routing_rule_}) }
      expect(resources.size).to eq(1)

      provider.create(context, values[:name], **values)

      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^routing_rule_}) }
      expect(resources.size).to eq(2)

      expect(resources.find { |r| r[:name] == values[:name] }).to eq(values.merge(ensure: 'present'))
    end
  end

  describe 'update(context, name, should)' do
    before(:each) { provider.create(context, values[:name], **default_values) }

    let(:default_values) { Puppet::Type.type(:nexus3_routing_rule).new(name: values[:name], matchers: ['foo']).to_hash }

    let(:values) do
      {
        name: "routing_rule_#{SecureRandom.uuid}",
        mode: 'ALLOW',
        matchers: %w[foo bar],
        description: 'some routing'
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
    let(:name) { "routing_rule_#{SecureRandom.uuid}" }

    before(:each) { provider.create(context, name, name: name, mode: 'ALLOW', matchers: ['foo']) }

    it 'deletes the resource' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^routing_rule_}) }
      expect(resources.size).to eq(2)

      provider.delete(context, name)

      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^routing_rule_}) }
      expect(resources.size).to eq(1)
    end
  end
end
