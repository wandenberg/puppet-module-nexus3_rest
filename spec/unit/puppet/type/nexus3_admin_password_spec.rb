require 'spec_helper'

describe 'nexus3_admin_password' do
  subject { Puppet::Type.type(:nexus3_admin_password) }
  
  before :each do
    provider_class = subject.provide(:simple) do
      mk_resource_methods
      def flush; end
      def self.instances; []; end
    end
    allow(subject).to receive(:defaultprovider).and_return(provider_class)
  end

  describe :password do
    specify 'should default to nil' do
      expect(subject.new(name: 'any')[:password]).to eq nil
    end

    specify 'should not accept empty string' do
      expect { subject.new(name: 'any', password: '') }.to raise_error(Puppet::ResourceError, 'Parameter password failed on Nexus3_admin_password[any]: password must be provided.')
    end

    specify 'should accept valid value' do
      expect { subject.new(name: 'any', password: 'secret') }.not_to raise_error
    end
  end

  describe :old_password do
    specify 'should default to nil' do
      expect(subject.new(name: 'any')[:old_password]).to eq nil
    end

    specify 'should not accept empty string' do
      expect { subject.new(name: 'any', old_password: '') }.to raise_error(Puppet::ResourceError, 'Parameter old_password failed on Nexus3_admin_password[any]: old_password must be provided.')
    end

    specify 'should accept valid value' do
      expect { subject.new(name: 'any', old_password: 'secret') }.not_to raise_error
    end
  end

end
