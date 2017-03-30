require 'spec_helper'

describe Puppet::Type.type(:nexus3_repository) do
  subject { Puppet::Type.type(:nexus3_repository) }

  let(:required_values) do
    {
      name: 'default',
      provider_type: :docker,
      type: :proxy
    }
  end
  
  describe 'by default' do
    let(:instance) { subject.new(required_values) }

    it { expect(instance[:blobstore_name]).to eq('default') }
    it { expect(instance[:online]).to eq(:true) }
    it { expect(instance[:strict_content_type_validation]).to eq(:true) }
    it { expect(instance[:version_policy]).to eq nil }
    it { expect(instance[:layout_policy]).to eq nil }
    it { expect(instance[:write_policy]).to eq nil }
    it { expect(instance[:remote_url]).to eq nil }
    it { expect(instance[:remote_auth_type]).to eq(:none) }
    it { expect(instance[:remote_user]).to eq nil }
    it { expect(instance[:remote_password]).to eq nil }
    it { expect(instance[:remote_ntlm_host]).to eq nil }
    it { expect(instance[:remote_ntlm_domain]).to eq nil }
  end

  describe 'for Maven2' do
    let(:group) { subject.new(required_values.merge(provider_type: :maven2)) }

    it { expect(group[:version_policy]).to eq(:release) }
    it { expect(group[:layout_policy]).to eq(:strict) }
    it { expect(group[:remote_auth_type]).to eq(:username) }
  end

  describe 'for hosted' do
    let(:group) { subject.new(required_values.merge(type: :hosted)) }

    it { expect(group[:write_policy]).to eq(:allow_write_once) }
  end

  it 'should validate type' do
    expect {
      subject.new(required_values.merge(type: 'invalid'))
    }.to raise_error(Puppet::Error, /Invalid value "invalid"/)
  end

  it 'should validate provider_type' do
    expect {
      subject.new(required_values.merge(provider_type: 'invalid'))
    }.to raise_error(Puppet::Error, /Invalid value "invalid"/)
  end

  it 'should accept Maven2 repository' do
    subject.new(required_values.merge(provider_type: :maven2))
  end

  it 'should validate version_policy' do
    expect {
      subject.new(required_values.merge(version_policy: 'invalid'))
    }.to raise_error(Puppet::Error, /Invalid value "invalid"/)
  end

  it 'should validate layout_policy' do
    expect {
      subject.new(required_values.merge(layout_policy: 'invalid'))
    }.to raise_error(Puppet::Error, /Invalid value "invalid"/)
  end

  it 'should validate write_policy' do
    expect {
      subject.new(required_values.merge(write_policy: 'invalid'))
    }.to raise_error(Puppet::Error, /Invalid value "invalid"/)
  end

  it 'should validate remote_auth_type' do
    expect {
      subject.new(required_values.merge(remote_auth_type: 'invalid'))
    }.to raise_error(Puppet::Error, /Invalid value "invalid"/)
  end

  describe :online do
    specify 'should default to false' do
      expect(subject.new(required_values)[:online]).to be :true
    end

    specify 'should accept :true' do
      expect { subject.new(required_values.merge(online: :true)) }.to_not raise_error
      expect(subject.new(required_values.merge(online: :true))[:online]).to be :true
    end

    specify 'should accept "true' do
      expect { subject.new(required_values.merge(online: 'true')) }.to_not raise_error
      expect(subject.new(required_values.merge(online: 'true'))[:online]).to be :true
    end

    specify 'should accept :false' do
      expect { subject.new(required_values.merge(online: :false)) }.to_not raise_error
      expect(subject.new(required_values.merge(online: :false))[:online]).to be :false
    end

    specify 'should accept "false"' do
      expect { subject.new(required_values.merge(online: 'false')) }.to_not raise_error
      expect(subject.new(required_values.merge(online: 'false'))[:online]).to be :false
    end
  end

  describe :strict_content_type_validation do
    specify 'should default to false' do
      expect(subject.new(required_values)[:strict_content_type_validation]).to be :true
    end

    specify 'should accept :true' do
      expect { subject.new(required_values.merge(strict_content_type_validation: :true)) }.to_not raise_error
      expect(subject.new(required_values.merge(strict_content_type_validation: :true))[:strict_content_type_validation]).to be :true
    end

    specify 'should accept "true' do
      expect { subject.new(required_values.merge(strict_content_type_validation: 'true')) }.to_not raise_error
      expect(subject.new(required_values.merge(strict_content_type_validation: 'true'))[:strict_content_type_validation]).to be :true
    end

    specify 'should accept :false' do
      expect { subject.new(required_values.merge(strict_content_type_validation: :false)) }.to_not raise_error
      expect(subject.new(required_values.merge(strict_content_type_validation: :false))[:strict_content_type_validation]).to be :false
    end

    specify 'should accept "false"' do
      expect { subject.new(required_values.merge(strict_content_type_validation: 'false')) }.to_not raise_error
      expect(subject.new(required_values.merge(strict_content_type_validation: 'false'))[:strict_content_type_validation]).to be :false
    end
  end

  describe :provider_type do
    specify 'should accept a valid provider_type' do
      expect { subject.new(required_values.merge(provider_type: 'docker')) }.to_not raise_error
    end

    specify 'should not have default value for provider_type' do
      expect {
        required_values.delete(:provider_type)
        subject.new(required_values)
      }.to raise_error(Puppet::ResourceError, /provider_type must be provided/)
    end

    specify 'should not accept empty string' do
      expect {
        subject.new(required_values.merge(provider_type: ''))
      }.to raise_error(Puppet::ResourceError, /Parameter provider_type failed/)
    end
  end

  describe 'when removing' do
    it { expect { subject.new(name: 'any', ensure: :absent) }.to_not raise_error }
  end
end
