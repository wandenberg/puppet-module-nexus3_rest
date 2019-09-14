require 'spec_helper'

type_class = Puppet::Type.type(:nexus3_repository)

describe type_class.provider(:ruby) do
  before(:each) { stub_default_config_and_healthcheck }

  let(:values) do
    {
      type: 'proxy',
      provider_type: 'npm',
      blobstore_name: 'blob_store',
      online: true,
      strict_content_type_validation: false,
      write_policy: :allow_write,
      remote_url: 'http://remote.server.com',
      version_policy: 'mixed',
      layout_policy: 'permissive',
      remote_auth_type: 'ntlm',
      remote_user: 'user',
      remote_password: 'pass',
      remote_ntlm_host: 'ntlmhost',
      remote_ntlm_domain: 'ntlmdomain',
      http_port: 8442,
      https_port: 8443,
      v1_enabled: true,
      index_type: 'custom',
      index_url: 'http://docker.proxy.index.com',
      distribution: 'trusty',
      is_flat: true,
      pgp_keypair: 'keypair',
      pgp_keypair_passphrase: 'passphrase',
      asset_history_limit: 100,
    }
  end

  let(:resource_extra_attributes) do
    {}
  end

  let(:instance) do
    resource = type_class.new(values.merge(name: 'example').merge(resource_extra_attributes))
    instance = described_class.new(values.merge(name: 'example', write_policy: 'ALLOW').merge(resource_extra_attributes))
    resource.provider = instance
    instance
  end

  describe 'define getters and setters to each type properties or params' do
    let(:instance) { described_class.new }

    [:type, :provider_type, :blobstore_name, :online, :version_policy, :layout_policy, :write_policy,
     :strict_content_type_validation, :remote_url, :remote_auth_type, :remote_user, :remote_password,
     :remote_ntlm_host, :remote_ntlm_domain, :distribution, :is_flat, :pgp_keypair, :pgp_keypair_passphrase].each do |method|
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
      before(:each) { allow(Nexus3::API).to receive(:execute_script).and_return([{name: 'example1', remote_user: 'from_service'}].to_json) }

      it 'should not set the provider' do
        resources = {example1: type_class.new(values.merge(name: 'example1'))}
        described_class.prefetch(resources)
        expect(resources[:example1].provider.remote_user).to eq('from_service')
        expect(resources[:example1][:remote_user]).to eq 'user'
      end
    end

    describe 'not found instance' do
      before(:each) { allow(Nexus3::API).to receive(:execute_script).and_return('[]') }

      it 'should not set the provider' do
        resources = {example1: type_class.new(values.merge(name: 'example1'))}
        described_class.prefetch(resources)
        expect(resources[:example1].provider.remote_user).to eq(:absent)
        expect(resources[:example1][:remote_user]).to eq 'user'
      end
    end
  end

  describe 'instances' do
    specify 'should execute a script to get repositories settings' do
      script = <<~EOS
        def repositories = repository.repositoryManager.browse()
        def infos = repositories.findResults { repository ->
          def config = repository.getConfiguration()
          def (providerType, type) = config.recipeName.split('-')

          if (type == 'group') {
            return null
          }

          def storage = config.attributes('storage')
          def proxy = config.attributes('proxy')
          def group = config.attributes('group')
          def maven = config.attributes('maven')
          def yum   = config.attributes('yum')
          def docker= config.attributes('docker')
          def dockerProxy = config.attributes('dockerProxy')
          def apt = config.attributes('apt')
          def aptSigning = config.attributes('aptSigning')
          def aptHosted = config.attributes('aptHosted')
          def httpclient = config.attributes('httpclient');
          def authentication = httpclient.child('authentication');
          [
            name: config.repositoryName,
            type: type,
            provider_type: providerType,
            online: config.isOnline(),
            write_policy: storage.get('writePolicy'),
            blobstore_name: storage.get('blobStoreName'),
            strict_content_type_validation: storage.get('strictContentTypeValidation'),
            remote_url: proxy.get('remoteUrl'),
            version_policy: maven.get('versionPolicy')?.toLowerCase(),
            layout_policy: maven.get('layoutPolicy')?.toLowerCase(),
            remote_auth_type: authentication.get('type') ? authentication.get('type') : 'none',
            remote_user: authentication.get('username'),
            remote_password: authentication.get('password'),
            remote_ntlm_host: authentication.get('ntlmHost'),
            remote_ntlm_domain: authentication.get('ntlmDomain'),
            depth: yum.get('repodataDepth').toString(),
            http_port: docker.get('httpPort'),
            https_port: docker.get('httpsPort'),
            v1_enabled: docker.get('v1Enabled'),
            force_basic_auth: docker.get('forceBasicAuth'),
            index_type: dockerProxy.get('indexType'),
            index_url: dockerProxy.get('indexUrl'),
            distribution: apt.get('distribution'),
            is_flat: apt.get('flat'),
            pgp_keypair: aptSigning.get('keypair'),
            pgp_keypair_passphrase: aptSigning.get('passphrase'),
            asset_history_limit: aptHosted.get('assetHistoryLimit'),
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
      expect(instances[0].type).to eq('')
      expect(instances[0].provider_type).to eq('')
      expect(instances[0].blobstore_name).to eq('')
      expect(instances[0].online).to eq('')
      expect(instances[0].strict_content_type_validation).to eq('')
      expect(instances[0].write_policy).to eq(:absent)
      expect(instances[0].remote_url).to eq('')
      expect(instances[0].version_policy).to eq('')
      expect(instances[0].layout_policy).to eq('')
      expect(instances[0].remote_auth_type).to eq('')
      expect(instances[0].remote_user).to eq('')
      expect(instances[0].remote_password).to eq('')
      expect(instances[0].remote_ntlm_host).to eq('')
      expect(instances[0].remote_ntlm_domain).to eq('')
      expect(instances[0].index_type).to eq(:absent)
      expect(instances[0].index_url).to eq('')
      expect(instances[0].distribution).to eq('')
      expect(instances[0].is_flat).to eq('')
      expect(instances[0].pgp_keypair).to eq('')
      expect(instances[0].pgp_keypair_passphrase).to eq('')
      expect(instances[0].asset_history_limit).to eq('')
    end

    specify 'should map each returned values to the correspondent property' do
      allow(Nexus3::API).to receive(:execute_script).and_return([values.merge(write_policy: 'ALLOW')].to_json)
      instances = described_class.instances
      expect(instances.length).to eq 1
      expect(instances[0].type).to eq('proxy')
      expect(instances[0].provider_type).to eq('npm')
      expect(instances[0].blobstore_name).to eq('blob_store')
      expect(instances[0].online).to eq :true
      expect(instances[0].strict_content_type_validation).to eq :false
      expect(instances[0].write_policy).to eq :allow_write
      expect(instances[0].remote_url).to eq('http://remote.server.com')
      expect(instances[0].version_policy).to eq('mixed')
      expect(instances[0].layout_policy).to eq('permissive')
      expect(instances[0].remote_auth_type).to eq('ntlm')
      expect(instances[0].remote_user).to eq('user')
      expect(instances[0].remote_password).to eq('pass')
      expect(instances[0].remote_ntlm_host).to eq('ntlmhost')
      expect(instances[0].remote_ntlm_domain).to eq('ntlmdomain')
      expect(instances[0].index_type).to eq(:absent)
      expect(instances[0].index_url).to eq('http://docker.proxy.index.com')
      expect(instances[0].distribution).to eq('trusty')
      expect(instances[0].is_flat).to eq :true
      expect(instances[0].pgp_keypair).to eq('keypair')
      expect(instances[0].pgp_keypair_passphrase).to eq('passphrase')
      expect(instances[0].asset_history_limit).to eq(100)
    end
  end

  describe 'create' do
    it 'should execute a script to create the instance' do
      script = <<~EOS
        def config = new org.sonatype.nexus.repository.config.Configuration()
        config.repositoryName = 'example'
        config.recipeName = 'npm-proxy'
        config.online = true
        def storage = config.attributes('storage')
        storage.set('blobStoreName', 'blob_store')
        storage.set('strictContentTypeValidation', false)
        def proxy = config.attributes('proxy')
        proxy.set('remoteUrl', 'http://remote.server.com')
        def httpclient = config.attributes('httpclient');
        def authentication = httpclient.child('authentication');
        authentication.set('type', 'ntlm');
        authentication.set('username', 'user');
        authentication.set('password', 'pass');
        authentication.set('ntlmHost', 'ntlmhost');
        authentication.set('ntlmDomain', 'ntlmdomain');
        repository.repositoryManager.create(config)
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script)
      instance.create
    end

    describe 'a hosted repository' do
      let(:resource_extra_attributes) do
        { type: :hosted }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def config = new org.sonatype.nexus.repository.config.Configuration()
          config.repositoryName = 'example'
          config.recipeName = 'npm-hosted'
          config.online = true
          def storage = config.attributes('storage')
          storage.set('blobStoreName', 'blob_store')
          storage.set('strictContentTypeValidation', false)
          storage.set('writePolicy', 'ALLOW')
          def httpclient = config.attributes('httpclient');
          def authentication = httpclient.child('authentication');
          authentication.set('type', 'ntlm');
          authentication.set('username', 'user');
          authentication.set('password', 'pass');
          authentication.set('ntlmHost', 'ntlmhost');
          authentication.set('ntlmDomain', 'ntlmdomain');
          repository.repositoryManager.create(config)
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script)
        instance.create
      end
    end

    describe 'an apt repository' do
      let(:resource_extra_attributes) do
        { provider_type: :apt }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def config = new org.sonatype.nexus.repository.config.Configuration()
          config.repositoryName = 'example'
          config.recipeName = 'apt-proxy'
          config.online = true
          def storage = config.attributes('storage')
          storage.set('blobStoreName', 'blob_store')
          storage.set('strictContentTypeValidation', false)
          def proxy = config.attributes('proxy')
          proxy.set('remoteUrl', 'http://remote.server.com')
          def httpclient = config.attributes('httpclient');
          def authentication = httpclient.child('authentication');
          authentication.set('type', 'ntlm');
          authentication.set('username', 'user');
          authentication.set('password', 'pass');
          authentication.set('ntlmHost', 'ntlmhost');
          authentication.set('ntlmDomain', 'ntlmdomain');
          def apt = config.attributes('apt')
          apt.set('distribution', 'trusty')
          apt.set('flat', true)
          repository.repositoryManager.create(config)
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script)
        instance.create
      end
    end

    describe 'a maven2 repository' do
      let(:resource_extra_attributes) do
        { provider_type: :maven2 }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def config = new org.sonatype.nexus.repository.config.Configuration()
          config.repositoryName = 'example'
          config.recipeName = 'maven2-proxy'
          config.online = true
          def storage = config.attributes('storage')
          storage.set('blobStoreName', 'blob_store')
          storage.set('strictContentTypeValidation', false)
          def proxy = config.attributes('proxy')
          proxy.set('remoteUrl', 'http://remote.server.com')
          def httpclient = config.attributes('httpclient');
          def authentication = httpclient.child('authentication');
          authentication.set('type', 'ntlm');
          authentication.set('username', 'user');
          authentication.set('password', 'pass');
          authentication.set('ntlmHost', 'ntlmhost');
          authentication.set('ntlmDomain', 'ntlmdomain');
          def maven = config.attributes('maven')
          maven.set('versionPolicy', 'MIXED')
          maven.set('layoutPolicy', 'PERMISSIVE')
          repository.repositoryManager.create(config)
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script)
        instance.create
      end
    end

    describe 'a yum repository' do
      let(:resource_extra_attributes) do
        { provider_type: :yum, depth: 1 }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def config = new org.sonatype.nexus.repository.config.Configuration()
          config.repositoryName = 'example'
          config.recipeName = 'yum-proxy'
          config.online = true
          def storage = config.attributes('storage')
          storage.set('blobStoreName', 'blob_store')
          storage.set('strictContentTypeValidation', false)
          def proxy = config.attributes('proxy')
          proxy.set('remoteUrl', 'http://remote.server.com')
          def httpclient = config.attributes('httpclient');
          def authentication = httpclient.child('authentication');
          authentication.set('type', 'ntlm');
          authentication.set('username', 'user');
          authentication.set('password', 'pass');
          authentication.set('ntlmHost', 'ntlmhost');
          authentication.set('ntlmDomain', 'ntlmdomain');
          def yum = config.attributes('yum')
          yum.set('repodataDepth', 1)
          repository.repositoryManager.create(config)
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script)
        instance.create
      end
    end

    describe 'a docker hosted repository' do
      let(:resource_extra_attributes) do
        { provider_type: :docker, type: :hosted }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def config = new org.sonatype.nexus.repository.config.Configuration()
          config.repositoryName = 'example'
          config.recipeName = 'docker-hosted'
          config.online = true
          def storage = config.attributes('storage')
          storage.set('blobStoreName', 'blob_store')
          storage.set('strictContentTypeValidation', false)
          storage.set('writePolicy', 'ALLOW')
          def httpclient = config.attributes('httpclient');
          def authentication = httpclient.child('authentication');
          authentication.set('type', 'ntlm');
          authentication.set('username', 'user');
          authentication.set('password', 'pass');
          authentication.set('ntlmHost', 'ntlmhost');
          authentication.set('ntlmDomain', 'ntlmdomain');
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

    describe 'a docker proxy repository' do
      let(:resource_extra_attributes) do
        { provider_type: :docker, type: :proxy }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def config = new org.sonatype.nexus.repository.config.Configuration()
          config.repositoryName = 'example'
          config.recipeName = 'docker-proxy'
          config.online = true
          def storage = config.attributes('storage')
          storage.set('blobStoreName', 'blob_store')
          storage.set('strictContentTypeValidation', false)
          def proxy = config.attributes('proxy')
          proxy.set('remoteUrl', 'http://remote.server.com')
          def httpclient = config.attributes('httpclient');
          def authentication = httpclient.child('authentication');
          authentication.set('type', 'ntlm');
          authentication.set('username', 'user');
          authentication.set('password', 'pass');
          authentication.set('ntlmHost', 'ntlmhost');
          authentication.set('ntlmDomain', 'ntlmdomain');
          def docker = config.attributes('docker')
          def dockerProxy = config.attributes('dockerProxy')
          dockerProxy.set('indexType', 'CUSTOM')
          dockerProxy.set('indexUrl', 'http://docker.proxy.index.com')
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

    describe 'a repository without authentication' do
      let(:resource_extra_attributes) do
        { remote_auth_type: :none }
      end

      it 'should execute a script to create the instance' do
        script = <<~EOS
          def config = new org.sonatype.nexus.repository.config.Configuration()
          config.repositoryName = 'example'
          config.recipeName = 'npm-proxy'
          config.online = true
          def storage = config.attributes('storage')
          storage.set('blobStoreName', 'blob_store')
          storage.set('strictContentTypeValidation', false)
          def proxy = config.attributes('proxy')
          proxy.set('remoteUrl', 'http://remote.server.com')
          config.getAttributes().remove('httpclient')
          repository.repositoryManager.create(config)
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script)
        instance.create
      end
    end

    it 'should raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      expect { instance.create }.to raise_error(Puppet::Error, /Error while creating nexus3_repository example/)
    end
  end

  describe 'flush' do
    it 'should execute a script to update the instance' do
      script = <<~EOS
        def config = repository.repositoryManager.get('example').getConfiguration()
        config.online = true
        def storage = config.attributes('storage')
        storage.set('strictContentTypeValidation', false)
        def proxy = config.attributes('proxy')
        proxy.set('remoteUrl', 'http://remote.server.com')
        def httpclient = config.attributes('httpclient');
        def authentication = httpclient.child('authentication');
        authentication.set('type', 'ntlm');
        authentication.set('username', 'user');
        authentication.set('password', 'pass');
        authentication.set('ntlmHost', 'ntlmhost');
        authentication.set('ntlmDomain', 'ntlmdomain');
        repository.repositoryManager.update(config)
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script)
      instance.mark_config_dirty
      instance.flush
    end

    describe 'a hosted repository' do
      let(:resource_extra_attributes) do
        { type: :hosted }
      end

      it 'should execute a script to update the instance' do
        script = <<~EOS
          def config = repository.repositoryManager.get('example').getConfiguration()
          config.online = true
          def storage = config.attributes('storage')
          storage.set('strictContentTypeValidation', false)
          storage.set('writePolicy', 'ALLOW')
          def httpclient = config.attributes('httpclient');
          def authentication = httpclient.child('authentication');
          authentication.set('type', 'ntlm');
          authentication.set('username', 'user');
          authentication.set('password', 'pass');
          authentication.set('ntlmHost', 'ntlmhost');
          authentication.set('ntlmDomain', 'ntlmdomain');
          repository.repositoryManager.update(config)
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script)
        instance.mark_config_dirty
        instance.flush
      end
    end

    describe 'an apt repository' do
      let(:resource_extra_attributes) do
        { provider_type: :apt }
      end

      it 'should execute a script to update the instance' do
        script = <<~EOS
          def config = repository.repositoryManager.get('example').getConfiguration()
          config.online = true
          def storage = config.attributes('storage')
          storage.set('strictContentTypeValidation', false)
          def proxy = config.attributes('proxy')
          proxy.set('remoteUrl', 'http://remote.server.com')
          def httpclient = config.attributes('httpclient');
          def authentication = httpclient.child('authentication');
          authentication.set('type', 'ntlm');
          authentication.set('username', 'user');
          authentication.set('password', 'pass');
          authentication.set('ntlmHost', 'ntlmhost');
          authentication.set('ntlmDomain', 'ntlmdomain');
          def apt = config.attributes('apt')
          apt.set('distribution', 'trusty')
          apt.set('flat', true)
          repository.repositoryManager.update(config)
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script)
        instance.mark_config_dirty
        instance.flush
      end
    end

    describe 'a maven2 repository' do
      let(:resource_extra_attributes) do
        { provider_type: :maven2 }
      end

      it 'should execute a script to update the instance' do
        script = <<~EOS
          def config = repository.repositoryManager.get('example').getConfiguration()
          config.online = true
          def storage = config.attributes('storage')
          storage.set('strictContentTypeValidation', false)
          def proxy = config.attributes('proxy')
          proxy.set('remoteUrl', 'http://remote.server.com')
          def httpclient = config.attributes('httpclient');
          def authentication = httpclient.child('authentication');
          authentication.set('type', 'ntlm');
          authentication.set('username', 'user');
          authentication.set('password', 'pass');
          authentication.set('ntlmHost', 'ntlmhost');
          authentication.set('ntlmDomain', 'ntlmdomain');
          def maven = config.attributes('maven')
          maven.set('versionPolicy', 'MIXED')
          maven.set('layoutPolicy', 'PERMISSIVE')
          repository.repositoryManager.update(config)
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script)
        instance.mark_config_dirty
        instance.flush
      end
    end

    describe 'a yum repository' do
      let(:resource_extra_attributes) do
        { provider_type: :yum, depth: 3 }
      end

      it 'should execute a script to update the instance' do
        script = <<~EOS
          def config = repository.repositoryManager.get('example').getConfiguration()
          config.online = true
          def storage = config.attributes('storage')
          storage.set('strictContentTypeValidation', false)
          def proxy = config.attributes('proxy')
          proxy.set('remoteUrl', 'http://remote.server.com')
          def httpclient = config.attributes('httpclient');
          def authentication = httpclient.child('authentication');
          authentication.set('type', 'ntlm');
          authentication.set('username', 'user');
          authentication.set('password', 'pass');
          authentication.set('ntlmHost', 'ntlmhost');
          authentication.set('ntlmDomain', 'ntlmdomain');
          def yum = config.attributes('yum')
          yum.set('repodataDepth', 3)
          repository.repositoryManager.update(config)
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script)
        instance.mark_config_dirty
        instance.flush
      end
    end

    describe 'a repository without authentication' do
      let(:resource_extra_attributes) do
        { remote_auth_type: :none }
      end

      it 'should execute a script to update the instance' do
        script = <<~EOS
          def config = repository.repositoryManager.get('example').getConfiguration()
          config.online = true
          def storage = config.attributes('storage')
          storage.set('strictContentTypeValidation', false)
          def proxy = config.attributes('proxy')
          proxy.set('remoteUrl', 'http://remote.server.com')
          config.getAttributes().remove('httpclient')
          repository.repositoryManager.update(config)
        EOS
        expect(Nexus3::API).to receive(:execute_script).with(script)
        instance.mark_config_dirty
        instance.flush
      end
    end

    it 'should raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      instance.mark_config_dirty
      expect { instance.flush }.to raise_error(Puppet::Error, /Error while updating nexus3_repository example/)
    end

    it 'should not allow changes on type' do
      expect { instance.type = :proxy }.to raise_error(Puppet::Error, /type is write-once only and cannot be changed./)
    end

    it 'should not allow changes on provider_type' do
      expect { instance.provider_type = :maven }.to raise_error(Puppet::Error, /provider_type is write-once only and cannot be changed./)
    end

    it 'should not allow changes on blobstore_name' do
      expect { instance.blobstore_name = 'new_blob_store' }.to raise_error(Puppet::Error, /blobstore_name is write-once only and cannot be changed./)
    end

    it 'should not allow changes on version_policy' do
      expect { instance.version_policy = :snapshot }.to raise_error(Puppet::Error, /version_policy is write-once only and cannot be changed./)
    end

    describe 'changing write_policy' do
      describe 'for hosted repository' do
        let(:resource_extra_attributes) do
          { type: :hosted }
        end

        it 'should allow changes on write_policy' do
          expect { instance.write_policy = :read_only }.not_to raise_error
          expect(instance.write_policy).to eql(:read_only)
        end
      end

      describe 'for proxied repository' do
        let(:resource_extra_attributes) do
          { type: :proxy }
        end

        it 'should not allow changes on version_policy' do
          expect { instance.write_policy = :read_only }.not_to raise_error
          expect(instance.write_policy).not_to eql(:read_only)
        end
      end
    end

    describe 'when some value has changed' do
      before(:each) { instance.remote_auth_type = :username }

      specify { expect(instance.instance_variable_get(:@update_required)).to be_truthy }
    end
  end

  describe 'destroy' do
    it 'should execute a script to destroy the instance' do
      script = <<~EOS
        def repositories = repository.repositoryManager.browse()
        repositories.each { repo ->
          def config = repo.getConfiguration()
          def (provider_type, type) = config.recipeName.split('-')
          if (type == 'group') {
            def group = config.attributes('group')
            def members = group.get('memberNames')
            if (members.contains('example')) {
              members.removeElement('example')
              group.set('memberNames', members)
              repository.repositoryManager.update(config)
            }
          }
        }
        repository.repositoryManager.delete('example')
      EOS
      expect(Nexus3::API).to receive(:execute_script).with(script)
      instance.destroy
    end

    it 'should raise a human readable error message if the operation failed' do
      allow(Nexus3::API).to receive(:execute_script).and_raise('Operation failed')
      expect { instance.destroy }.to raise_error(Puppet::Error, /Error while deleting nexus3_repository example/)
    end
  end

  it 'should return false if it is not existing' do
    # the dummy example isn't returned by self.instances
    expect(instance.exists?).to be_falsey
  end
end
