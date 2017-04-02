require 'spec_helper'

type_class = Puppet::Type.type(:nexus3_user)

describe type_class.provider(:ruby) do
  before(:each) { stub_default_config_and_healthcheck }

  let(:values) do
    {
       name: 'foo',
       firstname: 'Foo',
       lastname: 'Bar',
       email: 'foo@server.com',
       roles: ['roleId1'],
       read_only: false,
       status: 'disabled',
    }
  end

  let(:resource_extra_attributes) do
    {}
  end

  let(:instance) do
    resource = type_class.new(values.merge(name: 'example', password: 'pass').merge(resource_extra_attributes))
    instance = described_class.new(values.merge(name: 'example', password: 'pass').merge(resource_extra_attributes))
    resource.provider = instance
    instance
  end

  describe 'define getters and setters to each type properties or params' do
    let(:instance) { described_class.new }

    [:firstname, :lastname, :password, :email, :read_only, :status, :roles].each do |method|
      specify { expect(instance.respond_to?(method)).to be_truthy }
      specify { expect(instance.respond_to?("#{method}=")).to be_truthy }
    end
  end

  describe 'prefetch' do
    it 'should not raise error if more than one resource of this type is configured' do
      allow(Nexus3::API).to receive(:execute_script).and_return('[]')

      expect {
        described_class.prefetch({example1: type_class.new(values.merge(name: 'example1')), example2: type_class.new(values.merge(name: 'example2'))})
      }.not_to raise_error
    end

    describe 'found instance' do
      before(:each) { allow(Nexus3::API).to receive(:execute_script).and_return([{name: 'example1', firstname: 'from_service'}].to_json) }

      it 'should not set the provider' do
        resources = {example1: type_class.new(values.merge(name: 'example1'))}
        described_class.prefetch(resources)
        expect(resources[:example1].provider.firstname).to eq('from_service')
        expect(resources[:example1][:firstname]).to eq('Foo')
      end
    end

    describe 'not found instance' do
      before(:each) { allow(Nexus3::API).to receive(:execute_script).and_return('[]') }

      it 'should not set the provider' do
        resources = {example1: type_class.new(values.merge(name: 'example1'))}
        described_class.prefetch(resources)
        expect(resources[:example1].provider.firstname).to eq(:absent)
        expect(resources[:example1][:firstname]).to eq('Foo')
      end
    end
  end

  describe 'instances' do
    specify 'should execute a script to get repositories settings' do
      script = <<~EOS
        def userManager = container.lookup(org.sonatype.nexus.security.user.ConfiguredUsersUserManager.class.name)
        def users = userManager.listUsers()
        def infos = users.collect { user ->
          [
            name : user.getUserId(),
            firstname : user.getFirstName(),
            lastname : user.getLastName(),
            email : user.getEmailAddress(),
            roles : user.getRoles().collect { role -> role.getRoleId() },
            read_only : user.isReadOnly(),
            status : user.getStatus(),
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
      expect(instances[0].firstname).to eq('')
      expect(instances[0].lastname).to eq('')
      expect(instances[0].email).to eq('')
      expect(instances[0].roles).to eq('')
      expect(instances[0].read_only).to eq('')
      expect(instances[0].status).to eq('')
    end

    specify 'should map each returned values to the correspondent property' do
      allow(Nexus3::API).to receive(:execute_script).and_return([values].to_json)
      instances = described_class.instances
      expect(instances.length).to eq 1
      expect(instances[0].firstname).to eq('Foo')
      expect(instances[0].lastname).to eq('Bar')
      expect(instances[0].email).to eq('foo@server.com')
      expect(instances[0].roles).to eql(['roleId1'])
      expect(instances[0].read_only).to eq(:false)
      expect(instances[0].status).to eq('disabled')
    end
  end

  describe 'create' do
    it 'should execute a script to create the instance' do
      script = <<~EOS
        def user = new org.sonatype.nexus.security.user.User()
        user.setUserId('example')
        user.setFirstName('Foo')
        user.setLastName('Bar')
        user.setEmailAddress('foo@server.com')
        user.setSource('default')
        user.setStatus(org.sonatype.nexus.security.user.UserStatus.disabled)
        user.setRoles(new HashSet(["roleId1"].collect { new org.sonatype.nexus.security.role.RoleIdentifier('default', it) }))
        security.securitySystem.addUser(user, 'pass')
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script)
      instance.create
    end

    it 'should raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      expect { instance.create }.to raise_error(Puppet::Error, /Error while creating nexus3_user example/)
    end
  end

  describe 'flush' do
    it 'should execute a script to update the instance' do
      script = <<~EOS
        def user = security.securitySystem.getUser('example')
        user.setFirstName('Foo')
        user.setLastName('Bar')
        user.setEmailAddress('foo@server.com')
        user.setSource('default')
        user.setStatus(org.sonatype.nexus.security.user.UserStatus.disabled)
        user.setRoles(new HashSet(["roleId1"].collect { new org.sonatype.nexus.security.role.RoleIdentifier('default', it) }))
        security.securitySystem.updateUser(user)
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script)
      instance.mark_config_dirty
      instance.flush
    end

    it 'should raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      instance.mark_config_dirty
      expect { instance.flush }.to raise_error(Puppet::Error, /Error while updating nexus3_user example/)
    end

    describe 'when some value has changed' do
      before(:each) { instance.firstname = 'Xpto' }

      specify { expect(instance.instance_variable_get(:@update_required)).to be_truthy }
    end
  end

  describe 'destroy' do
    it 'should execute a script to destroy the instance' do
      script = "security.securitySystem.deleteUser('example')"
      expect(Nexus3::API).to receive(:execute_script).with(script)
      instance.destroy
    end

    it 'should raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      expect { instance.destroy }.to raise_error(Puppet::Error, /Error while deleting nexus3_user example/)
    end
  end

  it 'should return false if it is not existing' do
    # the dummy example isn't returned by self.instances
    expect(instance.exists?).to be_falsey
  end
end
