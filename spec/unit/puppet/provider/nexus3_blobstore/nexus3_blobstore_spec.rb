# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::Nexus3Blobstore')
require 'puppet/provider/nexus3_blobstore/nexus3_blobstore'

RSpec.describe Puppet::Provider::Nexus3Blobstore::Nexus3Blobstore do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  def clear_stores
    provider.get(context).each do |resource|
      provider.delete(context, resource[:name]) if resource[:name] != 'default'
    end
  end

  before(:each) do
    stub_config
    clear_stores
  end

  after(:each) do
    WebMock.reset!
    WebMock.disable_net_connect!(allow_localhost: true)
    clear_stores
  end

  describe '#get' do
    it 'processes resources' do
      resources = provider.get(context)
      expect(resources.size).to eq(1)
      expect(resources[0].keys.sort).to eq(%i[type soft_quota_enabled quota_limit_bytes quota_type path access_key_id assume_role bucket encryption_key
                                              encryption_type endpoint expiration forcepathstyle max_connection_pool_size prefix region secret_access_key
                                              session_token signertype name ensure].sort)
    end

    # There is not a good way to test getting S3 resources without having a real S3 blobstore. So, skipping it
  end

  describe 'set(context, changes)' do
    it 'prevent changing the type of the blobstore' do
      changes = {
        foo:  {
          is: { name: 'temporary', type: 'File', soft_quota_enabled: true, quota_limit_bytes: 60, quota_type: 'spaceUsedQuota', path: 'foo', ensure: 'present' },
          should: { name: 'temporary', type: 'S3', soft_quota_enabled: true, quota_type: 'spaceUsedQuota', quota_limit_bytes: 60, region: 'DEFAULT', bucket: 'foo', expiration: 3, ensure: 'present' }
        }
      }
      expect { provider.set(context, changes) }.to raise_error(ArgumentError, %r{type cannot be changed})
    end
  end

  describe 'create(context, name, should)' do
    context 'for File type' do
      let(:values) do
        {
          name: "blobstore_#{SecureRandom.uuid}",
          type: 'File',
          path: '/tmp/foo',
          soft_quota_enabled: true,
          quota_limit_bytes: 64,
          quota_type: 'spaceRemainingQuota',
        }
      end

      it 'creates the resource' do
        resources = provider.get(context)
        expect(resources.size).to eq(1)

        provider.create(context, values[:name], **values)

        resources = provider.get(context)
        expect(resources.size).to eq(2)

        resource = resources.find { |r| r[:name] == values[:name] }
        resource.delete_if { |key| resource[key].to_s.empty? }
        expect(resource).to eq(values.merge(ensure: 'present'))
      end
    end

    context 'for S3 type' do
      before(:each) do
        WebMock.disable_net_connect!
        stub_request(:get, 'http://localhost:8081/service/rest/v1/script/').to_return(status: 403)
        allow(Nexus3::API).to receive(:nexus3_server_version).and_return(3.21)
        stub_request(:post, %r{http://localhost:8081/service/rest/v1/script/}).to_return(status: 204)
        stub_request(:post, %r{http://localhost:8081/service/rest/v1/script/.*/run}).to_return(status: 200, body: '{}')
        stub_request(:delete, %r{http://localhost:8081/service/rest/v1/script/.*}).to_return(status: 204)
        allow(SecureRandom).to receive(:hex).and_return('57c0b7b66e8323f4dd583db53bc9c93f')
      end

      let(:values) do
        {
          name: 'blobstore_90578243-95ce-4f02-af8b-fcef60cc93d5',
          type: 'S3',
          region: 'us-west-2',
          bucket: 'bucket-foo1',
          prefix: 'bar_prefix',
          expiration: 12,
          access_key_id: 'AKIAYGHGZ',
          secret_access_key: 'kcGvjunIuP90rhi',
          assume_role: 'role_for_store',
          session_token: 'my_session',
          encryption_type: 'kmsManagedEncryption',
          encryption_key: 'arn:aws:kms:us-west-2:563124749982:alias/aws/s3',
          endpoint: 'https://foo/bar',
          max_connection_pool_size: 3,
          signertype: 'S3SignerType',
          forcepathstyle: true,
          soft_quota_enabled: true,
          quota_limit_bytes: 60,
          quota_type: 'spaceRemainingQuota',
        }
      end

      it 'creates the resource' do
        provider.create(context, values[:name], **values)
        expected_script = <<-EOS
def blobStoreManager = container.lookup(org.sonatype.nexus.blobstore.api.BlobStoreManager.class.name)

def config = blobStoreManager.newConfiguration()

config.setName('blobstore_90578243-95ce-4f02-af8b-fcef60cc93d5')
config.setType('S3')

config.setAttributes([:])

config.attributes.blobStoreQuotaConfig = [
  quotaType: 'spaceRemainingQuota',
  quotaLimitBytes: new Long(62914560000000),
]

config.attributes.s3 = [:]
config.attributes.s3.bucket = 'bucket-foo1'
config.attributes.s3.prefix = 'bar_prefix'
config.attributes.s3.accessKeyId = 'AKIAYGHGZ'
config.attributes.s3.secretAccessKey = 'kcGvjunIuP90rhi'
config.attributes.s3.sessionToken = 'my_session'
config.attributes.s3.assumeRole = 'role_for_store'
config.attributes.s3.encryption_type = 'kmsManagedEncryption'
config.attributes.s3.encryption_key = 'arn:aws:kms:us-west-2:563124749982:alias/aws/s3'
config.attributes.s3.region = 'us-west-2'
config.attributes.s3.endpoint = 'https://foo/bar'
config.attributes.s3.max_connection_pool_size = '3'
config.attributes.s3.expiration = 12
config.attributes.s3.signertype = 'S3SignerType'
config.attributes.s3.forcepathstyle = 'true'


blobStoreManager.create(config)
        EOS

        expected_body = %({"name":"57c0b7b66e8323f4dd583db53bc9c93f","type":"groovy","content":"#{expected_script.gsub(%r{\n}, '\\n')}"})
        expected_request = a_request(:post, %r{http://localhost:8081/service/rest/v1/script/}).with(body: expected_body)
        expect(expected_request).to have_been_requested
      end
    end
  end

  describe 'update(context, name, should)' do
    context 'for File type' do
      before(:each) { provider.create(context, values[:name], **default_values) }

      let(:default_values) { Puppet::Type.type(:nexus3_blobstore).new(name: values[:name], path: 'foo').to_hash }

      let(:values) do
        {
          name: "blobstore_#{SecureRandom.uuid}",
          type: 'File',
          path: '/tmp/foo',
          soft_quota_enabled: true,
          quota_limit_bytes: 64,
          quota_type: 'spaceRemainingQuota',
        }
      end

      it 'updates the resource' do
        original_resource = provider.get(context).find { |resource| resource[:name] == values[:name] }

        provider.update(context, values[:name], **values)

        new_resource = provider.get(context).find { |resource| resource[:name] == values[:name] }
        expect(original_resource).not_to eq(new_resource)

        new_resource.delete_if { |key| new_resource[key].to_s.empty? }
        expect(new_resource).to eq(values.merge(ensure: 'present'))
      end
    end

    context 'for S3 type' do
      before(:each) do
        WebMock.disable_net_connect!
        stub_request(:get, 'http://localhost:8081/service/rest/v1/script/').to_return(status: 403)
        allow(Nexus3::API).to receive(:nexus3_server_version).and_return(3.21)
        stub_request(:post, %r{http://localhost:8081/service/rest/v1/script/}).to_return(status: 204)
        stub_request(:post, %r{http://localhost:8081/service/rest/v1/script/.*/run}).to_return(status: 200, body: '{}')
        stub_request(:delete, %r{http://localhost:8081/service/rest/v1/script/.*}).to_return(status: 204)
        allow(SecureRandom).to receive(:hex).and_return('57c0b7b66e8323f4dd583db53bc9c93f')
      end

      let(:default_values) do
        Puppet::Type.type(:nexus3_blobstore).new(name: values[:name], type: 'S3', bucket: 'bucket-foo1', region: 'us-west-2', access_key_id: 'AKIAYGHGZ', secret_access_key: 'kcGvjunIuP90rhi').to_hash
      end

      let(:values) do
        {
          name: 'blobstore_90578243-95ce-4f02-af8b-fcef60cc93d5',
          type: 'S3',
          region: 'us-west-2',
          bucket: 'bucket-foo1',
          prefix: 'bar_prefix',
          expiration: 12,
          access_key_id: 'AKIAYGHGZ',
          secret_access_key: 'kcGvjunIuP90rhi',
          assume_role: 'role_for_store',
          session_token: 'my_session',
          encryption_type: 'kmsManagedEncryption',
          encryption_key: 'arn:aws:kms:us-west-2:563124749982:alias/aws/s3',
          endpoint: 'https://foo/bar',
          max_connection_pool_size: 3,
          signertype: 'S3SignerType',
          forcepathstyle: true,
          soft_quota_enabled: true,
          quota_limit_bytes: 60,
          quota_type: 'spaceRemainingQuota',
        }
      end

      it 'updates the resource' do
        provider.update(context, values[:name], **values)

        expected_script = <<-EOS
def blobStoreManager = container.lookup(org.sonatype.nexus.blobstore.api.BlobStoreManager.class.name)
def blobStore = blobStoreManager.get('blobstore_90578243-95ce-4f02-af8b-fcef60cc93d5')
def config = blobStore.getBlobStoreConfiguration()

config.setAttributes([:])

config.attributes.blobStoreQuotaConfig = [
  quotaType: 'spaceRemainingQuota',
  quotaLimitBytes: new Long(62914560000000),
]

config.attributes.s3 = [:]
config.attributes.s3.bucket = 'bucket-foo1'
config.attributes.s3.prefix = 'bar_prefix'
config.attributes.s3.accessKeyId = 'AKIAYGHGZ'
config.attributes.s3.secretAccessKey = 'kcGvjunIuP90rhi'
config.attributes.s3.sessionToken = 'my_session'
config.attributes.s3.assumeRole = 'role_for_store'
config.attributes.s3.encryption_type = 'kmsManagedEncryption'
config.attributes.s3.encryption_key = 'arn:aws:kms:us-west-2:563124749982:alias/aws/s3'
config.attributes.s3.region = 'us-west-2'
config.attributes.s3.endpoint = 'https://foo/bar'
config.attributes.s3.max_connection_pool_size = '3'
config.attributes.s3.expiration = 12
config.attributes.s3.signertype = 'S3SignerType'
config.attributes.s3.forcepathstyle = 'true'


blobStoreManager.update(config)

if ((config.type == 'S3') && !blobStore.isStarted()) {
  blobStore.start()
  while (!blobStore.isStarted()) {
    sleep(5)
  }
}
        EOS

        expected_body = %({"name":"57c0b7b66e8323f4dd583db53bc9c93f","type":"groovy","content":"#{expected_script.gsub(%r{\n}, '\\n')}"})
        expected_request = a_request(:post, %r{http://localhost:8081/service/rest/v1/script/}).with(body: expected_body)
        expect(expected_request).to have_been_requested
      end
    end
  end

  describe 'delete(context, name)' do
    let(:name) { "blobstore_#{SecureRandom.uuid}" }

    before(:each) { provider.create(context, name, name: name, type: 'File', path: '/tmp/foo') }

    it 'deletes the resource' do
      resources = provider.get(context)
      expect(resources.size).to eq(2)

      provider.delete(context, name)

      resources = provider.get(context)
      expect(resources.size).to eq(1)
    end
  end
end
