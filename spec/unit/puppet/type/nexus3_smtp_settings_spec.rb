# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:nexus3_smtp_settings) do
  let(:required_values) do
    {
      name: 'example',
      host: 'smtp.server.com',
    }
  end

  describe 'host' do
    specify 'should accept a valid host' do
      expect { described_class.new(required_values.merge(host: 'smtp.example.com')) }.not_to raise_error
    end

    specify 'should accept a localhost' do
      expect { described_class.new(required_values.merge(host: 'localhost')) }.not_to raise_error
    end

    specify 'should use default value when empty string' do
      expect(described_class.new(required_values.merge(host: ''))[:host]).to be('localhost')
    end
  end

  describe 'port' do
    specify 'should default to 25' do
      expect(described_class.new(required_values)[:port]).to be(25)
    end

    specify 'should use default value when empty string' do
      expect(described_class.new(required_values.merge(port: ''))[:port]).to be(25)
    end

    specify 'should not accept characters' do
      expect {
        described_class.new(required_values.merge(port: 'abc'))
      }.to raise_error(ArgumentError, %r{Port must be within \[1, 65535\]})
    end

    specify 'should not accept port 0' do
      expect {
        described_class.new(required_values.merge(port: 0))
      }.to raise_error(ArgumentError, %r{Port must be within \[1, 65535\]})
    end

    specify 'should accept port 1' do
      expect { described_class.new(required_values.merge(port: 1)) }.not_to raise_error
    end

    specify 'should accept port as string' do
      expect { described_class.new(required_values.merge(port: '25')) }.not_to raise_error
    end

    specify 'should accept port 65535' do
      expect { described_class.new(required_values.merge(port: 65_535)) }.not_to raise_error
    end

    specify 'should not accept ports larger than 65535' do
      expect {
        described_class.new(required_values.merge(port: 65_536))
      }.to raise_error(ArgumentError, %r{Port must be within \[1, 65535\]})
    end
  end

  describe 'enabled' do
    specify 'should default to false' do
      expect(described_class.new(required_values)[:enabled]).to be :false
    end

    specify 'should accept :true' do
      expect { described_class.new(required_values.merge(enabled: :true)) }.not_to raise_error
      expect(described_class.new(required_values.merge(enabled: :true))[:enabled]).to be :true
    end

    specify 'should accept "true' do
      expect { described_class.new(required_values.merge(enabled: 'true')) }.not_to raise_error
      expect(described_class.new(required_values.merge(enabled: 'true'))[:enabled]).to be :true
    end

    specify 'should accept :false' do
      expect { described_class.new(required_values.merge(enabled: :false)) }.not_to raise_error
      expect(described_class.new(required_values.merge(enabled: :false))[:enabled]).to be :false
    end

    specify 'should accept "false"' do
      expect { described_class.new(required_values.merge(enabled: 'false')) }.not_to raise_error
      expect(described_class.new(required_values.merge(enabled: 'false'))[:enabled]).to be :false
    end
  end

  describe 'username' do
    specify 'should default to empty string' do
      expect(described_class.new(required_values)[:username]).to eq ''
    end

    specify 'should accept empty string' do
      expect { described_class.new(required_values.merge(username: '')) }.not_to raise_error
    end

    specify 'should accept valid username' do
      expect { described_class.new(required_values.merge(username: 'jdoe')) }.not_to raise_error
    end
  end

  describe 'password' do
    specify 'should default to nil' do
      expect(described_class.new(required_values)[:password]).to eq ''
    end

    specify 'should accept empty string' do
      expect { described_class.new(required_values.merge(password: '')) }.not_to raise_error
    end

    specify 'should accept valid value' do
      expect { described_class.new(required_values.merge(password: 'secret')) }.not_to raise_error
    end
  end

  describe 'from_address' do
    specify 'should accept valid email address' do
      expect { described_class.new(required_values.merge(from_address: 'jdoe@example.com')) }.not_to raise_error
    end

    specify 'should use default value when empty email address' do
      expect(described_class.new(required_values.merge(from_address: ''))[:from_address]).to be('nexus@example.org')
    end

    specify 'should not accept invalid email address' do
      expect {
        described_class.new(required_values.merge(from_address: 'invalid'))
      }.to raise_error(Puppet::ResourceError, %r{Parameter from_address failed})
    end
  end

  describe 'subject_prefix' do
    specify 'should default to nil' do
      expect(described_class.new(required_values)[:subject_prefix]).to eq ''
    end

    specify 'should accept empty string' do
      expect { described_class.new(required_values.merge(subject_prefix: '')) }.not_to raise_error
    end

    specify 'should accept valid value' do
      expect { described_class.new(required_values.merge(subject_prefix: 'prefix')) }.not_to raise_error
    end
  end
end
