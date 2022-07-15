# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::Nexus3Privilege')
require 'puppet/provider/nexus3_privilege/nexus3_privilege'

RSpec.describe Puppet::Provider::Nexus3Privilege::Nexus3Privilege do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  let(:minimum_required_values) do
    {
      type: 'wildcard',
      pattern: '.*',
    }
  end

  before(:each) do
    stub_config
    provider.get(context).each do |resource|
      provider.delete(context, resource[:name]) if resource[:name].match?(%r{^privilege_})
    end

    name = "privilege_#{SecureRandom.uuid}"
    provider.create(context, name, name: name, **minimum_required_values)
  end

  describe '#get' do
    it 'processes resources' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^privilege_}) }
      expect(resources.size).to eq(1)
      expect(resources[0].keys.sort).to eq(%i[description actions format domain repository_name script_name type content_selector pattern name ensure].sort)
    end
  end

  describe 'set(context, changes)' do
    it 'prevent changing the type of the privilege' do
      changes = {
        foo:  {
          is: { name: 'temporary', type: 'wildcard', ensure: 'present' },
          should: { name: 'temporary', type: 'application', ensure: 'present' }
        }
      }
      expect { provider.set(context, changes) }.to raise_error(ArgumentError, %r{type cannot be changed})
    end
  end

  describe 'create(context, name, should)' do
    shared_examples_for 'simple privilege' do
      it 'creates the resource' do
        resources = provider.get(context).filter { |resource| resource[:name].match(%r{^privilege_}) }
        expect(resources.size).to eq(1)

        provider.create(context, values[:name], **values)

        resources = provider.get(context).filter { |resource| resource[:name].match(%r{^privilege_}) }
        expect(resources.size).to eq(2)

        resource = resources.find { |r| r[:name] == values[:name] }
        expect(resource).to eq(values.merge(ensure: 'present'))
      end
    end

    let(:common_values) do
      {
        name: "privilege_#{SecureRandom.uuid}",
        description: 'my privilege description',
      }
    end

    let(:default_values) do
      {
        actions: '',
        content_selector: '',
        description: '',
        domain: '',
        format: '',
        pattern: '',
        repository_name: '',
        script_name: '',
      }
    end

    let(:values) { common_values.merge(default_values).merge(specific_values) }

    describe 'for application' do
      let(:specific_values) do
        {
          type: 'application',
          actions: 'a,b',
          domain: 'foo.com',
        }
      end

      it_behaves_like 'simple privilege'
    end

    describe 'for repository-admin' do
      let(:specific_values) do
        {
          type: 'repository-admin',
          actions: 'a,b',
          format: '*.p',
          repository_name: 'my_repo',
        }
      end

      it_behaves_like 'simple privilege'
    end

    describe 'for repository-view' do
      let(:specific_values) do
        {
          type: 'repository-view',
          actions: 'a,b',
          format: '*.p',
          repository_name: 'my_repo',
        }
      end

      it_behaves_like 'simple privilege'
    end

    describe 'for repository-content-selector' do
      let(:specific_values) do
        {
          type: 'repository-content-selector',
          actions: 'a,b',
          content_selector: '*.p',
          repository_name: 'my_repo',
        }
      end

      it_behaves_like 'simple privilege'
    end

    describe 'for script' do
      let(:specific_values) do
        {
          type: 'script',
          actions: 'a,b',
          script_name: 'my_script',
        }
      end

      it_behaves_like 'simple privilege'
    end

    describe 'for wildcard' do
      let(:specific_values) do
        {
          type: 'wildcard',
          actions: 'a,b',
          pattern: '*.p',
        }
      end

      it_behaves_like 'simple privilege'
    end
  end

  describe 'update(context, name, should)' do
    shared_examples_for 'simple privilege' do
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

    let(:common_values) do
      {
        name: "privilege_#{SecureRandom.uuid}",
        description: 'my privilege description',
      }
    end

    let(:default_values) do
      {
        actions: '',
        content_selector: '',
        description: '',
        domain: '',
        format: '',
        pattern: '',
        repository_name: '',
        script_name: '',
      }
    end

    let(:update_values) do
      {
        description: 'new privilege description',
      }
    end

    let(:specific_values) do
      {}
    end

    let(:specific_update_values) do
      {}
    end

    describe 'for application' do
      let(:specific_values) do
        {
          type: 'application',
          actions: 'a,b',
          domain: 'foo.com',
        }
      end

      let(:specific_update_values) do
        {
          actions: 'c,d',
          domain: 'bar.com',
        }
      end

      it_behaves_like 'simple privilege'
    end

    describe 'for repository-admin' do
      let(:specific_values) do
        {
          type: 'repository-admin',
          actions: 'a,b',
          format: '*.p',
          repository_name: 'my_repo',
        }
      end

      let(:specific_update_values) do
        {
          actions: 'c,d',
          format: '*.p1',
          repository_name: 'my_repo1',
        }
      end

      it_behaves_like 'simple privilege'
    end

    describe 'for repository-view' do
      let(:specific_values) do
        {
          type: 'repository-view',
          actions: 'a,b',
          format: '*.p',
          repository_name: 'my_repo',
        }
      end

      let(:specific_update_values) do
        {
          actions: 'c,d',
          format: '*.p1',
          repository_name: 'my_repo1',
        }
      end

      it_behaves_like 'simple privilege'
    end

    describe 'for repository-content-selector' do
      let(:specific_values) do
        {
          type: 'repository-content-selector',
          actions: 'a,b',
          content_selector: '*.p',
          repository_name: 'my_repo',
        }
      end

      let(:specific_update_values) do
        {
          actions: 'c,d',
          content_selector: '*.p1',
          repository_name: 'my_repo1',
        }
      end

      it_behaves_like 'simple privilege'
    end

    describe 'for script' do
      let(:specific_values) do
        {
          type: 'script',
          actions: 'a,b',
          script_name: 'my_script',
        }
      end

      let(:specific_update_values) do
        {
          actions: 'c,d',
          script_name: 'my_script1',
        }
      end

      it_behaves_like 'simple privilege'
    end

    describe 'for wildcard' do
      let(:specific_values) do
        {
          type: 'wildcard',
          actions: 'a,b',
          pattern: '*.p',
        }
      end

      let(:specific_update_values) do
        {
          actions: 'c,d',
          pattern: '*.p1',
        }
      end

      it_behaves_like 'simple privilege'
    end
  end

  describe 'delete(context, name)' do
    let(:name) { "privilege_#{SecureRandom.uuid}" }

    before(:each) { provider.create(context, name, name: name, **minimum_required_values) }

    it 'deletes the resource' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^privilege_}) }
      expect(resources.size).to eq(2)

      provider.delete(context, name)

      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^privilege_}) }
      expect(resources.size).to eq(1)
    end
  end
end
