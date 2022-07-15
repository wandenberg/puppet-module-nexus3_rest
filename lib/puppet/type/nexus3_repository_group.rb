# frozen_string_literal: true

require 'puppet/resource_api'
require 'puppet_x/nexus3/config'

Puppet::ResourceApi.register_type(
  name: 'nexus3_repository_group',
  docs: <<-EOS,
@summary a nexus3_repository_group type
@example
nexus3_repository_group { 'maven-public':
  provider_type  => 'maven2',
  repositories   => ['maven-releases', 'maven-snapshots', 'maven-central'],
  version_policy => 'mixed',
}

This type provides Puppet with the capabilities to manage Nexus 3 Repository Group.

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
      desc: 'Unique repository group identifier; once created cannot be changed unless the repository group is destroyed. The Nexus UI will show it as group id.',
      behaviour: :namevar,
    },
    provider_type: {
      type: 'Enum[bower, docker, go, maven2, npm, nuget, pypi, r, raw, rubygems, yum]',
      desc: 'The content provider of the repository.',
    },
    online: {
      type: 'Boolean',
      desc: 'When repository is enabled or not to receive connections.',
      default: true,
    },
    blobstore_name: {
      type: 'String',
      desc: 'The blobstore name to store data of the repository',
      default: 'default',
    },
    repositories: {
      type: 'Array[String]',
      desc: 'A list of repositories contained in this Repository Group',
      default: [],
    },
    strict_content_type_validation: {
      type: 'Variant[Boolean, String]',
      desc: 'When should validate or not that all content uploaded to this repository is of a MIME type appropriate for the repository format.',
      default: '',
    },
    version_policy: {
      type: 'Pattern[/\A(snapshot|release|mixed)?\z/]',
      desc: 'Maven2 repositories can store release, snapshot or mixed artifacts.',
      default: '',
    },
    layout_policy: {
      type: 'Pattern[/\A(strict|permissive)?\z/]',
      desc: 'Maven2 repositories can check if all paths are maven artifact or metadata paths.',
      default: '',
    },
    content_disposition: {
      type: 'Pattern[/\A(inline|attachment)?\z/]',
      desc: 'Add Content-Disposition header as \'Attachment\' to disable some content from being inline in a browser.',
      default: '',
    },

    # docker-specific #
    http_port: {
      type: 'Variant[Integer, String]',
      desc: 'Docker repositories have Repository Connectors for http.',
      default: '',
    },
    https_port: {
      type: 'Variant[Integer, String]',
      desc: 'Docker repositories have Repository Connectors for https.',
      default: '',
    },
    force_basic_auth: {
      type: 'Variant[Boolean, String]',
      desc: 'Disable to allow anonymous pull (Note: also requires Docker Bearer Token Realm to be activated).',
      default: '',
    },
    v1_enabled: {
      type: 'Variant[Boolean, String]',
      desc: 'Allow clients to use the V1 API to interact with this Repository.',
      default: '',
    },

    # yum-specific #
    pgp_keypair: {
      type: 'String',
      desc: 'PGP signing key pair.',
      default: '',
    },
    pgp_keypair_passphrase: {
      type: 'String',
      desc: 'Passphrase of the PGP signing key pair.',
      default: '',
    },
  },
  autorequire: {
    file: Nexus3::Config.file_path,
  },
)
