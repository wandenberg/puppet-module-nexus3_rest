require 'spec_helper'

describe Puppet::Type.type(:nexus3_cleanup_policy) do
  subject { Puppet::Type.type(:nexus3_cleanup_policy) }

  let(:required_values) do
    {
      name: 'foo',
      last_downloaded: 7,
    }
  end
  
  describe 'by default' do
    let(:instance) { subject.new(required_values) }

    it { expect(instance[:format]).to eq(:all) }
  end

  it 'should not accept no criteria' do
    expect {
      subject.new(name: 'any', format: :all)
    }.to raise_error(Puppet::ResourceError, /At least one criteria must be provided/)
  end

  it 'should validate format' do
    expect {
      subject.new(required_values.merge(format: 'invalid'))
    }.to raise_error(Puppet::Error, /Invalid value "invalid"/)
  end

  specify 'should accept apt format policy' do
    subject.new(required_values.merge(format: 'apt'))
  end

  describe :is_prerelease do
    let(:prerel_values) do
      required_values.merge(format: 'yum')
    end
    
    specify 'should default to nil' do
      expect(subject.new(required_values)[:is_prerelease]).to be nil
    end

    specify 'should accept :true for yum repos' do
      expect { subject.new(prerel_values.merge(is_prerelease: :true)) }.to_not raise_error
      expect(subject.new(prerel_values.merge(is_prerelease: :true))[:is_prerelease]).to be :true
    end

    specify 'should accept "true" for yum repos' do
      expect { subject.new(prerel_values.merge(is_prerelease: 'true')) }.to_not raise_error
      expect(subject.new(prerel_values.merge(is_prerelease: 'true'))[:is_prerelease]).to be :true
    end

    specify 'should accept :false for yum repos' do
      expect { subject.new(prerel_values.merge(is_prerelease: :false)) }.to_not raise_error
      expect(subject.new(prerel_values.merge(is_prerelease: :false))[:is_prerelease]).to be :false
    end

    specify 'should accept "false" for yum repos' do
      expect { subject.new(prerel_values.merge(is_prerelease: 'false')) }.to_not raise_error
      expect(subject.new(prerel_values.merge(is_prerelease: 'false'))[:is_prerelease]).to be :false
    end
  end

  describe 'when removing' do
    it { expect { subject.new(name: 'foo', ensure: :absent) }.to_not raise_error }
  end
end
