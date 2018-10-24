require 'spec_helper'

type_class = Puppet::Type.type(:nexus3_repository_group)

describe type_class.provider(:ruby) do
  before(:each) { stub_default_config_and_healthcheck }

  let(:values) do
    {
      provider_type: 'npm',
      blobstore_name: 'blob_store',
      online: true,
      repositories: %W(repo-a repo-b),
      strict_content_type_validation: false,
      httpport: 8442,
      httpsport: 8443,
      v1enabled: true,
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

    [:provider_type, :blobstore_name, :online, :repositories, :strict_content_type_validation].each do |method|
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
      before(:each) { allow(Nexus3::API).to receive(:execute_script).and_return([{name: 'example1', online: false}].to_json) }

      it 'should not set the provider' do
        resources = {example1: type_class.new(values.merge(name: 'example1'))}
        described_class.prefetch(resources)
        expect(resources[:example1].provider.online).to eq(:false)
        expect(resources[:example1][:online]).to be_truthy
      end
    end

    describe 'not found instance' do
      before(:each) { allow(Nexus3::API).to receive(:execute_script).and_return('[]') }

      it 'should not set the provider' do
        resources = {example1: type_class.new(values.merge(name: 'example1'))}
        described_class.prefetch(resources)
        expect(resources[:example1].provider.online).to eq(:absent)
        expect(resources[:example1][:online]).to be_truthy
      end
    end
  end

  describe 'instances' do
    specify 'should execute a script to get repositories settings' do
      script = <<~EOS
        def repositories = repository.repositoryManager.browse()
        def infos = repositories.findResults { repository ->
          def config = repository.getConfiguration()
          def (provider_type, type) = config.recipeName.split('-')

          if (type != 'group') {
            return null
          }

          def storage = config.attributes('storage')
          def proxy = config.attributes('proxy')
          def group = config.attributes('group')
          def maven = config.attributes('maven')
          def httpclient = config.attributes('httpclient');
          def authentication = httpclient.child('authentication');
          [
            name: config.repositoryName,
            provider_type: provider_type,
            online: config.isOnline(),
            blobstore_name: storage.get('blobStoreName'),
            repositories: group.get('memberNames'),
            strict_content_type_validation: storage.get('strictContentTypeValidation'),
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
      expect(instances[0].provider_type).to eq('')
      expect(instances[0].blobstore_name).to eq('')
      expect(instances[0].online).to eq('')
      expect(instances[0].repositories).to eq('')
      expect(instances[0].strict_content_type_validation).to eq('')
    end

    specify 'should map each returned values to the correspondent property' do
      allow(Nexus3::API).to receive(:execute_script).and_return([values].to_json)
      instances = described_class.instances
      expect(instances.length).to eq 1
      expect(instances[0].provider_type).to eq('npm')
      expect(instances[0].blobstore_name).to eq('blob_store')
      expect(instances[0].online).to eq :true
      expect(instances[0].repositories).to eql(['repo-a', 'repo-b'])
      expect(instances[0].strict_content_type_validation).to eq :false
    end
  end

  describe 'create' do
    it 'should execute a script to create the instance' do
      script = <<~EOS
        def config = new org.sonatype.nexus.repository.config.Configuration()
        config.repositoryName = 'example'
        config.recipeName = 'npm-group'
        config.online = true
        def group = config.attributes('group')
        group.set('memberNames', ["repo-a", "repo-b"])
        def storage = config.attributes('storage')
        storage.set('strictContentTypeValidation', false)
        storage.set('blobStoreName', 'blob_store')
        repository.repositoryManager.create(config)
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
      instance.create
    end

    it 'should raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      expect { instance.create }.to raise_error(Puppet::Error, /Error while creating nexus3_repository_group example/)
    end
  end


  describe 'a maven2 repository group' do
    let(:resource_extra_attributes) do
      { provider_type: :maven2 }
    end

    it 'should execute a script to create the group' do
      script = <<~EOS
        def config = new org.sonatype.nexus.repository.config.Configuration()
        config.repositoryName = 'example'
        config.recipeName = 'maven2-group'
        config.online = true
        def group = config.attributes('group')
        group.set('memberNames', ["repo-a", "repo-b"])
        def storage = config.attributes('storage')
        storage.set('strictContentTypeValidation', false)
        storage.set('blobStoreName', 'blob_store')
        repository.repositoryManager.create(config)
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script)
      instance.create
    end
  end

  describe 'a npm repository group' do
    let(:resource_extra_attributes) do
      { provider_type: :nuget }
    end

    it 'should execute a script to create the group' do
      script = <<~EOS
        def config = new org.sonatype.nexus.repository.config.Configuration()
        config.repositoryName = 'example'
        config.recipeName = 'nuget-group'
        config.online = true
        def group = config.attributes('group')
        group.set('memberNames', ["repo-a", "repo-b"])
        def storage = config.attributes('storage')
        storage.set('strictContentTypeValidation', false)
        storage.set('blobStoreName', 'blob_store')
        repository.repositoryManager.create(config)
        EOS
      expect(Nexus3::API).to receive(:execute_script).with(script)
      instance.create
    end
  end

  describe 'a docker repository group' do
    let(:resource_extra_attributes) do
      { provider_type: :docker }
    end

    it 'should execute a script to create the group' do
      script = <<~EOS
        def config = new org.sonatype.nexus.repository.config.Configuration()
        config.repositoryName = 'example'
        config.recipeName = 'docker-group'
        config.online = true
        def group = config.attributes('group')
        group.set('memberNames', ["repo-a", "repo-b"])
        def storage = config.attributes('storage')
        storage.set('strictContentTypeValidation', false)
        storage.set('blobStoreName', 'blob_store')
        def docker = config.attributes('docker')
        docker.set('httpPort', '8442')
        docker.set('httpsPort', '8443')
        docker.set('v1Enabled', 'true')
        docker.set('forceBasicAuth','true')
        repository.repositoryManager.create(config)
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script)
      instance.create
    end
  end

  describe 'flush' do
    it 'should execute a script to update the instance' do
      script = <<~EOS
        def config = repository.repositoryManager.get('example').getConfiguration()
        config.online = true
        def group = config.attributes('group')
        group.set('memberNames', ["repo-a", "repo-b"])
        def storage = config.attributes('storage')
        storage.set('strictContentTypeValidation', false)
        repository.repositoryManager.update(config)
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
      instance.mark_config_dirty
      instance.flush
    end


    describe 'a docker repository group update' do
      let(:resource_extra_attributes) do
        { provider_type: :docker }
      end

      it 'should execute a script to update the group' do
        script = <<~EOS
          def config = repository.repositoryManager.get('example').getConfiguration()
          config.online = true
          def group = config.attributes('group')
          group.set('memberNames', ["repo-a", "repo-b"])
          def storage = config.attributes('storage')
          storage.set('strictContentTypeValidation', false)
          def docker = config.attributes('docker')
          docker.set('httpPort', '8442')
          docker.set('httpsPort', '8443')
          docker.set('v1Enabled', 'true')
          docker.set('forceBasicAuth','true')
          repository.repositoryManager.update(config)
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.mark_config_dirty
        instance.flush
      end
    end

    it 'should raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      instance.mark_config_dirty
      expect { instance.flush }.to raise_error(Puppet::Error, /Error while updating nexus3_repository_group example/)
    end

    it 'should not allow changes on provider_type' do
      expect { instance.provider_type = :maven }.to raise_error(Puppet::Error, /provider_type is write-once only and cannot be changed./)
    end

    it 'should not allow changes on blobstore_name' do
      expect { instance.blobstore_name = 'new_blob_store' }.to raise_error(Puppet::Error, /blobstore_name is write-once only and cannot be changed./)
    end

    describe 'when some value has changed' do
      before(:each) { instance.repositories = ['name1', 'name3'] }

      specify { expect(instance.instance_variable_get(:@update_required)).to be_truthy }
    end
  end

  describe 'destroy' do
    it 'should execute a script to destroy the instance' do
      script = "repository.repositoryManager.delete('example')"
      expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
      instance.destroy
    end

    it 'should raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      expect { instance.destroy }.to raise_error(Puppet::Error, /Error while deleting nexus3_repository_group example/)
    end
  end

  it 'should return false if it is not existing' do
    # the dummy example isn't returned by self.instances
    expect(instance.exists?).to be_falsey
  end
end
