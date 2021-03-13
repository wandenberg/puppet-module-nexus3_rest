require 'spec_helper'

type_class = Puppet::Type.type(:nexus3_role)

describe type_class.provider(:ruby) do
  before(:each) { stub_default_config_and_healthcheck }

  let(:values) do
    {
      role_name: 'role',
      description: 'role description',
      source: 'source',
      read_only: true,
      roles: ['roleId1'],
      privileges: ['priv1'],
    }
  end

  let(:instance) do
    resource = type_class.new(values.merge(name: 'example'))
    instance = described_class.new(values.merge(name: 'example'))
    resource.provider = instance
    instance
  end

  describe 'define getters and setters to each type properties or params' do
    let(:instance) { described_class.new }

    [:role_name, :description, :read_only, :source, :roles, :privileges].each do |method|
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
      before(:each) { allow(Nexus3::API).to receive(:execute_script).and_return([{ name: 'example1', description: 'from_service' }].to_json) }

      it 'not set the provider' do
        resources = { example1: type_class.new(values.merge(name: 'example1')) }
        described_class.prefetch(resources)
        expect(resources[:example1].provider.description).to eq('from_service')
        expect(resources[:example1][:description]).to eq('role description')
      end
    end

    describe 'not found instance' do
      before(:each) { allow(Nexus3::API).to receive(:execute_script).and_return('[]') }

      it 'not set the provider' do
        resources = { example1: type_class.new(values.merge(name: 'example1')) }
        described_class.prefetch(resources)
        expect(resources[:example1].provider.description).to eq(:absent)
        expect(resources[:example1][:description]).to eq('role description')
      end
    end
  end

  describe 'instances' do
    specify 'should execute a script to get repositories settings' do
      script = <<~EOS
        def authorizationManager = container.lookup(org.sonatype.nexus.security.authz.AuthorizationManager.class.name)
        def roles = authorizationManager.listRoles()
        def infos = roles.collect { role ->
          [
            name: role.roleId,
            role_name: role.name,
            description: role.description,
            source: role.source,
            read_only: role.readOnly,
            roles: role.roles,
            privileges: role.privileges,
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
      expect(instances[0].role_name).to eq('')
      expect(instances[0].description).to eq('')
      expect(instances[0].source).to eq('')
      expect(instances[0].read_only).to eq('')
      expect(instances[0].roles).to eq('')
      expect(instances[0].privileges).to eq('')
    end

    specify 'should map each returned values to the correspondent property' do
      allow(Nexus3::API).to receive(:execute_script).and_return([values].to_json)
      instances = described_class.instances
      expect(instances.length).to eq 1
      expect(instances[0].role_name).to eq('role')
      expect(instances[0].description).to eq('role description')
      expect(instances[0].source).to eq('source')
      expect(instances[0].read_only).to eq(:true)
      expect(instances[0].roles).to eq(['roleId1'])
      expect(instances[0].privileges).to eq(['priv1'])
    end
  end

  describe 'create' do
    it 'execute a script to create the instance' do
      script = <<~EOS
        def authorizationManager = container.lookup(org.sonatype.nexus.security.authz.AuthorizationManager.class.name)
        def role = new org.sonatype.nexus.security.role.Role()

        role.roleId = 'example'
        role.name = 'role'
        role.description = 'role description'
        role.source = 'source'
        role.readOnly = true
        role.setRoles(new HashSet(["roleId1"]))
        role.setPrivileges(new HashSet(["priv1"]))

        authorizationManager.addRole(role)
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
      instance.create
    end

    it 'raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      expect { instance.create }.to raise_error(Puppet::Error, %r{Error while creating nexus3_role example})
    end
  end

  describe 'flush' do
    it 'execute a script to update the instance' do
      script = <<~EOS
        def authorizationManager = container.lookup(org.sonatype.nexus.security.authz.AuthorizationManager.class.name)
        def role = authorizationManager.getRole('example')

        role.name = 'role'
        role.description = 'role description'
        role.source = 'source'
        role.readOnly = true
        role.setRoles(new HashSet(["roleId1"]))
        role.setPrivileges(new HashSet(["priv1"]))

        authorizationManager.updateRole(role)
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
      instance.mark_config_dirty
      instance.flush
    end

    it 'raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      instance.mark_config_dirty
      expect { instance.flush }.to raise_error(Puppet::Error, %r{Error while updating nexus3_role example})
    end

    describe 'when some value has changed' do
      before(:each) { instance.roles = %w[name1 name3] }

      specify { expect(instance.instance_variable_get(:@update_required)).to be_truthy }
    end
  end

  describe 'destroy' do
    it 'execute a script to destroy the instance' do
      script = <<~EOS
        def authorizationManager = container.lookup(org.sonatype.nexus.security.authz.AuthorizationManager.class.name)
        authorizationManager.deleteRole('example')
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
      instance.destroy
    end

    it 'raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      expect { instance.destroy }.to raise_error(Puppet::Error, %r{Error while deleting nexus3_role example})
    end
  end

  it 'return false if it is not existing' do
    # the dummy example isn't returned by self.instances
    expect(instance.exists?).to be_falsey
  end
end
