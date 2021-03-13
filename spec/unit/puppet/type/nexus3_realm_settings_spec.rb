require 'spec_helper'

describe Puppet::Type.type(:nexus3_realm_settings) do
  before :each do
    provider_class = described_class.provide(:simple) do
      mk_resource_methods

      def flush; end

      def self.instances
        []
      end
    end
    allow(described_class).to receive(:defaultprovider).and_return(provider_class)
  end

  describe 'names' do
    specify 'should accept a valid array of names' do
      expect { described_class.new(name: 'any', names: %w[name1 name2]) }.not_to raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(name: 'any', names: '')
      }.to raise_error(Puppet::ResourceError, %r{Parameter names failed})
    end

    specify 'should not accept a string as array' do
      expect {
        described_class.new(name: 'any', names: 'name1,name2')
      }.to raise_error(Puppet::ResourceError, %r{Parameter names failed})
    end
  end
end
