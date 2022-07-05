require 'spec_helper'

describe Puppet::Type.type(:nexus3_realm_settings) do
  describe 'names' do
    specify 'should accept a valid array of names' do
      expect { described_class.new(name: 'any', names: %w[NpmToken ConanToken]) }.not_to raise_error
    end

    specify 'should not accept a non-supported name' do
      expect {
        described_class.new(name: 'any', names: %w[name1 NpmToken])
      }.to raise_error(Puppet::ResourceError, %r{Parameter names failed})
    end

    specify 'should use default when empty string' do
      expect(described_class.new(name: 'any', names: '')[:names]).to eq %w[NexusAuthenticatingRealm NexusAuthorizingRealm]
    end

    specify 'should not accept a string as array' do
      expect {
        described_class.new(name: 'any', names: 'name1,name2')
      }.to raise_error(Puppet::ResourceError, %r{Parameter names failed})
    end
  end
end
