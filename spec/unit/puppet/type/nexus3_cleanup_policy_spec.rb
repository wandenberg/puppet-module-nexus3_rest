require 'spec_helper'

describe Puppet::Type.type(:nexus3_cleanup_policy) do
  let(:required_values) do
    {
      name: 'foo',
      last_downloaded: 7,
    }
  end

  describe 'by default' do
    let(:instance) { described_class.new(required_values) }

    it { expect(instance[:format]).to eq('all') }
  end

  it 'validate format' do
    expect {
      described_class.new(required_values.merge(format: 'invalid'))
    }.to raise_error(Puppet::ResourceError, %r{Parameter format failed})
  end

  specify 'should accept apt format policy' do
    described_class.new(required_values.merge(format: 'apt'))
  end

  describe 'is_prerelease' do
    let(:prerel_values) do
      required_values.merge(format: 'yum')
    end

    specify 'should default to empty string' do
      expect(described_class.new(required_values)[:is_prerelease]).to eq ''
    end

    specify 'should accept :true for yum repos' do
      expect { described_class.new(prerel_values.merge(is_prerelease: :true)) }.not_to raise_error
      expect(described_class.new(prerel_values.merge(is_prerelease: :true))[:is_prerelease]).to be :true
    end

    specify 'should accept "true" for yum repos' do
      expect { described_class.new(prerel_values.merge(is_prerelease: 'true')) }.not_to raise_error
      expect(described_class.new(prerel_values.merge(is_prerelease: 'true'))[:is_prerelease]).to be :true
    end

    specify 'should accept :false for yum repos' do
      expect { described_class.new(prerel_values.merge(is_prerelease: :false)) }.not_to raise_error
      expect(described_class.new(prerel_values.merge(is_prerelease: :false))[:is_prerelease]).to be :false
    end

    specify 'should accept "false" for yum repos' do
      expect { described_class.new(prerel_values.merge(is_prerelease: 'false')) }.not_to raise_error
      expect(described_class.new(prerel_values.merge(is_prerelease: 'false'))[:is_prerelease]).to be :false
    end
  end

  describe 'when removing' do
    it { expect { described_class.new(name: 'foo', ensure: :absent) }.not_to raise_error }
  end
end
