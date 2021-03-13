require 'spec_helper'

describe Puppet::Type.type(:nexus3_user) do
  let(:required_values) do
    {
      name: 'foo',
      firstname: 'Foo',
      lastname: 'Bar',
      password: 'pass',
      email: 'foo@server.com',
      status: :disabled,
      roles: 'role-a',
    }
  end

  describe 'by default' do
    let(:instance) { described_class.new(required_values) }

    it { expect(instance[:read_only]).to eq(:false) }
  end

  specify 'should not accept empty string as firstname' do
    expect {
      described_class.new(required_values.merge(firstname: ''))
    }.to raise_error(Puppet::ResourceError, %r{Parameter firstname failed})
  end

  specify 'should not accept empty string as lastname' do
    expect {
      described_class.new(required_values.merge(lastname: ''))
    }.to raise_error(Puppet::ResourceError, %r{Parameter lastname failed})
  end

  it 'validate status' do
    expect {
      described_class.new(required_values.merge(status: 'invalid'))
    }.to raise_error(Puppet::Error, %r{Invalid value "invalid"})
  end

  describe 'read_only' do
    specify 'should default to false' do
      expect(described_class.new(required_values)[:read_only]).to be :false
    end

    specify 'should accept :true' do
      expect { described_class.new(required_values.merge(read_only: :true)) }.not_to raise_error
      expect(described_class.new(required_values.merge(read_only: :true))[:read_only]).to be :true
    end

    specify 'should accept "true' do
      expect { described_class.new(required_values.merge(read_only: 'true')) }.not_to raise_error
      expect(described_class.new(required_values.merge(read_only: 'true'))[:read_only]).to be :true
    end

    specify 'should accept :false' do
      expect { described_class.new(required_values.merge(read_only: :false)) }.not_to raise_error
      expect(described_class.new(required_values.merge(read_only: :false))[:read_only]).to be :false
    end

    specify 'should accept "false"' do
      expect { described_class.new(required_values.merge(read_only: 'false')) }.not_to raise_error
      expect(described_class.new(required_values.merge(read_only: 'false'))[:read_only]).to be :false
    end
  end

  describe 'email' do
    specify 'should accept valid email address' do
      expect { described_class.new(required_values.merge(email: 'jdoe@example.com')) }.not_to raise_error
    end

    specify 'should not accept empty email address' do
      expect {
        described_class.new(required_values.merge(email: ''))
      }.to raise_error(Puppet::ResourceError, %r{Parameter email failed})
    end

    specify 'should not accept invalid email address' do
      expect {
        described_class.new(required_values.merge(email: 'invalid'))
      }.to raise_error(Puppet::ResourceError, %r{Parameter email failed})
    end
  end

  describe 'roles' do
    specify 'should accept a valid array of roles' do
      expect { described_class.new(required_values.merge(roles: %w[role-c role-d])) }.not_to raise_error
    end

    specify 'should not have default value for roles' do
      expect {
        required_values.delete(:roles)
        described_class.new(required_values)
      }.to raise_error(Puppet::ResourceError, %r{roles must be provided as a non empty array})
    end

    specify 'should not accept an empty array' do
      expect {
        described_class.new(required_values.merge(roles: []))
      }.to raise_error(Puppet::ResourceError, %r{roles must be provided as a non empty array})
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(required_values.merge(roles: ''))
      }.to raise_error(Puppet::ResourceError, %r{Parameter roles failed})
    end

    specify 'should not accept a string as array' do
      expect {
        described_class.new(required_values.merge(roles: 'name1,name2'))
      }.to raise_error(Puppet::ResourceError, %r{Parameter roles failed})
    end
  end

  describe 'when removing' do
    it { expect { described_class.new(name: 'any', ensure: :absent) }.not_to raise_error }
  end
end
