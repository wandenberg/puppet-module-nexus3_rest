require 'spec_helper'

type_class = Puppet::Type.type(:nexus3_realm_settings)

describe type_class.provider(:ruby) do
  before(:each) { stub_default_config_and_healthcheck }

  let(:values) do
    {
      names: %w[name1 name2]
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

    [:names].each do |method|
      specify { expect(instance.respond_to?(method)).to be_truthy }
      specify { expect(instance.respond_to?("#{method}=")).to be_truthy }
    end
  end

  describe 'prefetch' do
    it 'raise error if more than one resource of this type is configured' do
      expect {
        described_class.prefetch({ example1: type_class.new(values.merge(name: 'example1')), example2: type_class.new(values.merge(name: 'example2')) })
      }.to raise_error(Puppet::Error, %r{There are more then 1 instance\(s\) of 'nexus3_realm_settings': example1, example2})
    end

    it 'not raise error if just one resource of this type is configured' do
      expect(Nexus3::API).to receive(:execute_script).and_return(values.to_json)

      expect {
        described_class.prefetch({ example1: type_class.new(values.merge(name: 'example1')) })
      }.not_to raise_error
    end

    it 'set the provider no matter if the names matches' do
      expect(Nexus3::API).to receive(:execute_script).and_return('{"name": "example2", "names": ["from_service"] }')

      resources = { example1: type_class.new(values.merge(name: 'example1')) }
      described_class.prefetch(resources)
      expect(resources[:example1].provider.names).to eql(['from_service'])
      expect(resources[:example1][:names]).to eql(%w[name1 name2])
    end
  end

  describe 'instances' do
    specify 'should execute a script to get Realm settings' do
      script = <<~EOS
        def realmManager = container.lookup(org.sonatype.nexus.security.realm.RealmManager.class.name);
        def config = realmManager.getConfiguration()
        return groovy.json.JsonOutput.toJson([
          names : config.getRealmNames(),
        ]);
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
      described_class.instances
    end

    specify 'should use default values to non set properties' do
      allow(Nexus3::API).to receive(:execute_script).and_return('{}')
      instances = described_class.instances
      expect(instances.length).to eq 1
      expect(instances[0].names).to eq('')
    end

    specify 'should map each returned values to the correspondent property' do
      allow(Nexus3::API).to receive(:execute_script).and_return(values.to_json)
      instances = described_class.instances
      expect(instances.length).to eq 1
      expect(instances[0].names).to eq %w[name1 name2]
    end
  end

  describe 'flush' do
    it 'execute a script to update the changes' do
      script = <<~EOS
        def realmManager = container.lookup(org.sonatype.nexus.security.realm.RealmManager.class.name)
        def config = realmManager.getConfiguration()
        config.setRealmNames(["name1", "name2"])
        realmManager.setConfiguration(config);
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script).and_return(nil)
      instance.mark_config_dirty
      instance.flush
    end

    describe 'when some value has changed' do
      before(:each) { instance.names = %w[name1 name3] }

      specify { expect(instance.instance_variable_get(:@update_required)).to be_truthy }
    end
  end
end
