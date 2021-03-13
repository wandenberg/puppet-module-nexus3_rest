require 'spec_helper'

type_class = Puppet::Type.type(:nexus3_cleanup_policy)

describe type_class.provider(:ruby) do
  before(:each) { stub_default_config_and_healthcheck }

  let(:values) do
    {
      last_downloaded: 30,
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

  describe 'define getters and setters to some type properties or params' do
    let(:instance) { described_class.new }

    [:format, :last_downloaded].each do |method|
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
      before(:each) { allow(Nexus3::API).to receive(:execute_script).and_return([{ name: 'example1', format: 'all' }].to_json) }

      it 'not set the format' do
        resources = { example1: type_class.new(values.merge(name: 'example1')) }
        described_class.prefetch(resources)
        expect(resources[:example1].provider.notes).to eq('')
        expect(resources[:example1][:notes]).to be_truthy
      end
    end

    describe 'not found instance' do
      before(:each) { allow(Nexus3::API).to receive(:execute_script).and_return('[]') }

      it 'not set the format' do
        resources = { example1: type_class.new(values.merge(name: 'example1')) }
        described_class.prefetch(resources)
        expect(resources[:example1].provider.notes).to eq(:absent)
        expect(resources[:example1][:notes]).to be_truthy
      end
    end
  end

  describe 'instances' do
    specify 'should execute a script to get repositories settings' do
      script = <<~EOS
        def policyStorage = container.lookup(org.sonatype.nexus.cleanup.storage.CleanupPolicyStorage.class.name)
        def policies = policyStorage.getAll()

        def infos = []
        policies.each { policy ->
          def attributes = [
            name: policy.getName(),
            notes: policy.getNotes(),
          ]
          def format = policy.getFormat()
          attributes.format = (format == 'ALL_FORMATS' ? 'all' : format)

          def criteria = policy.getCriteria()
          attributes.regex = (criteria.containsKey('regex') ? criteria['regex'] : null)
          attributes.last_downloaded = (criteria.containsKey('lastDownloaded') ? criteria['lastDownloaded'].toInteger() / 60 / 60 / 24 : null)
          attributes.last_blob_updated = (criteria.containsKey('lastBlobUpdated') ? criteria['lastBlobUpdated'].toInteger() / 60 / 60 / 24 : null)
          if (criteria.containsKey('isPrerelease')) {
            attributes.is_prerelease = criteria['isPrerelease'].toBoolean()
          }

          infos << attributes
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
      expect(instances[0].notes).to eq('')
    end

    specify 'should map each returned values to the correspondent property' do
      allow(Nexus3::API).to receive(:execute_script).and_return([values].to_json)
      instances = described_class.instances
      expect(instances.length).to eq 1
      expect(instances[0].last_downloaded).to eq(30)
    end
  end

  describe 'create' do
    it 'execute a script to create the instance' do
      script = <<~EOS
        def policyStorage = container.lookup(org.sonatype.nexus.cleanup.storage.CleanupPolicyStorage.class.name)

        def criteria = [:]
        criteria.lastDownloaded = 2592000.toString()

        def policy = new org.sonatype.nexus.cleanup.storage.CleanupPolicy()

        policy.setCriteria(criteria)
        policy.setFormat(('all' == 'all' ? 'ALL_FORMATS' : 'all'))
        policy.setName('example')
        policy.setNotes('')
        policy.setMode('delete')

        policyStorage.add(policy)
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
      instance.create
    end

    it 'raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      expect { instance.create }.to raise_error(Puppet::Error, %r{Error while creating nexus3_cleanup_policy example})
    end
  end

  describe 'flush' do
    it 'execute a script to update the instance' do
      script = <<~EOS
        def policyStorage = container.lookup(org.sonatype.nexus.cleanup.storage.CleanupPolicyStorage.class.name)

        def criteria = [:]
        criteria.remove('isPrerelease')
        criteria.lastDownloaded = 2592000.toString()

        def policy = policyStorage.get('example')
        policy.setCriteria(criteria)
        policy.setFormat(('all' == 'all' ? 'ALL_FORMATS' : 'all'))
        policy.setNotes('')
        policy.setMode('delete')

        policyStorage.update(policy)
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
      instance.mark_config_dirty
      instance.flush
    end

    it 'raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      instance.mark_config_dirty
      expect { instance.flush }.to raise_error(Puppet::Error, %r{Error while updating nexus3_cleanup_policy example})
    end

    describe 'when some value has changed' do
      before(:each) { instance.last_downloaded = 29 }

      specify { expect(instance.instance_variable_get(:@update_required)).to be_truthy }
    end
  end

  describe 'destroy' do
    it 'execute a script to destroy the instance' do
      script = <<~EOS
        def policyStorage = container.lookup(org.sonatype.nexus.cleanup.storage.CleanupPolicyStorage.class.name)
        if (policyStorage.exists('example')) {
          policyStorage.remove(policyStorage.get('example'))
        }
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
      instance.destroy
    end

    it 'raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      expect { instance.destroy }.to raise_error(Puppet::Error, %r{Error while deleting nexus3_cleanup_policy example})
    end
  end

  it 'return false if it is not existing' do
    # the dummy example isn't returned by self.instances
    expect(instance.exists?).to be_falsey
  end
end
