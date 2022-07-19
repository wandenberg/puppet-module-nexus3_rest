require 'puppet/resource_api'
require 'puppet_x/nexus3/config'
require 'puppet/provider/nexus3_utils'

Puppet::ResourceApi.register_type(
  name: 'nexus3_task',
  docs: <<-EOS,
@summary a nexus3_task type
@example
nexus3_task { 'Cleanup service':
  type            => 'repository.cleanup',
  frequency       => 'advanced',
  cron_expression => '0 0 1 * * ?',
}

This type provides Puppet with the capabilities to manage Nexus 3 Task.

**Autorequires**:
* `File[$PUPPET_CONF_DIR/nexus3_rest.conf]`
  EOS
  features: ['canonicalize'],
  attributes: {
    ensure: {
      type: 'Enum[present, absent]',
      desc: 'Whether this resource should be present or absent on the target system.',
      default: 'present',
    },
    name: {
      type: 'String',
      desc: 'Id of the task.',
      behaviour: :namevar,
    },
    enabled: {
      type: 'Boolean',
      desc: 'Enable or disable the scheduled task.',
      default: true,
    },
    type: {
      type: "Pattern[/\\A(#{Puppet::Provider::Nexus3Utils::TASK_TYPES.join('|')})\\z/]",
      desc: 'The type of the task that will be scheduled to run. Can be the type name (as shown in the user interface) or
        the type id. The plugin ships a list of known type names; if a type name is not known, it is passed unmodified
        to Nexus.',
    },
    alert_email: {
      type: 'Pattern[/\A(.+@.+\..+)?\z/]',
      desc: 'The email address where an email will be sent to in case that task execution failed.',
      default: '',
    },
    notification_condition: {
      type: 'Enum[failure, success_failure]',
      desc: 'Conditions that will trigger a notification email',
      default: 'failure'
    },
    frequency: {
      type: 'Enum[manual, once, hourly, daily, weekly, monthly, advanced]',
      desc: 'The frequency this task will run. Can be one of: `manual`, `once`, `hourly`, `daily`, `weekly`, `monthly` or `advanced`.',
      default: 'manual',
    },
    recurring_day: {
      type: 'Array[String]',
      desc: 'The days the task will be repeatedly executed.',
      default: [],
    },
    cron_expression: {
      type: 'String',
      desc: 'A cron expression that will control the running of the task.',
      default: '',
    },
    start_date: {
      type: 'Pattern[/\A(\d{4}-\d{2}-\d{2})?\z/]',
      desc: 'The date this task should start running, specified as `YYYY-MM-DD`. Mandatory unless `frequency` is `manual` or `advanced`.',
      default: '',
    },
    start_time: {
      type: 'Pattern[/\A(\d?\d:\d{2})?\z/]',
      desc: 'The start time in `hh:mm` the task should run (according to the timezone of the service). Mandatory unless `frequency` is `manual` or `advanced`.',
      default: '',
    },
    age: {
      type: 'Integer',
      desc: "The 'age' for the task.",
      default: 0,
    },
    artifact_id: {
      type: 'String',
      desc: "The 'artifact_id' for the task.",
      default: '',
    },
    base_version: {
      type: 'String',
      desc: "The 'base_version' for the task.",
      default: '',
    },
    blobstore_name: {
      type: 'String',
      desc: "The 'blobstore_name' for the task.",
      default: '',
    },
    deploy_offset: {
      type: 'Integer',
      desc: 'Manifests and images deployed within this period before the task starts will not be deleted.',
      default: 0,
    },
    dry_run: {
      type: 'Boolean',
      desc: "The 'dry_run' for the task.",
      default: false,
    },
    grace_period_in_days: {
      type: 'Integer',
      desc: "The 'grace_period_in_days' for the task.",
      default: 0,
    },
    group_id: {
      type: 'String',
      desc: "The 'group_id' for the task.",
      default: '',
    },
    integrity_check: {
      type: 'Boolean',
      desc: "The 'integrity_check' for the task.",
      default: false,
    },
    language: {
      type: 'String',
      desc: "The 'language' for the task.",
      default: '',
    },
    last_used: {
      type: 'Integer',
      desc: "The 'last_used' for the task.",
      default: 0,
    },
    location: {
      type: 'String',
      desc: "The 'location' for the task.",
      default: '',
    },
    minimum_retained: {
      type: 'Integer',
      desc: "The 'minimum_retained' for the task.",
      default: 0,
    },
    package_name: {
      type: 'String',
      desc: "The 'package_name' for the task.",
      default: '',
    },
    rebuild_checksums: {
      type: 'Boolean',
      desc: "The 'rebuild_checksums' for the task.",
      default: false,
    },
    remove_if_released: {
      type: 'Boolean',
      desc: "The 'remove_if_released' for the task.",
      default: false,
    },
    repository_name: {
      type: 'String',
      desc: "The 'repository_name' for the task.",
      default: '',
    },
    restore_blobs: {
      type: 'Boolean',
      desc: "The 'restore_blobs' for the task.",
      default: false,
    },
    since_days: {
      type: 'Integer',
      desc: "The 'since_days' for the task.",
      default: 0,
    },
    snapshot_retention_days: {
      type: 'Integer',
      desc: "The 'snapshot_retention_days' for the task.",
      default: 0,
    },
    source: {
      type: 'String',
      desc: "The 'source' for the task.",
      default: '',
    },
    undelete_blobs: {
      type: 'Boolean',
      desc: "The 'undelete_blobs' for the task.",
      default: false,
    },
    yum_metadata_caching: {
      type: 'Boolean',
      desc: "The 'yum_metadata_caching' for the task.",
      default: false,
    },
  },
  autorequire: {
    file: Nexus3::Config.file_path,
  },
)
