require 'spec_helper'

type_class = Puppet::Type.type(:nexus3_task)

describe type_class.provider(:ruby) do
  before(:each) { stub_default_config_and_healthcheck }

  let(:values) do
    {
      id: 'internal_id',
      name: 'foo',
      type: 'script',
      enabled: true,
      alert_email: 'foo@server.com',
      frequency: 'weekly',
      start_date: '2017-12-21',
      start_time: '23:59',
      recurring_day: 'sunday',
      age: 45,
      artifact_id: 'artifact_id',
      base_version: 'base_version',
      blobstore_name: 'blobstore_name',
      grace_period_in_days: 5,
      group_id: 'group_id',
      language: 'language',
      last_used: 35,
      minimum_retained: 10,
      remove_if_released: true,
      repository_name: 'repository_name',
      snapshot_retention_days: 15,
      source: 'source',
      location: 'location',
    }
  end

  let(:resource_extra_attributes) do
    {}
  end

  let(:remove_values) do
    []
  end

  let(:resource_values) do
    resource_values = values.merge(name: 'example').merge(resource_extra_attributes)
    resource_values.reject! {|k, v| remove_values.include?(k) } unless remove_values.empty?
    resource_values
  end

  let(:instance) do
    resource = type_class.new(resource_values)
    instance = described_class.new(resource_values)
    resource.provider = instance
    instance
  end

  describe 'define getters and setters to each type properties or params' do
    let(:instance) { described_class.new }

    [:id, :type, :enabled, :alert_email, :frequency, :start_date, :start_time, :cron_expression, :recurring_day,
     :age, :artifact_id, :base_version, :blobstore_name, :grace_period_in_days, :group_id, :language, :last_used,
     :minimum_retained, :remove_if_released, :repository_name, :snapshot_retention_days, :source, :location].each do |method|
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
      before(:each) { allow(Nexus3::API).to receive(:execute_script).and_return([{name: 'example1', alert_email: 'from_service@server.com'}].to_json) }

      it 'should not set the provider' do
        resources = {example1: type_class.new(values.merge(name: 'example1'))}
        described_class.prefetch(resources)
        expect(resources[:example1].provider.alert_email).to eq('from_service@server.com')
        expect(resources[:example1][:alert_email]).to eq('foo@server.com')
      end
    end

    describe 'not found instance' do
      before(:each) { allow(Nexus3::API).to receive(:execute_script).and_return('[]') }

      it 'should not set the provider' do
        resources = {example1: type_class.new(values.merge(name: 'example1'))}
        described_class.prefetch(resources)
        expect(resources[:example1].provider.alert_email).to eq(:absent)
        expect(resources[:example1][:alert_email]).to eq('foo@server.com')
      end
    end
  end

  describe 'instances' do
    specify 'should execute a script to get repositories settings' do
      script = <<~EOS
        def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
        def tasks = taskScheduler.listsTasks()
        def weekdays = ["SUN": "sunday", "MON": "monday", "TUE": "tuesday", "WED": "wednesday", "THU": "thursday", "FRI": "friday", "SAT": "saturday"]
        def infos = tasks.collect { task ->
          def config = task.getConfiguration()
          def schedule = task.getSchedule()
          def info = [
            id: config.getId(),
            name: config.getName(),
            type: config.getTypeId(),
            enabled: config.isEnabled(),
            alert_email: config.getAlertEmail(),
            frequency: schedule.getType(),
          ]
        
          if ((schedule.getType() != 'manual') && (schedule.getType() != 'cron')) {
            info['start_date'] = schedule.getStartAt().format('yyyy-MM-dd')
            info['start_time'] = schedule.getStartAt().format('HH:mm')
          }
        
          if (schedule.getType() == 'cron') {
            info['cron_expression'] = schedule.getCronExpression()
            info['frequency'] = 'advanced'
          }
        
          if (schedule.getType() == 'weekly') {
            info['recurring_day'] = schedule.getDaysToRun().collect{ weekdays[it.name()] }.join(',')
          }
        
          if (schedule.getType() == 'monthly') {
            info['recurring_day'] = schedule.getDaysToRun().collect{ it.isLastDayOfMonth() ? 'last' :  it.getDay() }.join(',')
          }

          if (config.getTypeId() == 'blobstore.compact') {
            info['blobstore_name'] = config.getString('blobstoreName')
          }

          if (config.getTypeId() == 'repository.docker.upload-purge') {
            info['age'] = config.getInteger('age', 0)
          }

          if (config.getTypeId() == 'repository.maven.publish-dotindex') {
            info['repository_name'] = config.getString('repositoryName')
          }

          if (config.getTypeId() == 'repository.maven.purge-unused-snapshots') {
            info['last_used'] = config.getInteger('lastUsed', 0)
            info['repository_name'] = config.getString('repositoryName')
          }

          if (config.getTypeId() == 'repository.maven.rebuild-metadata') {
            info['artifact_id'] = config.getString('artifactId')
            info['base_version'] = config.getString('baseVersion')
            info['group_id'] = config.getString('groupId')
            info['repository_name'] = config.getString('repositoryName')
          }

          if (config.getTypeId() == 'repository.maven.remove-snapshots') {
            info['grace_period_in_days'] = config.getInteger('gracePeriodInDays', 0)
            info['minimum_retained'] = config.getInteger('minimumRetained', 0)
            info['remove_if_released'] = config.getBoolean('removeIfReleased', false)
            info['repository_name'] = config.getString('repositoryName')
            info['snapshot_retention_days'] = config.getInteger('snapshotRetentionDays', 0)
          }

          if (config.getTypeId() == 'repository.maven.unpublish-dotindex') {
            info['repository_name'] = config.getString('repositoryName')
          }

          if (config.getTypeId() == 'repository.purge-unused') {
            info['last_used'] = config.getInteger('lastUsed', 0)
            info['repository_name'] = config.getString('repositoryName')
          }

          if (config.getTypeId() == 'repository.rebuild-index') {
            info['repository_name'] = config.getString('repositoryName')
          }

          if (config.getTypeId() == 'script') {
            info['language'] = config.getString('language')
            info['source'] = config.getString('source')
          }

          if (config.getTypeId() == 'db.backup') {
            info['location'] = config.getString('location')
          }
        
          info
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
      expect(instances[0].type).to eq('')
      expect(instances[0].enabled).to eq('')
      expect(instances[0].alert_email).to eq('')
      expect(instances[0].frequency).to eq('')
      expect(instances[0].start_date).to eq('')
      expect(instances[0].start_time).to eq('')
      expect(instances[0].cron_expression).to eq('')
      expect(instances[0].recurring_day).to eq('')
      expect(instances[0].age).to eq('')
      expect(instances[0].artifact_id).to eq('')
      expect(instances[0].base_version).to eq('')
      expect(instances[0].blobstore_name).to eq('')
      expect(instances[0].grace_period_in_days).to eq('')
      expect(instances[0].group_id).to eq('')
      expect(instances[0].language).to eq('')
      expect(instances[0].last_used).to eq('')
      expect(instances[0].minimum_retained).to eq('')
      expect(instances[0].remove_if_released).to eq('')
      expect(instances[0].repository_name).to eq('')
      expect(instances[0].snapshot_retention_days).to eq('')
      expect(instances[0].source).to eq('')
    end

    specify 'should map each returned values to the correspondent property' do
      allow(Nexus3::API).to receive(:execute_script).and_return([values].to_json)
      instances = described_class.instances
      expect(instances.length).to eq 1
      expect(instances[0].id).to eq('internal_id')
      expect(instances[0].type).to eq('script')
      expect(instances[0].enabled).to eq(:true)
      expect(instances[0].alert_email).to eq('foo@server.com')
      expect(instances[0].frequency).to eq('weekly')
      expect(instances[0].start_date).to eq('2017-12-21')
      expect(instances[0].start_time).to eq('23:59')
      expect(instances[0].cron_expression).to eq('')
      expect(instances[0].recurring_day).to eq('sunday')
      expect(instances[0].age).to eq(45)
      expect(instances[0].artifact_id).to eq('artifact_id')
      expect(instances[0].base_version).to eq('base_version')
      expect(instances[0].blobstore_name).to eq('blobstore_name')
      expect(instances[0].grace_period_in_days).to eq(5)
      expect(instances[0].group_id).to eq('group_id')
      expect(instances[0].language).to eq('language')
      expect(instances[0].last_used).to eq(35)
      expect(instances[0].minimum_retained).to eq(10)
      expect(instances[0].remove_if_released).to eq(:true)
      expect(instances[0].repository_name).to eq('repository_name')
      expect(instances[0].snapshot_retention_days).to eq(15)
      expect(instances[0].source).to eq('source')
    end
  end

  describe 'create' do
    describe 'for type blobstore.compact' do
      let(:resource_extra_attributes) do
        { type: 'blobstore.compact' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('blobstore.compact')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('blobstoreName', 'blobstore_name')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for type repository.docker.upload-purge' do
      let(:resource_extra_attributes) do
        { type: 'repository.docker.upload-purge' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('repository.docker.upload-purge')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setInteger('age', 45)
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for type repository.maven.publish-dotindex' do
      let(:resource_extra_attributes) do
        { type: 'repository.maven.publish-dotindex' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('repository.maven.publish-dotindex')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('repositoryName', 'repository_name')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for type repository.maven.purge-unused-snapshots' do
      let(:resource_extra_attributes) do
        { type: 'repository.maven.purge-unused-snapshots' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('repository.maven.purge-unused-snapshots')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setInteger('lastUsed', 35)
          config.setString('repositoryName', 'repository_name')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for type repository.maven.rebuild-metadata' do
      let(:resource_extra_attributes) do
        { type: 'repository.maven.rebuild-metadata' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('repository.maven.rebuild-metadata')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('artifactId', 'artifact_id')
          config.setString('baseVersion', 'base_version')
          config.setString('groupId', 'group_id')
          config.setString('repositoryName', 'repository_name')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for type repository.maven.remove-snapshots' do
      let(:resource_extra_attributes) do
        { type: 'repository.maven.remove-snapshots' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('repository.maven.remove-snapshots')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setInteger('gracePeriodInDays', 5)
          config.setInteger('minimumRetained', 10)
          config.setBoolean('removeIfReleased', true)
          config.setString('repositoryName', 'repository_name')
          config.setInteger('snapshotRetentionDays', 15)
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for type repository.maven.unpublish-dotindex' do
      let(:resource_extra_attributes) do
        { type: 'repository.maven.unpublish-dotindex' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('repository.maven.unpublish-dotindex')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('repositoryName', 'repository_name')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for type repository.purge-unused' do
      let(:resource_extra_attributes) do
        { type: 'repository.purge-unused' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('repository.purge-unused')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setInteger('lastUsed', 35)
          config.setString('repositoryName', 'repository_name')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for type repository.rebuild-index' do
      let(:resource_extra_attributes) do
        { type: 'repository.rebuild-index' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('repository.rebuild-index')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('repositoryName', 'repository_name')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for type script' do
      let(:resource_extra_attributes) do
        { type: 'script' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('script')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('language', 'language')
          config.setString('source', 'source')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for type security.purge-api-keys' do
      let(:resource_extra_attributes) do
        { type: 'security.purge-api-keys' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('security.purge-api-keys')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for type db.backup' do
      let(:resource_extra_attributes) do
        { type: 'db.backup' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('db.backup')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('location', 'location')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for frequency manual' do
      let(:resource_extra_attributes) do
        { type: 'script', frequency: 'manual' }
      end

      let(:remove_values) do
        [:cron_expression, :recurring_day, :start_date, :start_time]
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('script')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('language', 'language')
          config.setString('source', 'source')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Manual()
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for frequency once' do
      let(:resource_extra_attributes) do
        { type: 'script', frequency: 'once' }
      end

      let(:remove_values) do
        [:cron_expression, :recurring_day]
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('script')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('language', 'language')
          config.setString('source', 'source')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Once(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for frequency hourly' do
      let(:resource_extra_attributes) do
        { type: 'script', frequency: 'hourly' }
      end

      let(:remove_values) do
        [:cron_expression, :recurring_day]
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('script')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('language', 'language')
          config.setString('source', 'source')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Hourly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for frequency daily' do
      let(:resource_extra_attributes) do
        { type: 'script', frequency: 'daily' }
      end

      let(:remove_values) do
        [:cron_expression, :recurring_day]
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('script')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('language', 'language')
          config.setString('source', 'source')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Daily(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for frequency weekly' do
      let(:resource_extra_attributes) do
        { type: 'script', frequency: 'weekly', recurring_day: %w(tuesday thursday sunday) }
      end

      let(:remove_values) do
        [:cron_expression]
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('script')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('language', 'language')
          config.setString('source', 'source')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN", "THU", "TUE"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for frequency monthly' do
      let(:resource_extra_attributes) do
        { type: 'script', frequency: 'monthly', recurring_day: %w(1 5 10 15 20 25 30 last) }
      end

      let(:remove_values) do
        [:cron_expression]
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('script')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('language', 'language')
          config.setString('source', 'source')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Monthly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet([1, 10, 15, 20, 25, 30, 5, 999].collect{ org.sonatype.nexus.scheduling.schedule.Monthly.CalendarDay.day(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end

    describe 'for frequency advanced' do
      let(:resource_extra_attributes) do
        { type: 'script', frequency: 'advanced', cron_expression: 'any valid cron expression' }
      end

      let(:remove_values) do
        [:recurring_day, :start_date, :start_time]
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def config = taskScheduler.createTaskConfigurationInstance('script')
          config.setName('example')
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('language', 'language')
          config.setString('source', 'source')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Cron(new java.util.Date(), 'any valid cron expression')
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.create
      end
    end


    it 'should raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      expect { instance.create }.to raise_error(Puppet::Error, /Error while creating nexus3_task example/)
    end
  end

  describe 'flush' do
    describe 'for type blobstore.compact' do
      let(:resource_extra_attributes) do
        { type: 'blobstore.compact' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def taskInfo = taskScheduler.getTaskById('internal_id')
          def config = taskInfo.getConfiguration()
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('blobstoreName', 'blobstore_name')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.mark_config_dirty
        instance.flush
      end
    end

    describe 'for type repository.docker.upload-purge' do
      let(:resource_extra_attributes) do
        { type: 'repository.docker.upload-purge' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def taskInfo = taskScheduler.getTaskById('internal_id')
          def config = taskInfo.getConfiguration()
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setInteger('age', 45)
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.mark_config_dirty
        instance.flush
      end
    end

    describe 'for type repository.maven.publish-dotindex' do
      let(:resource_extra_attributes) do
        { type: 'repository.maven.publish-dotindex' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def taskInfo = taskScheduler.getTaskById('internal_id')
          def config = taskInfo.getConfiguration()
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('repositoryName', 'repository_name')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.mark_config_dirty
        instance.flush
      end
    end

    describe 'for type repository.maven.purge-unused-snapshots' do
      let(:resource_extra_attributes) do
        { type: 'repository.maven.purge-unused-snapshots' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def taskInfo = taskScheduler.getTaskById('internal_id')
          def config = taskInfo.getConfiguration()
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setInteger('lastUsed', 35)
          config.setString('repositoryName', 'repository_name')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.mark_config_dirty
        instance.flush
      end
    end

    describe 'for type repository.maven.rebuild-metadata' do
      let(:resource_extra_attributes) do
        { type: 'repository.maven.rebuild-metadata' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def taskInfo = taskScheduler.getTaskById('internal_id')
          def config = taskInfo.getConfiguration()
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('artifactId', 'artifact_id')
          config.setString('baseVersion', 'base_version')
          config.setString('groupId', 'group_id')
          config.setString('repositoryName', 'repository_name')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.mark_config_dirty
        instance.flush
      end
    end

    describe 'for type repository.maven.remove-snapshots' do
      let(:resource_extra_attributes) do
        { type: 'repository.maven.remove-snapshots' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def taskInfo = taskScheduler.getTaskById('internal_id')
          def config = taskInfo.getConfiguration()
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setInteger('gracePeriodInDays', 5)
          config.setInteger('minimumRetained', 10)
          config.setBoolean('removeIfReleased', true)
          config.setString('repositoryName', 'repository_name')
          config.setInteger('snapshotRetentionDays', 15)
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.mark_config_dirty
        instance.flush
      end
    end

    describe 'for type repository.maven.unpublish-dotindex' do
      let(:resource_extra_attributes) do
        { type: 'repository.maven.unpublish-dotindex' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def taskInfo = taskScheduler.getTaskById('internal_id')
          def config = taskInfo.getConfiguration()
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('repositoryName', 'repository_name')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.mark_config_dirty
        instance.flush
      end
    end

    describe 'for type repository.purge-unused' do
      let(:resource_extra_attributes) do
        { type: 'repository.purge-unused' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def taskInfo = taskScheduler.getTaskById('internal_id')
          def config = taskInfo.getConfiguration()
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setInteger('lastUsed', 35)
          config.setString('repositoryName', 'repository_name')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.mark_config_dirty
        instance.flush
      end
    end

    describe 'for type repository.rebuild-index' do
      let(:resource_extra_attributes) do
        { type: 'repository.rebuild-index' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def taskInfo = taskScheduler.getTaskById('internal_id')
          def config = taskInfo.getConfiguration()
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('repositoryName', 'repository_name')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.mark_config_dirty
        instance.flush
      end
    end

    describe 'for type script' do
      let(:resource_extra_attributes) do
        { type: 'script' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def taskInfo = taskScheduler.getTaskById('internal_id')
          def config = taskInfo.getConfiguration()
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          config.setString('language', 'language')
          config.setString('source', 'source')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.mark_config_dirty
        instance.flush
      end
    end

    describe 'for type security.purge-api-keys' do
      let(:resource_extra_attributes) do
        { type: 'security.purge-api-keys' }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
          def taskInfo = taskScheduler.getTaskById('internal_id')
          def config = taskInfo.getConfiguration()
          config.setEnabled(true)
          config.setAlertEmail('foo@server.com')
          def schedule = new org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '2017-12-21 23:59'), new HashSet(["SUN"].collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }))
          taskScheduler.scheduleTask(config, schedule);
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
        instance.mark_config_dirty
        instance.flush
      end
    end

    it 'should raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      instance.mark_config_dirty
      expect { instance.flush }.to raise_error(Puppet::Error, /Error while updating nexus3_task example/)
    end

    it 'should not allow changes on id' do
      expect { instance.id = 'other_id' }.to raise_error(Puppet::Error, /id is write-once only and cannot be changed./)
    end

    it 'should not allow changes on type' do
      expect { instance.type = 'blobstore.compact' }.to raise_error(Puppet::Error, /type is write-once only and cannot be changed./)
    end

    describe 'when some value has changed' do
      before(:each) { instance.cron_expression = '* * * * *' }

      specify { expect(instance.instance_variable_get(:@update_required)).to be_truthy }
    end
  end

  describe 'destroy' do
    it 'should execute a script to destroy the instance' do
      script = <<~EOS
        def taskScheduler = container.lookup(org.sonatype.nexus.scheduling.TaskScheduler.class.name)
        def taskInfo = taskScheduler.getTaskById('internal_id')
        taskInfo.remove()
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script).and_return('{}')
      instance.destroy
    end

    it 'should raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      expect { instance.destroy }.to raise_error(Puppet::Error, /Error while deleting nexus3_task example/)
    end
  end

  it 'should return false if it is not existing' do
    # the dummy example isn't returned by self.instances
    expect(instance.exists?).to be_falsey
  end
end
