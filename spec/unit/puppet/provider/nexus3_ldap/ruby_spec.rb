require 'spec_helper'

type_class = Puppet::Type.type(:nexus3_ldap)

describe type_class.provider(:ruby) do
  before(:each) { stub_default_config_and_healthcheck }

  let(:values) do
    {
      id: 'internal_id',
      name: 'foo',
      hostname: 'ldap.server.com',
      search_base: 'sch_base',
      order: 1,
      protocol: 'ldap',
      port: 1234,
      max_incidents_count: 5,
      connection_retry_delay: 65,
      connection_timeout: 78,
      sasl_realm: 'sasl_realm',
      authentication_scheme: 'none',
      username: 'username',
      password: 'password',
      user_base_dn: 'user_base_dn',
      user_email_attribute: 'user_email_attribute',
      user_id_attribute: 'user_id_attribute',
      user_object_class: 'user_object_class',
      user_password_attribute: 'user_password_attribute',
      user_real_name_attribute: 'user_real_name_attribute',
      user_subtree: true,
      user_member_of_attribute: 'user_member_of_attribute',
      group_base_dn: 'group_base_dn',
      group_id_attribute: 'group_id_attribute',
      group_member_attribute: 'group_member_attribute',
      group_member_format: 'group_member_format',
      group_object_class: 'group_object_class',
      group_subtree: false,
      ldap_filter: 'ldap_filter',
      ldap_groups_as_roles: false,
    }
  end

  let(:resource_extra_attributes) do
    {}
  end

  let(:instance) do
    resource = type_class.new(values.merge(name: 'example').merge(resource_extra_attributes))
    instance = described_class.new(values.merge(name: 'example').merge(resource_extra_attributes))
    resource.provider = instance
    instance
  end

  describe 'define getters and setters to each type properties or params' do
    let(:instance) { described_class.new }

    [:id, :order, :protocol, :hostname, :port, :search_base, :max_incidents_count, :connection_retry_delay,
     :connection_timeout, :authentication_scheme, :username, :password, :sasl_realm, :user_base_dn, :user_subtree,
     :user_object_class, :ldap_filter, :user_id_attribute, :user_real_name_attribute, :user_email_attribute,
     :user_password_attribute, :user_member_of_attribute, :ldap_groups_as_roles, :group_base_dn, :group_subtree,
     :group_object_class, :group_id_attribute, :group_member_attribute, :group_member_format].each do |method|
      specify { expect(instance.respond_to?(method)).to be_truthy }
      specify { expect(instance.respond_to?("#{method}=")).to be_truthy }
    end
  end

  describe 'prefetch' do
    it 'not raise error if more than one resource of this type is configured' do
      allow(Nexus3::API).to receive(:execute_script).and_return('[]')

      expect {
        described_class.prefetch({ example1: type_class.new(values.merge(name: 'example1')), example2: type_class.new(values.merge(name: 'example2')) })
      }.not_to raise_error
    end

    describe 'found instance' do
      before(:each) { allow(Nexus3::API).to receive(:execute_script).and_return([{ name: 'example1', hostname: 'from_service' }].to_json) }

      it 'not set the provider' do
        resources = { example1: type_class.new(values.merge(name: 'example1')) }
        described_class.prefetch(resources)
        expect(resources[:example1].provider.hostname).to eq('from_service')
        expect(resources[:example1][:hostname]).to eq('ldap.server.com')
      end
    end

    describe 'not found instance' do
      before(:each) { allow(Nexus3::API).to receive(:execute_script).and_return('[]') }

      it 'not set the provider' do
        resources = { example1: type_class.new(values.merge(name: 'example1')) }
        described_class.prefetch(resources)
        expect(resources[:example1].provider.hostname).to eq(:absent)
        expect(resources[:example1][:hostname]).to eq('ldap.server.com')
      end
    end
  end

  describe 'instances' do
    specify 'should execute a script to get repositories settings' do
      script = <<~EOS
        def ldapConfigurationManager = container.lookup(org.sonatype.nexus.ldap.persist.LdapConfigurationManager.class.name)
        def ldapConfigurations = ldapConfigurationManager.listLdapServerConfigurations()

        def infos = ldapConfigurations.collect { ldapConfiguration ->
          def connection = ldapConfiguration.getConnection()
          def host = connection.getHost()
          def mapping = ldapConfiguration.getMapping()
          [
            name: ldapConfiguration.getName(),
            id: ldapConfiguration.getId(),
            order: ldapConfiguration.getOrder(),
            protocol: host.getProtocol(),
            hostname: host.getHostName(),
            port: host.getPort(),
            search_base: connection.getSearchBase(),
            max_incidents_count: connection.getMaxIncidentsCount(),
            connection_retry_delay: connection.getConnectionRetryDelay(),
            connection_timeout: connection.getConnectionTimeout(),
            sasl_realm: connection.getSaslRealm(),

            authentication_scheme: connection.getAuthScheme(),
            username: connection.getSystemUsername(),
            password: connection.getSystemPassword(),

            user_base_dn: mapping.getUserBaseDn(),
            user_email_attribute: mapping.getEmailAddressAttribute(),
            user_id_attribute: mapping.getUserIdAttribute(),
            user_object_class: mapping.getUserObjectClass(),
            user_password_attribute: mapping.getUserPasswordAttribute(),
            user_real_name_attribute: mapping.getUserRealNameAttribute(),
            user_subtree: mapping.isUserSubtree(),
            user_member_of_attribute: mapping.getUserMemberOfAttribute(),

            group_base_dn: mapping.getGroupBaseDn(),
            group_id_attribute: mapping.getGroupIdAttribute(),
            group_member_attribute: mapping.getGroupMemberAttribute(),
            group_member_format: mapping.getGroupMemberFormat(),
            group_object_class: mapping.getGroupObjectClass(),
            group_subtree: mapping.isGroupSubtree(),

            ldap_filter: mapping.getLdapFilter(),
            ldap_groups_as_roles: mapping.isLdapGroupsAsRoles(),
          ]
        }
        return groovy.json.JsonOutput.toJson(infos)
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script).and_return('[{}]')
      described_class.instances
    end

    specify 'should use default values to non set properties' do
      allow(Nexus3::API).to receive(:execute_script).and_return('[{}]')
      instances = described_class.instances
      expect(instances.length).to eq 1
      expect(instances[0].id).to eq('')
      expect(instances[0].order).to eq('')
      expect(instances[0].protocol).to eq('')
      expect(instances[0].hostname).to eq('')
      expect(instances[0].port).to eq('')
      expect(instances[0].search_base).to eq('')
      expect(instances[0].max_incidents_count).to eq('')
      expect(instances[0].connection_retry_delay).to eq('')
      expect(instances[0].connection_timeout).to eq('')
      expect(instances[0].sasl_realm).to eq('')
      expect(instances[0].authentication_scheme).to eq('')
      expect(instances[0].username).to eq('')
      expect(instances[0].password).to eq('')
      expect(instances[0].user_base_dn).to eq('')
      expect(instances[0].user_email_attribute).to eq('')
      expect(instances[0].user_id_attribute).to eq('')
      expect(instances[0].user_object_class).to eq('')
      expect(instances[0].user_password_attribute).to eq('')
      expect(instances[0].user_real_name_attribute).to eq('')
      expect(instances[0].user_subtree).to eq('')
      expect(instances[0].user_member_of_attribute).to eq('')
      expect(instances[0].group_base_dn).to eq('')
      expect(instances[0].group_id_attribute).to eq('')
      expect(instances[0].group_member_attribute).to eq('')
      expect(instances[0].group_member_format).to eq('')
      expect(instances[0].group_object_class).to eq('')
      expect(instances[0].group_subtree).to eq('')
      expect(instances[0].ldap_filter).to eq('')
      expect(instances[0].ldap_groups_as_roles).to eq('')
    end

    specify 'should map each returned values to the correspondent property' do
      allow(Nexus3::API).to receive(:execute_script).and_return([values].to_json)
      instances = described_class.instances
      expect(instances.length).to eq 1
      expect(instances[0].id).to eq('internal_id')
      expect(instances[0].order).to eq 1
      expect(instances[0].protocol).to eq('ldap')
      expect(instances[0].hostname).to eq('ldap.server.com')
      expect(instances[0].port).to eq 1234
      expect(instances[0].search_base).to eq('sch_base')
      expect(instances[0].max_incidents_count).to eq 5
      expect(instances[0].connection_retry_delay).to eq 65
      expect(instances[0].connection_timeout).to eq 78
      expect(instances[0].sasl_realm).to eq('sasl_realm')
      expect(instances[0].authentication_scheme).to eq('none')
      expect(instances[0].username).to eq('username')
      expect(instances[0].password).to eq('password')
      expect(instances[0].user_base_dn).to eq('user_base_dn')
      expect(instances[0].user_email_attribute).to eq('user_email_attribute')
      expect(instances[0].user_id_attribute).to eq('user_id_attribute')
      expect(instances[0].user_object_class).to eq('user_object_class')
      expect(instances[0].user_password_attribute).to eq('user_password_attribute')
      expect(instances[0].user_real_name_attribute).to eq('user_real_name_attribute')
      expect(instances[0].user_subtree).to eq(:true)
      expect(instances[0].user_member_of_attribute).to eq('user_member_of_attribute')
      expect(instances[0].group_base_dn).to eq('group_base_dn')
      expect(instances[0].group_id_attribute).to eq('group_id_attribute')
      expect(instances[0].group_member_attribute).to eq('group_member_attribute')
      expect(instances[0].group_member_format).to eq('group_member_format')
      expect(instances[0].group_object_class).to eq('group_object_class')
      expect(instances[0].group_subtree).to eq(:false)
      expect(instances[0].ldap_filter).to eq('ldap_filter')
      expect(instances[0].ldap_groups_as_roles).to eq(:false)
    end
  end

  describe 'create' do
    it 'execute a script to create the instance' do
      script = <<~EOS
        def ldapConfigurationManager = container.lookup(org.sonatype.nexus.ldap.persist.LdapConfigurationManager.class.name)

        def ldapConfiguration = new org.sonatype.nexus.ldap.persist.entity.LdapConfiguration()

        ldapConfiguration.setName('example')
        ldapConfiguration.setOrder(1)

        def connection = new org.sonatype.nexus.ldap.persist.entity.Connection()
        connection.setSearchBase('sch_base')
        connection.setMaxIncidentsCount(5)
        connection.setConnectionRetryDelay(65)
        connection.setConnectionTimeout(78)
        connection.setSaslRealm('sasl_realm')
        connection.setAuthScheme('none')
        connection.setSystemUsername('username')
        connection.setSystemPassword('password')

        ldapConfiguration.setConnection(connection)

        def host = new org.sonatype.nexus.ldap.persist.entity.Connection.Host()
        host.setProtocol(org.sonatype.nexus.ldap.persist.entity.Connection.Protocol.ldap)
        host.setHostName('ldap.server.com')
        host.setPort(1234)

        connection.setHost(host)

        def mapping = new org.sonatype.nexus.ldap.persist.entity.Mapping()
        mapping.setUserBaseDn('user_base_dn')
        mapping.setEmailAddressAttribute('user_email_attribute')
        mapping.setUserIdAttribute('user_id_attribute')
        mapping.setUserObjectClass('user_object_class')
        mapping.setUserPasswordAttribute('user_password_attribute')
        mapping.setUserRealNameAttribute('user_real_name_attribute')
        mapping.setUserSubtree(true)
        mapping.setUserMemberOfAttribute('user_member_of_attribute')
        mapping.setGroupBaseDn('group_base_dn')
        mapping.setGroupIdAttribute('group_id_attribute')
        mapping.setGroupMemberAttribute('group_member_attribute')
        mapping.setGroupMemberFormat('group_member_format')
        mapping.setGroupObjectClass('group_object_class')
        mapping.setGroupSubtree(false)
        mapping.setLdapFilter('ldap_filter')
        mapping.setLdapGroupsAsRoles(false)

        ldapConfiguration.setMapping(mapping)

        ldapConfigurationManager.addLdapServerConfiguration(ldapConfiguration)
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script)
      instance.create
    end

    it 'raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      expect { instance.create }.to raise_error(Puppet::Error, %r{Error while creating nexus3_ldap example})
    end
  end

  describe 'flush' do
    it 'execute a script to update the instance' do
      script = <<~EOS
        def ldapConfigurationManager = container.lookup(org.sonatype.nexus.ldap.persist.LdapConfigurationManager.class.name)

        def ldapConfiguration = ldapConfigurationManager.getLdapServerConfiguration('internal_id')
        ldapConfiguration.setOrder(1)

        def connection = ldapConfiguration.getConnection()
        connection.setSearchBase('sch_base')
        connection.setMaxIncidentsCount(5)
        connection.setConnectionRetryDelay(65)
        connection.setConnectionTimeout(78)
        connection.setSaslRealm('sasl_realm')
        connection.setAuthScheme('none')
        connection.setSystemUsername('username')
        connection.setSystemPassword('password')

        def host = connection.getHost()
        host.setProtocol(org.sonatype.nexus.ldap.persist.entity.Connection.Protocol.ldap)
        host.setHostName('ldap.server.com')
        host.setPort(1234)

        def mapping = ldapConfiguration.getMapping()
        mapping.setUserBaseDn('user_base_dn')
        mapping.setEmailAddressAttribute('user_email_attribute')
        mapping.setUserIdAttribute('user_id_attribute')
        mapping.setUserObjectClass('user_object_class')
        mapping.setUserPasswordAttribute('user_password_attribute')
        mapping.setUserRealNameAttribute('user_real_name_attribute')
        mapping.setUserSubtree(true)
        mapping.setUserMemberOfAttribute('user_member_of_attribute')
        mapping.setGroupBaseDn('group_base_dn')
        mapping.setGroupIdAttribute('group_id_attribute')
        mapping.setGroupMemberAttribute('group_member_attribute')
        mapping.setGroupMemberFormat('group_member_format')
        mapping.setGroupObjectClass('group_object_class')
        mapping.setGroupSubtree(false)
        mapping.setLdapFilter('ldap_filter')
        mapping.setLdapGroupsAsRoles(false)

        ldapConfigurationManager.updateLdapServerConfiguration(ldapConfiguration)
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script)
      instance.mark_config_dirty
      instance.flush
    end

    it 'raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      instance.mark_config_dirty
      expect { instance.flush }.to raise_error(Puppet::Error, %r{Error while updating nexus3_ldap example})
    end

    it 'not allow changes on id' do
      expect { instance.id = 'other_id' }.to raise_error(Puppet::Error, %r{id is write-once only and cannot be changed.})
    end

    describe 'when some value has changed' do
      before(:each) { instance.hostname = 'Xpto1' }

      specify { expect(instance.instance_variable_get(:@update_required)).to be_truthy }
    end
  end

  describe 'destroy' do
    it 'execute a script to destroy the instance' do
      script = <<~EOS
        def ldapConfigurationManager = container.lookup(org.sonatype.nexus.ldap.persist.LdapConfigurationManager.class.name)
        ldapConfigurationManager.deleteLdapServerConfiguration('internal_id')
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script)
      instance.destroy
    end

    it 'raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      expect { instance.destroy }.to raise_error(Puppet::Error, %r{Error while deleting nexus3_ldap example})
    end
  end

  it 'return false if it is not existing' do
    # the dummy example isn't returned by self.instances
    expect(instance.exists?).to be_falsey
  end
end
