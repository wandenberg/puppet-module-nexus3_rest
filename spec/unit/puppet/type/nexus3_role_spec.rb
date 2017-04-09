require 'spec_helper'

describe Puppet::Type.type(:nexus3_role) do
  subject { Puppet::Type.type(:nexus3_role) }

  let(:required_values) do
    {
      name: 'default',
      role_name: 'New Role',
    }
  end
  
  describe 'by default' do
    let(:instance) { subject.new(required_values) }

    it { expect(instance[:read_only]).to eq(:false) }
    it { expect(instance[:roles]).to eql([]) }
    it { expect(instance[:privileges]).to eql([]) }
  end

  describe :read_only do
    specify 'should default to false' do
      expect(subject.new(required_values)[:read_only]).to be :false
    end

    specify 'should accept :true' do
      expect { subject.new(required_values.merge(read_only: :true)) }.to_not raise_error
      expect(subject.new(required_values.merge(read_only: :true))[:read_only]).to be :true
    end

    specify 'should accept "true' do
      expect { subject.new(required_values.merge(read_only: 'true')) }.to_not raise_error
      expect(subject.new(required_values.merge(read_only: 'true'))[:read_only]).to be :true
    end

    specify 'should accept :false' do
      expect { subject.new(required_values.merge(read_only: :false)) }.to_not raise_error
      expect(subject.new(required_values.merge(read_only: :false))[:read_only]).to be :false
    end

    specify 'should accept "false"' do
      expect { subject.new(required_values.merge(read_only: 'false')) }.to_not raise_error
      expect(subject.new(required_values.merge(read_only: 'false'))[:read_only]).to be :false
    end
  end

  describe :roles do
    specify 'should accept a valid array of roles' do
      expect { subject.new(required_values.merge(roles: ['repo-c', 'repo-d'])) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        subject.new(required_values.merge(roles: ''))
      }.to raise_error(Puppet::ResourceError, /Parameter roles failed/)
    end

    specify 'should not accept a string as array' do
      expect {
        subject.new(required_values.merge(roles: 'name1,name2'))
      }.to raise_error(Puppet::ResourceError, /Parameter roles failed/)
    end
  end
  
  describe :privileges do
    specify 'should accept a valid array of privileges' do
      expect { subject.new(required_values.merge(privileges: ['repo-c', 'repo-d'])) }.to_not raise_error
    end

    specify 'should not accept empty string' do
      expect {
        subject.new(required_values.merge(privileges: ''))
      }.to raise_error(Puppet::ResourceError, /Parameter privileges failed/)
    end

    specify 'should not accept a string as array' do
      expect {
        subject.new(required_values.merge(privileges: 'name1,name2'))
      }.to raise_error(Puppet::ResourceError, /Parameter privileges failed/)
    end
  end

  describe 'when removing' do
    it { expect { subject.new(name: 'any', ensure: :absent) }.to_not raise_error }
  end
end
