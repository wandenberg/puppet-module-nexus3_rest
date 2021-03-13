require 'spec_helper'

describe Puppet::Type.type(:nexus3_anonymous_settings) do
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

  describe 'username' do
    specify 'should default to empty string' do
      expect(described_class.new(name: 'any')[:username]).to eq nil
    end

    specify 'should accept empty string' do
      expect { described_class.new(name: 'any', username: '') }.not_to raise_error
    end

    specify 'should accept valid username' do
      expect { described_class.new(name: 'any', username: 'jdoe') }.not_to raise_error
    end
  end

  describe 'realm' do
    specify 'should default to empty string' do
      expect(described_class.new(name: 'any')[:realm]).to eq nil
    end

    specify 'should accept empty string' do
      expect { described_class.new(name: 'any', realm: '') }.not_to raise_error
    end

    specify 'should accept valid realm' do
      expect { described_class.new(name: 'any', realm: 'jdoe') }.not_to raise_error
    end
  end

  describe 'enabled' do
    specify 'should default to false' do
      expect(described_class.new(name: 'any')[:enabled]).to be :false
    end

    specify 'should accept :true' do
      expect { described_class.new(name: 'any', enabled: :true) }.not_to raise_error
      expect(described_class.new(name: 'any', enabled: :true)[:enabled]).to be :true
    end

    specify 'should accept "true' do
      expect { described_class.new(name: 'any', enabled: 'true') }.not_to raise_error
      expect(described_class.new(name: 'any', enabled: 'true')[:enabled]).to be :true
    end

    specify 'should accept :false' do
      expect { described_class.new(name: 'any', enabled: :false) }.not_to raise_error
      expect(described_class.new(name: 'any', enabled: :false)[:enabled]).to be :false
    end

    specify 'should accept "false"' do
      expect { described_class.new(name: 'any', enabled: 'false') }.not_to raise_error
      expect(described_class.new(name: 'any', enabled: 'false')[:enabled]).to be :false
    end
  end
end
