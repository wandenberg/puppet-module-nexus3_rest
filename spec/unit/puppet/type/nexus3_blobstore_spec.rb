require 'spec_helper'

describe Puppet::Type.type(:nexus3_blobstore) do
  shared_examples_for 'check quota properties' do
    specify 'requires a value for quota type' do
      expect { described_class.new(values.merge(quota_limit_bytes: 1)) }.to raise_error(ArgumentError, %r{quota_type must be provided})
      expect { described_class.new(values.merge(quota_type: nil, quota_limit_bytes: 1)) }.to raise_error(ArgumentError, %r{quota_type must be provided})
      expect { described_class.new(values.merge(quota_type: '', quota_limit_bytes: 1)) }.to raise_error(ArgumentError, %r{quota_type must be provided})
      expect { described_class.new(values.merge(quota_type: '  ', quota_limit_bytes: 1)) }.to raise_error(ArgumentError, %r{quota_type must be provided})
    end

    specify 'requires a value for quota limit bytes' do
      expect { described_class.new(values.merge(quota_type: 'spaceUsedQuota')) }.to raise_error(ArgumentError, %r{quota_limit_bytes must be greater than 0})
      expect { described_class.new(values.merge(quota_limit_bytes: nil, quota_type: 'spaceUsedQuota')) }.to raise_error(ArgumentError, %r{quota_limit_bytes must be greater than 0})
      expect { described_class.new(values.merge(quota_limit_bytes: 0, quota_type: 'spaceUsedQuota')) }.to raise_error(ArgumentError, %r{quota_limit_bytes must be greater than 0})
      expect { described_class.new(values.merge(quota_limit_bytes: -1, quota_type: 'spaceUsedQuota')) }.to raise_error(ArgumentError, %r{quota_limit_bytes must be greater than 0})
    end

    specify 'quota type to be either spaceRemainingQuota or spaceUsedQuota' do
      expect { described_class.new(values.merge(quota_type: 'spaceRemainingQuota', quota_limit_bytes: 1)) }.not_to raise_error
      expect { described_class.new(values.merge(quota_type: 'spaceUsedQuota', quota_limit_bytes: 1)) }.not_to raise_error
      expect { described_class.new(values.merge(quota_type: 'foo', quota_limit_bytes: 1)) }.to raise_error(Puppet::ResourceError, %r{Parameter quota_type failed})
    end
  end

  context 'for a normal File store' do
    let(:base_values) do
      {
        name: 'any',
        type: 'File',
      }
    end

    describe 'path' do
      specify 'requires a value' do
        expect { described_class.new(base_values.merge(path: nil)) }.to raise_error(ArgumentError, %r{Path is required})
        expect { described_class.new(base_values.merge(path: '')) }.to raise_error(ArgumentError, %r{Path is required})
        expect { described_class.new(base_values.merge(path: '  ')) }.to raise_error(ArgumentError, %r{Path is required})
      end

      specify 'should accept relative path' do
        expect { described_class.new(base_values.merge(path: 'my/path')) }.not_to raise_error
      end

      specify 'should accept absolute path' do
        expect { described_class.new(base_values.merge(path: '/my/path')) }.not_to raise_error
      end
    end

    context 'when soft quota is enabled' do
      let(:values) do
        base_values.merge(path: 'foo', soft_quota_enabled: true)
      end

      it_behaves_like 'check quota properties'
    end

    specify 'any other property besides path and quota related should be emptied' do
      expect(described_class.new(base_values.merge(path: 'foo', soft_quota_enabled: true, quota_limit_bytes: 1, quota_type: 'spaceUsedQuota', bucket: 'bar'))[:bucket]).to be_empty
    end
  end

  context 'for a S3 store' do
    let(:base_values) do
      {
        name: 'any',
        type: 'S3',
      }
    end

    describe 'bucket' do
      specify 'requires a value' do
        expect { described_class.new(base_values.merge(bucket: nil)) }.to raise_error(ArgumentError, %r{Bucket is required})
        expect { described_class.new(base_values.merge(bucket: '')) }.to raise_error(ArgumentError, %r{Bucket is required})
        expect { described_class.new(base_values.merge(bucket: '  ')) }.to raise_error(ArgumentError, %r{Bucket is required})
      end
    end

    describe 'expiration' do
      let(:values) do
        base_values.merge(bucket: 'foo-1.2')
      end

      specify 'must be equal or greater than -1' do
        expect { described_class.new(values.merge(expiration: -2)) }.to raise_error(ArgumentError, %r{Expiration must be equal or greater than -1})
        expect { described_class.new(values.merge(expiration: -1)) }.not_to raise_error
        expect { described_class.new(values.merge(expiration: 0)) }.not_to raise_error
        expect { described_class.new(values.merge(expiration: 1)) }.not_to raise_error
      end

      specify 'default value of 3' do
        expect(described_class.new(values)[:expiration]).to be 3
      end
    end

    describe 'authentication' do
      let(:values) do
        base_values.merge(bucket: 'foo-1.2')
      end

      specify 'either set access_key_id and secret_access_key, or none' do
        expect { described_class.new(values.merge(access_key_id: 'foo', secret_access_key: nil)) }.to raise_error(ArgumentError, %r{Either set access_key_id and secret_access_key, or none.})
        expect { described_class.new(values.merge(access_key_id: 'foo', secret_access_key: '')) }.to raise_error(ArgumentError, %r{Either set access_key_id and secret_access_key, or none.})
        expect { described_class.new(values.merge(access_key_id: 'foo', secret_access_key: ' ')) }.to raise_error(ArgumentError, %r{Either set access_key_id and secret_access_key, or none.})
        expect { described_class.new(values.merge(access_key_id: nil, secret_access_key: 'bar')) }.to raise_error(ArgumentError, %r{Either set access_key_id and secret_access_key, or none.})
        expect { described_class.new(values.merge(access_key_id: '', secret_access_key: 'bar')) }.to raise_error(ArgumentError, %r{Either set access_key_id and secret_access_key, or none.})
        expect { described_class.new(values.merge(access_key_id: ' ', secret_access_key: 'bar')) }.to raise_error(ArgumentError, %r{Either set access_key_id and secret_access_key, or none.})
        expect { described_class.new(values.merge(access_key_id: 'foo', secret_access_key: 'bar')) }.not_to raise_error
      end
    end

    describe 'endpoint' do
      let(:values) do
        base_values.merge(bucket: 'foo-1.2')
      end

      specify 'must follow pattern <protocol>:<path>' do
        expect { described_class.new(values.merge(endpoint: nil)) }.not_to raise_error
        expect { described_class.new(values.merge(endpoint: '')) }.not_to raise_error
        expect { described_class.new(values.merge(endpoint: ' ')) }.not_to raise_error
        expect { described_class.new(values.merge(endpoint: 'foo')) }.to raise_error(Puppet::ResourceError, %r{Parameter endpoint failed})
        expect { described_class.new(values.merge(endpoint: 'foo:')) }.to raise_error(Puppet::ResourceError, %r{Parameter endpoint failed})
        expect { described_class.new(values.merge(endpoint: ':bar')) }.to raise_error(Puppet::ResourceError, %r{Parameter endpoint failed})
        expect { described_class.new(values.merge(endpoint: 'foo:/bar')) }.not_to raise_error
      end
    end

    describe 'max_connection_pool_size' do
      let(:values) do
        base_values.merge(bucket: 'foo-1.2')
      end

      specify 'must be equal or greater than 1' do
        expect { described_class.new(values.merge(max_connection_pool_size: -1)) }.to raise_error(ArgumentError, %r{max_connection_pool_size must be equal or greater than 1})
        expect { described_class.new(values.merge(max_connection_pool_size: 0)) }.to raise_error(ArgumentError, %r{max_connection_pool_size must be equal or greater than 1})
        expect { described_class.new(values.merge(max_connection_pool_size: 1)) }.not_to raise_error
      end
    end

    context 'when soft quota is enabled' do
      let(:values) do
        base_values.merge(bucket: 'foo-1.2', soft_quota_enabled: true)
      end

      it_behaves_like 'check quota properties'
    end
  end
end
