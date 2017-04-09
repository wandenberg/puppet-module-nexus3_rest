require 'spec_helper'

describe Puppet::Type.type(:nexus3_realm_settings) do
  subject { Puppet::Type.type(:nexus3_realm_settings) }

  before :each do
    provider_class = subject.provide(:simple) do
      mk_resource_methods
      def flush; end
      def self.instances; []; end
    end
    allow(subject).to receive(:defaultprovider).and_return(provider_class)
  end

  describe :names do
    specify 'should accept a valid array of names' do
      expect { subject.new(name: 'any', names: ['name1', 'name2']) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        subject.new(name: 'any', names: '')
      }.to raise_error(Puppet::ResourceError, /Parameter names failed/)
    end

    specify 'should not accept a string as array' do
      expect {
        subject.new(name: 'any', names: 'name1,name2')
      }.to raise_error(Puppet::ResourceError, /Parameter names failed/)
    end
  end
end
