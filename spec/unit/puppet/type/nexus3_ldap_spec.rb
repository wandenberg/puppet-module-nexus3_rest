require 'spec_helper'

describe Puppet::Type.type(:nexus3_ldap) do
  let(:required_values) do
    {
      name: 'foo',
      hostname: 'ldap.server.com',
      search_base: 'sch_base',
      ldap_groups_as_roles: false,
    }
  end

  describe 'by default' do
    let(:instance) { described_class.new(required_values) }

    it { expect(instance[:protocol]).to eq(:ldap) }
    it { expect(instance[:port]).to eq(389) }
    it { expect(instance[:max_incidents_count]).to eq(3) }
    it { expect(instance[:connection_retry_delay]).to eq(300) }
    it { expect(instance[:connection_timeout]).to eq(30) }
    it { expect(instance[:authentication_scheme]).to eq(:none) }
    it { expect(instance[:user_subtree]).to eq(:false) }
    # it { expect(instance[:ldap_groups_as_roles]).to eq(:true) }
    it { expect(instance[:group_subtree]).to eq(:false) }
  end

  it 'validate protocol' do
    expect {
      described_class.new(required_values.merge(protocol: 'invalid'))
    }.to raise_error(Puppet::Error, %r{Invalid value "invalid"})
  end

  it 'validate authentication_scheme' do
    expect {
      described_class.new(required_values.merge(authentication_scheme: 'invalid'))
    }.to raise_error(Puppet::Error, %r{Invalid value "invalid"})
  end

  describe 'hostname' do
    specify 'should accept a valid hostname' do
      expect { described_class.new(required_values.merge(hostname: 'smtp.example.com')) }.not_to raise_error
    end

    specify 'should accept a localhost' do
      expect { described_class.new(required_values.merge(hostname: 'localhost')) }.not_to raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(required_values.merge(hostname: ''))
      }.to raise_error(Puppet::ResourceError, %r{Parameter hostname failed})
    end
  end

  describe 'search_base' do
    specify 'should accept a valid search_base' do
      expect { described_class.new(required_values.merge(search_base: 'cn=example.com')) }.not_to raise_error
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(required_values.merge(search_base: ''))
      }.to raise_error(Puppet::ResourceError, %r{Parameter search_base failed})
    end
  end

  describe 'port' do
    specify 'should default to 25' do
      expect(described_class.new(required_values)[:port]).to be(389)
    end

    specify 'should not accept empty string' do
      expect {
        described_class.new(required_values.merge(port: ''))
      }.to raise_error(Puppet::ResourceError, %r{Parameter port failed})
    end

    specify 'should not accept characters' do
      expect {
        described_class.new(required_values.merge(port: 'abc'))
      }.to raise_error(Puppet::ResourceError, %r{Parameter port failed})
    end

    specify 'should not accept port 0' do
      expect {
        described_class.new(required_values.merge(port: 0))
      }.to raise_error(Puppet::ResourceError, %r{Parameter port failed})
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
      }.to raise_error(Puppet::ResourceError, %r{Parameter port failed})
    end
  end

  describe 'user_subtree' do
    specify 'should default to false' do
      expect(described_class.new(required_values)[:user_subtree]).to be :false
    end

    specify 'should accept :true' do
      expect { described_class.new(required_values.merge(user_subtree: :true)) }.not_to raise_error
      expect(described_class.new(required_values.merge(user_subtree: :true))[:user_subtree]).to be :true
    end

    specify 'should accept "true' do
      expect { described_class.new(required_values.merge(user_subtree: 'true')) }.not_to raise_error
      expect(described_class.new(required_values.merge(user_subtree: 'true'))[:user_subtree]).to be :true
    end

    specify 'should accept :false' do
      expect { described_class.new(required_values.merge(user_subtree: :false)) }.not_to raise_error
      expect(described_class.new(required_values.merge(user_subtree: :false))[:user_subtree]).to be :false
    end

    specify 'should accept "false"' do
      expect { described_class.new(required_values.merge(user_subtree: 'false')) }.not_to raise_error
      expect(described_class.new(required_values.merge(user_subtree: 'false'))[:user_subtree]).to be :false
    end
  end

  describe 'group_subtree' do
    specify 'should default to false' do
      expect(described_class.new(required_values)[:group_subtree]).to be :false
    end

    specify 'should accept :true' do
      expect { described_class.new(required_values.merge(group_subtree: :true)) }.not_to raise_error
      expect(described_class.new(required_values.merge(group_subtree: :true))[:group_subtree]).to be :true
    end

    specify 'should accept "true' do
      expect { described_class.new(required_values.merge(group_subtree: 'true')) }.not_to raise_error
      expect(described_class.new(required_values.merge(group_subtree: 'true'))[:group_subtree]).to be :true
    end

    specify 'should accept :false' do
      expect { described_class.new(required_values.merge(group_subtree: :false)) }.not_to raise_error
      expect(described_class.new(required_values.merge(group_subtree: :false))[:group_subtree]).to be :false
    end

    specify 'should accept "false"' do
      expect { described_class.new(required_values.merge(group_subtree: 'false')) }.not_to raise_error
      expect(described_class.new(required_values.merge(group_subtree: 'false'))[:group_subtree]).to be :false
    end
  end

  describe 'ldap_groups_as_roles' do
    let(:required_values) do
      {
        name: 'foo',
        hostname: 'ldap.server.com',
        search_base: 'sch_base',
        group_base_dn: 'group_base_dn',
        group_object_class: 'group_object_class',
        group_id_attribute: 'group_id_attribute',
        group_member_attribute: 'group_member_attribute',
        group_member_format: 'group_member_format',
      }
    end

    specify 'should default to true' do
      expect(described_class.new(required_values)[:ldap_groups_as_roles]).to be :true
    end

    specify 'should accept :true' do
      expect { described_class.new(required_values.merge(ldap_groups_as_roles: :true)) }.not_to raise_error
      expect(described_class.new(required_values.merge(ldap_groups_as_roles: :true))[:ldap_groups_as_roles]).to be :true
    end

    specify 'should accept "true' do
      expect { described_class.new(required_values.merge(ldap_groups_as_roles: 'true')) }.not_to raise_error
      expect(described_class.new(required_values.merge(ldap_groups_as_roles: 'true'))[:ldap_groups_as_roles]).to be :true
    end

    specify 'should accept :false' do
      expect { described_class.new(required_values.merge(ldap_groups_as_roles: :false)) }.not_to raise_error
      expect(described_class.new(required_values.merge(ldap_groups_as_roles: :false))[:ldap_groups_as_roles]).to be :false
    end

    specify 'should accept "false"' do
      expect { described_class.new(required_values.merge(ldap_groups_as_roles: 'false')) }.not_to raise_error
      expect(described_class.new(required_values.merge(ldap_groups_as_roles: 'false'))[:ldap_groups_as_roles]).to be :false
    end

    specify 'should not accept empty string as group_base_dn' do
      expect {
        described_class.new(required_values.merge(ldap_groups_as_roles: true, group_base_dn: ''))
      }.to raise_error(Puppet::ResourceError, %r{group_base_dn must not be empty when using ldap_groups_as_roles})
    end

    specify 'should not accept empty string as group_object_class' do
      expect {
        described_class.new(required_values.merge(ldap_groups_as_roles: true, group_object_class: ''))
      }.to raise_error(Puppet::ResourceError, %r{group_object_class must not be empty when using ldap_groups_as_roles})
    end

    specify 'should not accept empty string as group_id_attribute' do
      expect {
        described_class.new(required_values.merge(ldap_groups_as_roles: true, group_id_attribute: ''))
      }.to raise_error(Puppet::ResourceError, %r{group_id_attribute must not be empty when using ldap_groups_as_roles})
    end

    specify 'should not accept empty string as group_member_attribute' do
      expect {
        described_class.new(required_values.merge(ldap_groups_as_roles: true, group_member_attribute: ''))
      }.to raise_error(Puppet::ResourceError, %r{group_member_attribute must not be empty when using ldap_groups_as_roles})
    end

    specify 'should not accept empty string as group_member_format' do
      expect {
        described_class.new(required_values.merge(ldap_groups_as_roles: true, group_member_format: ''))
      }.to raise_error(Puppet::ResourceError, %r{group_member_format must not be empty when using ldap_groups_as_roles})
    end
  end

  describe 'when removing' do
    it { expect { described_class.new(name: 'any', ensure: :absent) }.not_to raise_error }
  end
end
