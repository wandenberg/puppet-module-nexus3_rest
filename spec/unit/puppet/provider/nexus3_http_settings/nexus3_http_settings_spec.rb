# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::Nexus3HttpSettings')
require 'puppet/provider/nexus3_http_settings/nexus3_http_settings'

RSpec.describe Puppet::Provider::Nexus3HttpSettings::Nexus3HttpSettings do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  before(:each) { stub_config }

  describe '#get' do
    it 'processes resources' do
      resources = provider.get(context)
      expect(resources.size).to eq(1)
      expect(resources[0].keys.sort).to eq(%i[http_enabled http_port http_host http_auth_type http_auth_username http_auth_password http_auth_ntlm_host http_auth_ntlm_domain https_enabled https_port
                                              https_host https_auth_type https_auth_username https_auth_password https_auth_ntlm_host https_auth_ntlm_domain non_proxy_hosts connection_user_agent
                                              connection_timeout connection_maximum_retries name ensure].sort)
    end
  end

  describe 'create(context, name, should)' do
    it 'creates the resource' do
      expect(context).to receive(:notice).with('Not possible to create new HTTP settings')

      provider.create(context, 'a', name: 'a', ensure: 'present')
    end
  end

  describe 'update(context, name, should)' do
    let(:values) { connection_values.merge(http_values).merge(https_values) }

    let(:connection_values) do
      {
        non_proxy_hosts: %w[xyz.com xxx.com],
        connection_user_agent: 'nexus_useragent',
        connection_timeout: 90,
        connection_maximum_retries: 5,
      }
    end

    let(:http_values) do
      {
        http_enabled: true,
        http_port: 9991,
        http_host: 'foo.com',
        http_auth_type: 'ntlm',
        http_auth_username: 'userhttp',
        http_auth_password: 'passhttp',
        http_auth_ntlm_host: 'ntlmhosthttp',
        http_auth_ntlm_domain: 'ntlmdomainhttp',
      }
    end

    let(:https_values) do
      {
        https_enabled: true,
        https_port: 9992,
        https_host: 'bar.com',
        https_auth_type: 'ntlm',
        https_auth_username: 'userhttps',
        https_auth_password: 'passhttps',
        https_auth_ntlm_host: 'ntlmhosthttps',
        https_auth_ntlm_domain: 'ntlmdomainhttps',
      }
    end

    let(:default_values) { Puppet::Type.type(:nexus3_http_settings).new({}).to_hash }

    shared_examples_for 'normal resource' do
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

    context 'http proxy' do
      context 'disabled' do
        let(:http_values) do
          {
            http_enabled: false,
            http_port: '',
            http_host: '',
            http_auth_type: '',
            http_auth_username: '',
            http_auth_password: '',
            http_auth_ntlm_host: '',
            http_auth_ntlm_domain: '',
          }
        end

        it_behaves_like 'normal resource'
      end

      context 'with auth type username' do
        let(:http_values) do
          {
            http_enabled: true,
            http_port: 9993,
            http_host: 'foo.bar',
            http_auth_type: 'username',
            http_auth_username: 'userhttp',
            http_auth_password: 'passhttp',
            http_auth_ntlm_host: '',
            http_auth_ntlm_domain: '',
          }
        end

        it_behaves_like 'normal resource'
      end

      context 'with auth type ntlm' do
        let(:http_values) do
          {
            http_enabled: true,
            http_port: 9993,
            http_host: 'foo.bar',
            http_auth_type: 'ntlm',
            http_auth_username: 'userhttp',
            http_auth_password: 'passhttp',
            http_auth_ntlm_host: 'ntlmhosthttp',
            http_auth_ntlm_domain: 'ntlmdomainhttp',
          }
        end

        it_behaves_like 'normal resource'
      end
    end

    context 'https proxy' do
      context 'disabled' do
        let(:https_values) do
          {
            https_enabled: false,
            https_port: '',
            https_host: '',
            https_auth_type: '',
            https_auth_username: '',
            https_auth_password: '',
            https_auth_ntlm_host: '',
            https_auth_ntlm_domain: '',
          }
        end

        it_behaves_like 'normal resource'
      end

      context 'with auth type username' do
        let(:https_values) do
          {
            https_enabled: true,
            https_port: 9994,
            https_host: 'foo.bar',
            https_auth_type: 'username',
            https_auth_username: 'userhttps',
            https_auth_password: 'passhttps',
            https_auth_ntlm_host: '',
            https_auth_ntlm_domain: '',
          }
        end

        it_behaves_like 'normal resource'
      end

      context 'with auth type ntlm' do
        let(:https_values) do
          {
            https_enabled: true,
            https_port: 9994,
            https_host: 'foo.bar',
            https_auth_type: 'ntlm',
            https_auth_username: 'userhttps',
            https_auth_password: 'passhttps',
            https_auth_ntlm_host: 'ntlmhosthttps',
            https_auth_ntlm_domain: 'ntlmdomainhttps',
          }
        end

        it_behaves_like 'normal resource'
      end
    end
  end

  describe 'delete(context, name)' do
    it 'deletes the resource' do
      expect(context).to receive(:notice).with('Not possible to remove HTTP settings')

      provider.delete(context, 'foo')
    end
  end
end
