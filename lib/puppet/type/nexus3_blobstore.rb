# frozen_string_literal: true

require 'puppet/resource_api'
require 'puppet_x/nexus3/config'

Puppet::ResourceApi.register_type(
  name: 'nexus3_blobstore',
  docs: <<-EOS,
@summary a nexus3_blobstore type
@example
nexus3_blobstore { 'default':
  type => 'File',
  path => 'default',
}

This type provides Puppet with the capabilities to manage Nexus 3 Blob Store.

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
      desc: 'Unique blob store name.',
      behaviour: :namevar,
    },
    type: {
      type: 'Pattern[/(S3|File)/]',
      desc: 'The type of the blob store.',
      default: 'File',
      behaviour: :init_only,
    },
    path: {
      type: 'String',
      desc: 'The path of the blob store.',
      default: '',
    },
    soft_quota_enabled: {
      type: 'Boolean',
      desc: 'Enable soft quota.',
      default: false,
    },
    quota_type: {
      type: 'Pattern[/\A(spaceRemainingQuota|spaceUsedQuota)?\z/]',
      desc: 'The quota type of the blob store.',
      default: '',
    },
    quota_limit_bytes: {
      type: 'Variant[Integer, String]',
      desc: 'The quota limit (in MB) of the blob store.',
      default: '',
    },
    region: {
      type: 'Pattern[/\A(DEFAULT|us-east-1|us-east-2|us-west-1|us-west-2|us-gov-west-1|us-gov-east-1|eu-west-1|eu-west-2|eu-west-3|eu-central-1|eu-north-1|eu-south-1|ap-east-1|ap-southeast-1|ap-southeast-2|ap-northeast-1|ap-northeast-2|ap-south-1|sa-east-1|ca-central-1|cn-north-1|cn-northwest-1|me-south-1|af-south-1)?\z/]', # rubocop:disable Layout/LineLength
      desc: 'The region on S3 store.',
      default: '',
    },
    bucket: {
      type: 'Pattern[/\A[a-z0-9.-]*\z/]',
      desc: 'The bucket on S3 store.',
      default: '',
    },
    prefix: {
      type: 'String',
      desc: 'The prefix on S3 store.',
      default: '',
    },
    expiration: {
      type: 'Variant[Integer, String]',
      desc: 'The expiration (in days) on S3 store.',
      default: '',
    },
    access_key_id: {
      type: 'String',
      desc: 'The access_key_id on S3 store.',
      default: '',
    },
    secret_access_key: {
      type: 'String',
      desc: 'The secret_access_key on S3 store.',
      default: '',
    },
    assume_role: {
      type: 'String',
      desc: 'The assume_role on S3 store.',
      default: '',
    },
    session_token: {
      type: 'String',
      desc: 'The session_token on S3 store.',
      default: '',
    },
    encryption_type: {
      type: 'Variant[Pattern[/\A(none|s3ManagedEncryption|kmsManagedEncryption)\z/], String]',
      desc: 'The encryption_type on S3 store.',
      default: '',
    },
    encryption_key: {
      type: 'String',
      desc: 'The encryption_key on S3 store.',
      default: '',
    },
    endpoint: {
      type: 'Pattern[/\A(.+:.+)?\z/]',
      desc: 'The endpoint on S3 store.',
      default: '',
    },
    max_connection_pool_size: {
      type: 'Variant[Integer, String]',
      desc: 'The max_connection_pool_size on S3 store.',
      default: '',
    },
    signertype: {
      type: 'Pattern[/\A(DEFAULT|S3SignerType|AWSS3V4SignerType)?\z/]',
      desc: 'The signertype on S3 store.',
      default: '',
    },
    forcepathstyle: {
      type: 'Variant[Boolean, String]',
      desc: 'Force path style on S3 store.',
      default: '',
    },
  },
  autorequire: {
    file: Nexus3::Config.file_path,
  },
)
