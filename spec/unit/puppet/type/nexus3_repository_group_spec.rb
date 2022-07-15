require 'spec_helper'

describe Puppet::Type.type(:nexus3_repository_group) do
  let(:required_values) do
    {
      name: 'default',
      repositories: ['repo-a'],
      provider_type: 'go',
    }
  end

  describe 'by default' do
    let(:instance) { described_class.new(required_values) }

    it 'has true for online property' do
      expect(instance[:online]).to eq(:true)
    end

    it 'has default for blobstore_name property' do
      expect(instance[:blobstore_name]).to eq('default')
    end

    it 'has true for strict_content_type_validation property' do
      expect(instance[:strict_content_type_validation]).to eq(:true)
    end

    describe 'for docker provider_type' do
      let(:instance) { described_class.new(required_values.merge(provider_type: 'docker')) }

      it 'has false for force_basic_auth property' do
        expect(instance[:force_basic_auth]).to eq(:false)
      end

      it 'has false for v1_enabled property' do
        expect(instance[:v1_enabled]).to eq(:false)
      end
    end

    describe 'for maven2 provider_type' do
      let(:instance) { described_class.new(required_values.merge(provider_type: 'maven2')) }

      it 'has strict for layout_policy property' do
        expect(instance[:layout_policy]).to eq('strict')
      end

      it 'has release for version_policy property' do
        expect(instance[:version_policy]).to eq('release')
      end

      it 'has inline for content_disposition property' do
        expect(instance[:content_disposition]).to eq('inline')
      end
    end

    describe 'for raw provider_type' do
      let(:instance) { described_class.new(required_values.merge(provider_type: 'raw')) }

      it 'has attachment for content_disposition property' do
        expect(instance[:content_disposition]).to eq('attachment')
      end
    end
  end

  describe 'allow overwrite default values' do
    let(:instance) { described_class.new(required_values.merge(online: false, blobstore_name: 'foo', strict_content_type_validation: false)) }

    it 'has false for online property' do
      expect(instance[:online]).to eq(:false)
    end

    it 'has foo for blobstore_name property' do
      expect(instance[:blobstore_name]).to eq('foo')
    end

    it 'has false for strict_content_type_validation property' do
      expect(instance[:strict_content_type_validation]).to eq(:false)
    end

    describe 'for docker provider_type' do
      let(:instance) { described_class.new(required_values.merge(provider_type: 'docker', force_basic_auth: true, v1_enabled: true)) }

      it 'has true for force_basic_auth property' do
        expect(instance[:force_basic_auth]).to eq(:true)
      end

      it 'has true for v1_enabled property' do
        expect(instance[:v1_enabled]).to eq(:true)
      end
    end

    describe 'for maven2 provider_type' do
      let(:instance) { described_class.new(required_values.merge(provider_type: 'maven2', layout_policy: 'permissive', version_policy: 'snapshot', content_disposition: 'attachment')) }

      it 'has permissive for layout_policy property' do
        expect(instance[:layout_policy]).to eq('permissive')
      end

      it 'has snapshot for version_policy property' do
        expect(instance[:version_policy]).to eq('snapshot')
      end

      it 'has attachment for content_disposition property' do
        expect(instance[:content_disposition]).to eq('attachment')
      end
    end

    describe 'for raw provider_type' do
      let(:instance) { described_class.new(required_values.merge(provider_type: 'raw', content_disposition: 'inline')) }

      it 'has inline for content_disposition property' do
        expect(instance[:content_disposition]).to eq('inline')
      end
    end
  end

  it 'validate provider_type' do
    expect {
      described_class.new(required_values.merge(provider_type: 'invalid'))
    }.to raise_error(ArgumentError, %r{'invalid' not supported})
  end

  it 'ensure the http_port is a integer' do
    expect(described_class.new(required_values.merge(http_port: '9999'))[:http_port]).to eq(9999)
  end

  it 'ensure the https_port is a integer' do
    expect(described_class.new(required_values.merge(https_port: '9999'))[:https_port]).to eq(9999)
  end

  describe 'online' do
    specify 'should default to false' do
      expect(described_class.new(required_values)[:online]).to be :true
    end

    specify 'should accept :true' do
      expect { described_class.new(required_values.merge(online: :true)) }.not_to raise_error
      expect(described_class.new(required_values.merge(online: :true))[:online]).to be :true
    end

    specify 'should accept "true' do
      expect { described_class.new(required_values.merge(online: 'true')) }.not_to raise_error
      expect(described_class.new(required_values.merge(online: 'true'))[:online]).to be :true
    end

    specify 'should accept :false' do
      expect { described_class.new(required_values.merge(online: :false)) }.not_to raise_error
      expect(described_class.new(required_values.merge(online: :false))[:online]).to be :false
    end

    specify 'should accept "false"' do
      expect { described_class.new(required_values.merge(online: 'false')) }.not_to raise_error
      expect(described_class.new(required_values.merge(online: 'false'))[:online]).to be :false
    end
  end

  describe 'strict_content_type_validation' do
    specify 'should default to false' do
      expect(described_class.new(required_values)[:strict_content_type_validation]).to be :true
    end

    specify 'should accept :true' do
      expect { described_class.new(required_values.merge(strict_content_type_validation: :true)) }.not_to raise_error
      expect(described_class.new(required_values.merge(strict_content_type_validation: :true))[:strict_content_type_validation]).to be :true
    end

    specify 'should accept "true' do
      expect { described_class.new(required_values.merge(strict_content_type_validation: 'true')) }.not_to raise_error
      expect(described_class.new(required_values.merge(strict_content_type_validation: 'true'))[:strict_content_type_validation]).to be :true
    end

    specify 'should accept :false' do
      expect { described_class.new(required_values.merge(strict_content_type_validation: :false)) }.not_to raise_error
      expect(described_class.new(required_values.merge(strict_content_type_validation: :false))[:strict_content_type_validation]).to be :false
    end

    specify 'should accept "false"' do
      expect { described_class.new(required_values.merge(strict_content_type_validation: 'false')) }.not_to raise_error
      expect(described_class.new(required_values.merge(strict_content_type_validation: 'false'))[:strict_content_type_validation]).to be :false
    end
  end

  describe 'repositories' do
    specify 'should accept a valid array of repositories' do
      expect { described_class.new(required_values.merge(repositories: %w[repo-c repo-d])) }.not_to raise_error
    end

    specify 'should not have default value for repositories' do
      expect {
        required_values.delete(:repositories)
        described_class.new(required_values)
      }.to raise_error(ArgumentError, %r{repositories must be an array of strings})
    end

    specify 'should not accept an empty array' do
      expect {
        described_class.new(required_values.merge(repositories: []))
      }.to raise_error(ArgumentError, %r{repositories must be an array of strings})
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(required_values.merge(repositories: ''))
      }.to raise_error(ArgumentError, %r{repositories must be an array of strings})
    end

    specify 'should not accept a string as array' do
      expect {
        described_class.new(required_values.merge(repositories: 'name1,name2'))
      }.to raise_error(ArgumentError, %r{repositories must be an array of strings})
    end
  end

  describe 'provider_type' do
    specify 'should accept a valid provider_type' do
      expect { described_class.new(required_values.merge(provider_type: 'go')) }.not_to raise_error
    end

    specify 'should not have default value for provider_type' do
      expect {
        required_values.delete(:provider_type)
        described_class.new(required_values)
      }.to raise_error(ArgumentError, %r{provider_type must not be empty})
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(required_values.merge(provider_type: ''))
      }.to raise_error(ArgumentError, %r{provider_type must not be empty})
    end

    specify 'should not accept an invalid value' do
      expect {
        described_class.new(required_values.merge(provider_type: 'invalid'))
      }.to raise_error(ArgumentError, %r{'invalid' not supported})
    end
  end

  describe 'when removing' do
    it { expect { described_class.new(name: 'any', ensure: :absent) }.not_to raise_error }
  end
end
