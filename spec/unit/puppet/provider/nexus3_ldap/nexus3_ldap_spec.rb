# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::Nexus3Ldap')
require 'puppet/provider/nexus3_ldap/nexus3_ldap'

RSpec.describe Puppet::Provider::Nexus3Ldap::Nexus3Ldap do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  let(:minimum_required_values) do
    {
      protocol: 'ldap',
      hostname: 'localhost',
      port: 389,
      search_base: 'dc=example,dc=com',
      user_object_class: 'inetOrgPerson',
      user_email_attribute: 'mail',
      user_id_attribute: 'uid',
      user_real_name_attribute: 'cn',
      ldap_groups_as_roles: false,
      max_incidents_count: 5,
      connection_retry_delay: 65,
      connection_timeout: 78,
      user_subtree: false,
      group_subtree: false,
      authentication_scheme: 'none',
    }
  end

  let(:values) do
    {
      name: "ldap_#{SecureRandom.uuid}",
      hostname: 'ldap.server.com',
      search_base: 'sch_base',
      order: 1,
      protocol: 'ldap',
      port: 1234,
      max_incidents_count: 5,
      connection_retry_delay: 65,
      connection_timeout: 78,
      sasl_realm: 'sasl_realm',
      authentication_scheme: 'simple',
      username: 'username',
      password: 'password',
      user_base_dn: 'user_base_dn',
      user_email_attribute: 'user_email_attribute',
      user_id_attribute: 'user_id_attribute',
      user_object_class: 'user_object_class',
      user_password_attribute: 'user_password_attribute',
      user_real_name_attribute: 'user_real_name_attribute',
      user_subtree: true,
      user_member_of_attribute: 'user_member_of_attribute',
      group_base_dn: 'group_base_dn',
      group_id_attribute: 'group_id_attribute',
      group_member_attribute: 'group_member_attribute',
      group_member_format: 'group_member_format',
      group_object_class: 'group_object_class',
      group_subtree: true,
      ldap_filter: 'ldap_filter',
      ldap_groups_as_roles: true,
      group_type: 'dynamic',
    }
  end

  before(:each) do
    stub_config
    provider.get(context).each do |resource|
      provider.delete(context, resource[:name]) if resource[:name].match?(%r{^ldap_})
    end

    name = "ldap_#{SecureRandom.uuid}"
    provider.create(context, name, name: name, **minimum_required_values)
  end

  describe '#get' do
    it 'processes resources' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^ldap_}) }
      expect(resources.size).to eq(1)
      expect(resources[0].keys.sort).to eq(%i[authentication_scheme connection_retry_delay connection_timeout ensure group_base_dn group_id_attribute group_member_attribute group_member_format
                                              group_object_class group_subtree group_type hostname ldap_filter ldap_groups_as_roles max_incidents_count name order password port protocol
                                              sasl_realm search_base user_base_dn user_email_attribute user_id_attribute user_member_of_attribute user_object_class user_password_attribute
                                              user_real_name_attribute user_subtree username ].sort)
    end
  end

  describe 'create(context, name, should)' do
    it 'creates the resource' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^ldap_}) }
      expect(resources.size).to eq(1)

      provider.create(context, values[:name], **values)

      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^ldap_}) }
      expect(resources.size).to eq(2)

      resource = resources.find { |r| r[:name] == values[:name] }
      expect(resource.merge(order: nil)).to eq(values.merge(ensure: 'present', order: nil))
    end
  end

  describe 'update(context, name, should)' do
    before(:each) { provider.create(context, values[:name], **default_values) }

    let(:default_values) { Puppet::Type.type(:nexus3_ldap).new(name: values[:name], **minimum_required_values).to_hash }

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
    let(:name) { "ldap_#{SecureRandom.uuid}" }

    before(:each) { provider.create(context, name, name: name, **minimum_required_values) }

    it 'deletes the resource' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^ldap_}) }
      expect(resources.size).to eq(2)

      provider.delete(context, name)

      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^ldap_}) }
      expect(resources.size).to eq(1)
    end
  end
end
