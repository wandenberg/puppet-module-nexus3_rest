# frozen_string_literal: true

require 'puppet/resource_api'
require 'puppet_x/nexus3/config'

Puppet::ResourceApi.register_type(
  name: 'nexus3_cleanup_policy',
  docs: <<-EOS,
@summary a nexus3_cleanup_policy type
@example
nexus3_cleanup_policy { 'policy_all':
  format => 'all',
}

This type provides Puppet with the capabilities to manage Nexus 3 Cleanup Policy.

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
      desc: 'Unique cleanup policy name.',
      behaviour: :namevar,
    },
    format: {
      type: 'Enum[all, apt, bower, cocoapods, conan, conda, docker, gitlfs, go, helm, maven2, npm, nuget, p2, pypi, r, raw, rubygems, yum]',
      desc: 'The repository format the policy should apply to (can also be "all").',
      default: 'all',
    },
    notes: {
      type: 'String',
      desc: 'A short description of the policy.',
      default: '',
    },
    is_prerelease: {
      type: 'Variant[Boolean, String]',
      desc: 'Restrict cleanup to components of release type "release" or "prerelease". This is applicable to "maven2", "npm", or "yum" format repos only.',
      default: '',
    },
    last_blob_updated: {
      type: 'Variant[Integer, String]',
      desc: 'Restrict cleanup to components last updated before this number of days.',
      default: '',
    },
    last_downloaded: {
      type: 'Variant[Integer, String]',
      desc: 'Restrict cleanup to components last downloaded before this number of days.',
      default: '',
    },
    regex: {
      type: 'String',
      desc: 'Restrict cleanup to components whose names match this regular expression. Not applicable to "all" and "gitlfs" format repos.',
      default: '',
    },
  },
  autorequire: {
    file: Nexus3::Config.file_path,
  },
)
