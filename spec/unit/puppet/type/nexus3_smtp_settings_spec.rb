require 'spec_helper'

describe Puppet::Type.type(:nexus3_smtp_settings) do
  subject { Puppet::Type.type(:nexus3_smtp_settings) }

  let(:required_values) do
    {
      name: 'example',
      hostname: 'smtp.server.com',
    }
  end

  before :each do
    provider_class = subject.provide(:simple) do
      mk_resource_methods
      def flush; end
      def self.instances; []; end
    end
    allow(subject).to receive(:defaultprovider).and_return(provider_class)
  end

  describe :hostname do
    specify 'should accept a valid hostname' do
      expect { subject.new(required_values.merge(hostname: 'smtp.example.com')) }.to_not raise_error
    end

    specify 'should accept a localhost' do
      expect { subject.new(required_values.merge(hostname: 'localhost')) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        subject.new(required_values.merge(hostname: ''))
      }.to raise_error(Puppet::ResourceError, /Parameter hostname failed/)
    end
  end

  describe :port do
    specify 'should default to 25' do
      expect(subject.new(required_values)[:port]).to be(25)
    end

    specify 'should not accept empty string' do
      expect {
        subject.new(required_values.merge(port: ''))
      }.to raise_error(Puppet::ResourceError, /Parameter port failed/)
    end

    specify 'should not accept characters' do
      expect {
        subject.new(required_values.merge(port: 'abc'))
      }.to raise_error(Puppet::ResourceError, /Parameter port failed/)
    end

    specify 'should not accept port 0' do
      expect {
        subject.new(required_values.merge(port: 0))
      }.to raise_error(Puppet::ResourceError, /Parameter port failed/)
    end

    specify 'should accept port 1' do
      expect { subject.new(required_values.merge(port: 1)) }.to_not raise_error
    end

    specify 'should accept port as string' do
      expect { subject.new(required_values.merge(port: '25')) }.to_not raise_error
    end

    specify 'should accept port 65535' do
      expect { subject.new(required_values.merge(port:  65535)) }.to_not raise_error
    end

    specify 'should not accept ports larger than 65535' do
      expect {
        subject.new(required_values.merge(port:  65536))
      }.to raise_error(Puppet::ResourceError, /Parameter port failed/)
    end
  end

  describe :enabled do
    specify 'should default to false' do
      expect(subject.new(required_values)[:enabled]).to be :false
    end

    specify 'should accept :true' do
      expect { subject.new(required_values.merge(enabled: :true)) }.to_not raise_error
      expect(subject.new(required_values.merge(enabled: :true))[:enabled]).to be :true
    end

    specify 'should accept "true' do
      expect { subject.new(required_values.merge(enabled: 'true')) }.to_not raise_error
      expect(subject.new(required_values.merge(enabled: 'true'))[:enabled]).to be :true
    end

    specify 'should accept :false' do
      expect { subject.new(required_values.merge(enabled: :false)) }.to_not raise_error
      expect(subject.new(required_values.merge(enabled: :false))[:enabled]).to be :false
    end

    specify 'should accept "false"' do
      expect { subject.new(required_values.merge(enabled: 'false')) }.to_not raise_error
      expect(subject.new(required_values.merge(enabled: 'false'))[:enabled]).to be :false
    end
  end
  
  describe :username do
    specify 'should default to empty string' do
      expect(subject.new(required_values)[:username]).to eq nil
    end

    specify 'should accept empty string' do
      expect { subject.new(required_values.merge(username: '')) }.to_not raise_error
    end

    specify 'should accept valid username' do
      expect { subject.new(required_values.merge(username: 'jdoe')) }.to_not raise_error
    end
  end

  describe :password do
    specify 'should default to nil' do
      expect(subject.new(required_values)[:password]).to eq nil
    end

    specify 'should accept empty string' do
      expect { subject.new(required_values.merge(password: '')) }.to_not raise_error
    end

    specify 'should accept valid value' do
      expect { subject.new(required_values.merge(password: 'secret')) }.to_not raise_error
    end
  end

  describe :sender_email do
    specify 'should accept valid email address' do
      expect { subject.new(required_values.merge(sender_email: 'jdoe@example.com')) }.to_not raise_error
    end

    specify 'should not accept empty email address' do
      expect {
        subject.new(required_values.merge(sender_email: ''))
      }.to raise_error(Puppet::ResourceError, /Parameter sender_email failed/)
    end

    specify 'should not accept invalid email address' do
      expect {
        subject.new(required_values.merge(sender_email: 'invalid'))
      }.to raise_error(Puppet::ResourceError, /Parameter sender_email failed/)
    end
  end

  describe :subject_prefix do
    specify 'should default to nil' do
      expect(subject.new(required_values)[:subject_prefix]).to eq nil
    end

    specify 'should accept empty string' do
      expect { subject.new(required_values.merge(subject_prefix: '')) }.to_not raise_error
    end

    specify 'should accept valid value' do
      expect { subject.new(required_values.merge(subject_prefix: 'prefix')) }.to_not raise_error
    end
  end
end
