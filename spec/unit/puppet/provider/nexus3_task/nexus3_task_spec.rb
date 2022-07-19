# frozen_string_literal: true

require 'spec_helper'

ensure_module_defined('Puppet::Provider::Nexus3Task')
require 'puppet/provider/nexus3_task/nexus3_task'

RSpec.describe Puppet::Provider::Nexus3Task::Nexus3Task do
  subject(:provider) { described_class.new }

  let(:context) { instance_double('Puppet::ResourceApi::BaseContext', 'context') }

  let(:minimum_required_values) do
    {
      type: 'repository.vulnerability.statistics',
      enabled: true,
      frequency: 'manual',
    }
  end

  before(:each) do
    stub_config
    provider.get(context).each do |resource|
      provider.delete(context, resource[:name]) if resource[:name].match?(%r{^task_})
    end

    name = "task_#{SecureRandom.uuid}"
    provider.create(context, name, name: name, **minimum_required_values)
  end

  describe '#get' do
    it 'processes resources' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^task_}) }
      expect(resources.size).to eq(1)
      expect(resources[0].keys.sort).to eq(%i[age alert_email artifact_id base_version blobstore_name cron_expression deploy_offset dry_run enabled frequency grace_period_in_days group_id
                                              integrity_check language last_used location minimum_retained notification_condition package_name rebuild_checksums recurring_day remove_if_released
                                              repository_name restore_blobs since_days snapshot_retention_days source start_date start_time type undelete_blobs yum_metadata_caching name ensure].sort)
    end
  end

  describe 'set(context, changes)' do
    it 'prevent changing the type of the task' do
      changes = {
        foo:  {
          is: { name: 'temporary', type: 'repository.vulnerability.statistics', ensure: 'present' },
          should: { name: 'temporary', type: 'blobstore.compact', ensure: 'present' }
        }
      }
      expect { provider.set(context, changes) }.to raise_error(ArgumentError, %r{type cannot be changed})
    end
  end

  describe 'create(context, name, should)' do
    shared_examples_for 'simple task' do
      it 'creates the resource' do
        resources = provider.get(context).filter { |resource| resource[:name].match(%r{^task_}) }
        expect(resources.size).to eq(1)

        provider.create(context, values[:name], **values)

        resources = provider.get(context).filter { |resource| resource[:name].match(%r{^task_}) }
        expect(resources.size).to eq(2)

        resource = resources.find { |r| r[:name] == values[:name] }
        expect(resource).to eq(values.merge(ensure: 'present'))
      end
    end

    let(:common_values) do
      {
        name: "task_#{SecureRandom.uuid}",
        enabled: true,
        frequency: 'manual',
        alert_email: 'foo@server.com',
      }
    end

    let(:default_values) do
      {
        age: 0,
        artifact_id: '',
        base_version: '',
        blobstore_name: '',
        cron_expression: '',
        deploy_offset: 0,
        dry_run: false,
        grace_period_in_days: 0,
        group_id: '',
        integrity_check: false,
        language: '',
        last_used: 0,
        location: '',
        minimum_retained: 0,
        notification_condition: 'failure',
        package_name: '',
        rebuild_checksums: false,
        recurring_day: [],
        remove_if_released: false,
        repository_name: '',
        restore_blobs: false,
        since_days: 0,
        snapshot_retention_days: 0,
        source: '',
        start_date: '',
        start_time: '',
        undelete_blobs: false,
        yum_metadata_caching: false,
      }
    end

    let(:specific_values) do
      {}
    end

    let(:values) { common_values.merge(default_values).merge(specific_values) }

    context 'for blobstore.compact' do
      let(:specific_values) do
        {
          type: 'blobstore.compact',
          blobstore_name: 'default',
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for blobstore.rebuildComponentDB' do
      let(:specific_values) do
        {
          type: 'blobstore.rebuildComponentDB',
          blobstore_name: 'default',
          dry_run: true,
          integrity_check: true,
          undelete_blobs: true,
          restore_blobs: true,
          since_days: 30,
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for create.browse.nodes' do
      let(:specific_values) do
        {
          type: 'create.browse.nodes',
          repository_name: 'maven-snapshots',
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for db.backup' do
      let(:specific_values) do
        {
          type: 'db.backup',
          location: '/tmp/foo',
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.docker.gc' do
      let(:specific_values) do
        {
          type: 'repository.docker.gc',
          repository_name: '*',
          deploy_offset: 15,
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.docker.upload-purge' do
      let(:specific_values) do
        {
          type: 'repository.docker.upload-purge',
          age: 15,
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.maven.publish-dotindex' do
      let(:specific_values) do
        {
          type: 'repository.maven.publish-dotindex',
          repository_name: '*',
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.maven.purge-unused-snapshots' do
      let(:specific_values) do
        {
          type: 'repository.maven.purge-unused-snapshots',
          repository_name: '*',
          last_used: 30,
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.maven.rebuild-metadata' do
      let(:specific_values) do
        {
          type: 'repository.maven.rebuild-metadata',
          artifact_id: 'foo',
          base_version: '1.0',
          group_id: 'bar',
          repository_name: '*',
          rebuild_checksums: true,
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.maven.remove-snapshots' do
      let(:specific_values) do
        {
          type: 'repository.maven.remove-snapshots',
          grace_period_in_days: 5,
          minimum_retained: 3,
          remove_if_released: true,
          repository_name: '*',
          snapshot_retention_days: 9,
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.maven.unpublish-dotindex' do
      let(:specific_values) do
        {
          type: 'repository.maven.unpublish-dotindex',
          repository_name: '*',
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.npm.rebuild-metadata' do
      let(:specific_values) do
        {
          type: 'repository.npm.rebuild-metadata',
          repository_name: '*',
          package_name: 'foo',
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.npm.reindex' do
      let(:specific_values) do
        {
          type: 'repository.npm.reindex',
          repository_name: '*',
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.purge-unused' do
      let(:specific_values) do
        {
          type: 'repository.purge-unused',
          repository_name: '*',
          last_used: 11,
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.rebuild-index' do
      let(:specific_values) do
        {
          type: 'repository.rebuild-index',
          repository_name: '*',
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.yum.rebuild.metadata' do
      let(:specific_values) do
        {
          type: 'repository.yum.rebuild.metadata',
          repository_name: '*',
          yum_metadata_caching: true,
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for script' do
      let(:specific_values) do
        {
          type: 'script',
          language: 'foo',
          source: "a\nb\nc",
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for frequency' do
      let(:specific_values) { frequency_values.merge(type: 'tasklog.cleanup') }

      context 'once' do
        let(:frequency_values) do
          {
            frequency: 'once',
            start_date: (Date.today + 1).iso8601,
            start_time: '23:59',
          }
        end

        it_behaves_like 'simple task'
      end

      context 'hourly' do
        let(:frequency_values) do
          {
            frequency: 'hourly',
            start_date: (Date.today + 1).iso8601,
            start_time: '23:59',
          }
        end

        it_behaves_like 'simple task'
      end

      context 'daily' do
        let(:frequency_values) do
          {
            frequency: 'daily',
            start_date: (Date.today + 1).iso8601,
            start_time: '23:59',
          }
        end

        it_behaves_like 'simple task'
      end

      context 'weekly' do
        let(:frequency_values) do
          {
            frequency: 'weekly',
            start_date: (Date.today + 1).iso8601,
            start_time: '23:59',
            recurring_day: %w[sunday tuesday thursday],
          }
        end

        it_behaves_like 'simple task'
      end

      context 'monthly' do
        let(:frequency_values) do
          {
            frequency: 'monthly',
            start_date: (Date.today + 1).iso8601,
            start_time: '23:59',
            recurring_day: %w[1 5 10 15 20 25 30 last],
          }
        end

        it_behaves_like 'simple task'
      end

      context 'advanced' do
        let(:frequency_values) do
          {
            frequency: 'advanced',
            cron_expression: '10 45 */2 16 5 ? *',
          }
        end

        it_behaves_like 'simple task'
      end
    end
  end

  describe 'update(context, name, should)' do
    shared_examples_for 'simple task' do
      it 'updates the resource' do
        original_resources = provider.get(context)
        original_resource = original_resources.find { |r| r[:name] == values[:name] }

        provider.update(context, values[:name], **values)

        new_resources = provider.get(context)
        new_resource = new_resources.find { |r| r[:name] == values[:name] }
        expect(original_resource).not_to eq(new_resource)

        expect(new_resource).to eq(values.merge(ensure: 'present'))
      end
    end

    before(:each) { provider.create(context, values[:name], **create_values) }

    let(:create_values) { common_values.merge(default_values).merge(specific_values) }

    let(:values) { create_values.merge(update_values).merge(specific_update_values) }

    let(:type) { '' }

    let(:common_values) do
      {
        name: "task_#{SecureRandom.uuid}",
        type: type,
        enabled: true,
        frequency: 'manual',
        alert_email: 'foo@server.com',
      }
    end

    let(:default_values) do
      {
        age: 0,
        artifact_id: '',
        base_version: '',
        blobstore_name: '',
        cron_expression: '',
        deploy_offset: 0,
        dry_run: false,
        grace_period_in_days: 0,
        group_id: '',
        integrity_check: false,
        language: '',
        last_used: 0,
        location: '',
        minimum_retained: 0,
        notification_condition: 'failure',
        package_name: '',
        rebuild_checksums: false,
        recurring_day: [],
        remove_if_released: false,
        repository_name: '',
        restore_blobs: false,
        since_days: 0,
        snapshot_retention_days: 0,
        source: '',
        start_date: '',
        start_time: '',
        undelete_blobs: false,
        yum_metadata_caching: false,
      }
    end

    let(:update_values) do
      {
        enabled: false,
        alert_email: 'bar@server.com',
        notification_condition: 'success_failure',
      }
    end

    let(:specific_values) do
      {}
    end

    let(:specific_update_values) do
      {}
    end

    context 'for blobstore.compact' do
      let(:type) { 'blobstore.compact' }

      let(:specific_values) do
        {
          blobstore_name: 'default',
        }
      end

      let(:specific_update_values) do
        {
          blobstore_name: 'xyz',
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for blobstore.rebuildComponentDB' do
      let(:type) { 'blobstore.rebuildComponentDB' }

      let(:specific_values) do
        {
          blobstore_name: 'default',
          dry_run: true,
          integrity_check: false,
          undelete_blobs: true,
          restore_blobs: false,
          since_days: 30,
        }
      end

      let(:specific_update_values) do
        {
          blobstore_name: 'xyz',
          dry_run: false,
          integrity_check: true,
          undelete_blobs: false,
          restore_blobs: true,
          since_days: 25,
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for create.browse.nodes' do
      let(:type) { 'create.browse.nodes' }

      let(:specific_values) do
        {
          repository_name: 'maven-snapshots',
        }
      end

      let(:specific_update_values) do
        {
          repository_name: 'maven-snapshots,maven-release',
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for db.backup' do
      let(:type) { 'db.backup' }

      let(:specific_values) do
        {
          location: '/tmp/foo',
        }
      end

      let(:specific_update_values) do
        {
          location: '/tmp/bar',
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.docker.gc' do
      let(:type) { 'repository.docker.gc' }

      let(:specific_values) do
        {
          repository_name: '*',
          deploy_offset: 15,
        }
      end

      let(:specific_update_values) do
        {
          repository_name: 'foo',
          deploy_offset: 35,
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.docker.upload-purge' do
      let(:type) { 'repository.docker.upload-purge' }

      let(:specific_values) do
        {
          age: 15,
        }
      end

      let(:specific_update_values) do
        {
          age: 23,
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.maven.publish-dotindex' do
      let(:type) { 'repository.maven.publish-dotindex' }

      let(:specific_values) do
        {
          repository_name: '*',
        }
      end

      let(:specific_update_values) do
        {
          repository_name: 'bar',
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.maven.purge-unused-snapshots' do
      let(:type) { 'repository.maven.purge-unused-snapshots' }

      let(:specific_values) do
        {
          repository_name: '*',
          last_used: 30,
        }
      end

      let(:specific_upfate_values) do
        {
          repository_name: 'maven-central',
          last_used: 12,
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.maven.rebuild-metadata' do
      let(:type) { 'repository.maven.rebuild-metadata' }

      let(:specific_values) do
        {
          artifact_id: 'foo',
          base_version: '1.0',
          group_id: 'bar',
          repository_name: '*',
          rebuild_checksums: true,
        }
      end

      let(:specific_update_values) do
        {
          artifact_id: 'xyz',
          base_version: '2.5',
          group_id: 'abc',
          repository_name: 'maven-central',
          rebuild_checksums: false,
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.maven.remove-snapshots' do
      let(:type) { 'repository.maven.remove-snapshots' }

      let(:specific_values) do
        {
          grace_period_in_days: 5,
          minimum_retained: 3,
          remove_if_released: true,
          repository_name: '*',
          snapshot_retention_days: 9,
        }
      end

      let(:specific_update_values) do
        {
          grace_period_in_days: 4,
          minimum_retained: 2,
          remove_if_released: false,
          repository_name: 'maven-central',
          snapshot_retention_days: 8,
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.maven.unpublish-dotindex' do
      let(:type) { 'repository.maven.unpublish-dotindex' }

      let(:specific_values) do
        {
          repository_name: '*',
        }
      end

      let(:specific_update_values) do
        {
          repository_name: 'maven-central',
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.npm.rebuild-metadata' do
      let(:type) { 'repository.npm.rebuild-metadata' }

      let(:specific_values) do
        {
          repository_name: '*',
          package_name: 'foo',
        }
      end

      let(:specific_update_values) do
        {
          repository_name: 'yum',
          package_name: 'bar',
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.npm.reindex' do
      let(:type) { 'repository.npm.reindex' }

      let(:specific_values) do
        {
          repository_name: '*',
        }
      end

      let(:specific_update_values) do
        {
          repository_name: 'npm',
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.purge-unused' do
      let(:type) { 'repository.purge-unused' }

      let(:specific_values) do
        {
          repository_name: '*',
          last_used: 11,
        }
      end

      let(:specific_update_values) do
        {
          repository_name: 'maven-central',
          last_used: 30,
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.rebuild-index' do
      let(:type) { 'repository.rebuild-index' }

      let(:specific_values) do
        {
          repository_name: '*',
        }
      end

      let(:specific_update_values) do
        {
          repository_name: 'maven-central',
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for repository.yum.rebuild.metadata' do
      let(:type) { 'repository.yum.rebuild.metadata' }

      let(:specific_values) do
        {
          repository_name: '*',
          yum_metadata_caching: true,
        }
      end

      let(:specific_update_values) do
        {
          repository_name: 'yum',
          yum_metadata_caching: false,
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for script' do
      let(:type) { 'script' }

      let(:specific_values) do
        {
          language: 'foo',
          source: "a\nb\nc",
        }
      end

      let(:specific_update_values) do
        {
          language: 'bar',
          source: "a\nd\nc",
        }
      end

      it_behaves_like 'simple task'
    end

    context 'for frequency' do
      let(:specific_values) { { type: 'tasklog.cleanup' } }
      let(:specific_update_values) { frequency_values.merge(type: 'tasklog.cleanup') }

      context 'once' do
        let(:frequency_values) do
          {
            frequency: 'once',
            start_date: (Date.today + 1).iso8601,
            start_time: '23:59',
          }
        end

        it_behaves_like 'simple task'
      end

      context 'hourly' do
        let(:frequency_values) do
          {
            frequency: 'hourly',
            start_date: (Date.today + 1).iso8601,
            start_time: '23:59',
          }
        end

        it_behaves_like 'simple task'
      end

      context 'daily' do
        let(:frequency_values) do
          {
            frequency: 'daily',
            start_date: (Date.today + 1).iso8601,
            start_time: '23:59',
          }
        end

        it_behaves_like 'simple task'
      end

      context 'weekly' do
        let(:frequency_values) do
          {
            frequency: 'weekly',
            start_date: (Date.today + 1).iso8601,
            start_time: '23:59',
            recurring_day: %w[sunday tuesday thursday],
          }
        end

        it_behaves_like 'simple task'
      end

      context 'monthly' do
        let(:frequency_values) do
          {
            frequency: 'monthly',
            start_date: (Date.today + 1).iso8601,
            start_time: '23:59',
            recurring_day: %w[1 5 10 15 20 25 30 last],
          }
        end

        it_behaves_like 'simple task'
      end

      context 'advanced' do
        let(:frequency_values) do
          {
            frequency: 'advanced',
            cron_expression: '10 45 */2 16 5 ? *',
          }
        end

        it_behaves_like 'simple task'
      end
    end
  end

  describe 'delete(context, name)' do
    let(:name) { "task_#{SecureRandom.uuid}" }

    before(:each) { provider.create(context, name, name: name, **minimum_required_values) }

    it 'deletes the resource' do
      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^task_}) }
      expect(resources.size).to eq(2)

      provider.delete(context, name)

      resources = provider.get(context).filter { |resource| resource[:name].match(%r{^task_}) }
      expect(resources.size).to eq(1)
    end
  end
end
