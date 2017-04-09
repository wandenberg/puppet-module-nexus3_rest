require 'spec_helper'

describe Puppet::Type.type(:nexus3_anonymous_settings) do
  subject { Puppet::Type.type(:nexus3_anonymous_settings) }

  before :each do
    provider_class = subject.provide(:simple) do
      mk_resource_methods
      def flush; end
      def self.instances; []; end
    end
    allow(subject).to receive(:defaultprovider).and_return(provider_class)
  end

  describe :username do
    specify 'should default to empty string' do
      expect(subject.new(name: 'any')[:username]).to eq nil
    end

    specify 'should accept empty string' do
      expect { subject.new(name: 'any', username: '') }.to_not raise_error
    end

    specify 'should accept valid username' do
      expect { subject.new(name: 'any', username: 'jdoe') }.to_not raise_error
    end
  end

  describe :realm do
    specify 'should default to empty string' do
      expect(subject.new(name: 'any')[:realm]).to eq nil
    end

    specify 'should accept empty string' do
      expect { subject.new(name: 'any', realm: '') }.to_not raise_error
    end

    specify 'should accept valid realm' do
      expect { subject.new(name: 'any', realm: 'jdoe') }.to_not raise_error
    end
  end

  describe :enabled do
    specify 'should default to false' do
      expect(subject.new(name: 'any')[:enabled]).to be :false
    end

    specify 'should accept :true' do
      expect { subject.new(name: 'any', enabled: :true) }.to_not raise_error
      expect(subject.new(name: 'any', enabled: :true)[:enabled]).to be :true
    end

    specify 'should accept "true' do
      expect { subject.new(name: 'any', enabled: 'true') }.to_not raise_error
      expect(subject.new(name: 'any', enabled: 'true')[:enabled]).to be :true
    end

    specify 'should accept :false' do
      expect { subject.new(name: 'any', enabled: :false) }.to_not raise_error
      expect(subject.new(name: 'any', enabled: :false)[:enabled]).to be :false
    end

    specify 'should accept "false"' do
      expect { subject.new(name: 'any', enabled: 'false') }.to_not raise_error
      expect(subject.new(name: 'any', enabled: 'false')[:enabled]).to be :false
    end
  end
end
