require 'spec_helper'

describe Puppet::Type.type(:nexus3_repository_group) do
  let(:required_values) do
    {
      name: 'default',
      repositories: 'repo-a',
      provider_type: :docker,
    }
  end

  describe 'by default' do
    let(:instance) { described_class.new(required_values) }

    it { expect(instance[:blobstore_name]).to eq('default') }
    it { expect(instance[:online]).to eq(:true) }
    it { expect(instance[:strict_content_type_validation]).to eq(:true) }
  end

  it 'validate provider_type' do
    expect {
      described_class.new(required_values.merge(provider_type: 'invalid'))
    }.to raise_error(Puppet::Error, %r{Invalid value "invalid"})
  end

  it 'accept Maven2 group repository' do
    described_class.new(required_values.merge(provider_type: :maven2))
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
      }.to raise_error(Puppet::ResourceError, %r{repositories in group must be provided as a non empty array})
    end

    specify 'should not accept an empty array' do
      expect {
        described_class.new(required_values.merge(repositories: []))
      }.to raise_error(Puppet::ResourceError, %r{repositories in group must be provided as a non empty array})
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(required_values.merge(repositories: ''))
      }.to raise_error(Puppet::ResourceError, %r{Parameter repositories failed})
    end

    specify 'should not accept a string as array' do
      expect {
        described_class.new(required_values.merge(repositories: 'name1,name2'))
      }.to raise_error(Puppet::ResourceError, %r{Parameter repositories failed})
    end
  end

  describe 'provider_type' do
    specify 'should accept a valid provider_type' do
      expect { described_class.new(required_values.merge(provider_type: 'docker')) }.not_to raise_error
    end

    specify 'should not have default value for provider_type' do
      expect {
        required_values.delete(:provider_type)
        described_class.new(required_values)
      }.to raise_error(Puppet::ResourceError, %r{provider_type must be provided})
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(required_values.merge(provider_type: ''))
      }.to raise_error(Puppet::ResourceError, %r{Parameter provider_type failed})
    end
  end

  describe 'when removing' do
    it { expect { described_class.new(name: 'any', ensure: :absent) }.not_to raise_error }
  end
end
