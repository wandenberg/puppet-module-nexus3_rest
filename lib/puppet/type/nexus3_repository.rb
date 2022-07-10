# frozen_string_literal: true

require 'puppet/resource_api'
require 'puppet_x/nexus3/config'

Puppet::ResourceApi.register_type(
  name: 'nexus3_repository',
  docs: <<-EOS,
@summary a nexus3_repository type
@example
nexus3_repository { 'maven-central':
  type                           => 'proxy',
  provider_type                  => 'maven2',
  remote_url                     => 'https://repo1.maven.org/maven2/',
  layout_policy                  => 'permissive',
  strict_content_type_validation => false,
  auto_block                     => false,
}

This type provides Puppet with the capabilities to manage Nexus 3 Repository.

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
      desc: 'Unique repository identifier; once created cannot be changed unless the repository is destroyed. The Nexus UI will show it as repository id.',
      behaviour: :namevar,
    },
    type: {
      type: 'Enum[hosted, proxy]',
      desc: 'Type of this repository. Can be hosted or proxy; cannot be changed after creation without deleting the repository.',
    },
    provider_type: {
      type: 'Enum[apt, bower, cocoapods, conan, conda, docker, gitlfs, go, helm, maven2, npm, nuget, p2, pypi, r, raw, rubygems, yum]',
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
    cleanup_policies: {
      type: 'Array[String]',
      desc: 'A list of cleanup policies to apply to this repository',
      default: [],
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
    write_policy: {
      type: 'Pattern[/\A(read_only|allow_write_once|allow_write|allow_write_by_replication)?\z/]',
      desc: 'Controls if users are allowed to deploy or update artifacts in this repository. Responds to the \'Deployment Policy\' setting in the UI and is applicable for hosted repositories only.',
      default: '',
    },
    strict_content_type_validation: {
      type: 'Variant[Boolean, String]',
      desc: 'When should validate or not that all content uploaded to this repository is of a MIME type appropriate for the repository format.',
      default: '',
    },
    proprietary_components: {
      type: 'Variant[Boolean, String]',
      desc: 'Count components as proprietary for namespace conflict attacks (requires Sonatype Nexus Firewall).',
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

    # docker-proxy-specific #
    index_type: {
      type: 'Pattern[/\A(registry|hub|custom)?\z/]',
      desc: 'Docker proxy index_type
        * Use REGISTRY to use the proxy url for the index as well.
        * Use HUB to use the index from DockerHub.
        * Use CUSTOM in conjunction with the index_url param to
        * specify a custom index location.',
      default: '',
    },
    index_url: {
      type: 'String',
      desc: 'Docker proxy repository index_url param to specify a custom index location.',
      default: '',
    },
    cache_foreign_layers: {
      type: 'Variant[Boolean, String]',
      desc: 'Allow Nexus Repository Manager to download and cache foreign layers.',
      default: '',
    },
    foreign_layers_url_whitelist: {
      type: 'Array[String]',
      desc: 'Regular expressions used to identify URLs that are allowed for foreign layer requests',
      default: [],
    },

    # yum-specific #
    depth: {
      type: 'Variant[Integer, String]',
      desc: 'Depth in directory tree where repodata structure is created.',
      default: '',
    },

    # apt-specific #
    distribution: {
      type: 'String',
      desc: 'Distribution to fetch, for example trusty.',
      default: '',
    },
    is_flat: {
      type: 'Variant[Boolean, String]',
      desc: 'Is this repository flat?',
      default: '',
    },
    asset_history_limit: {
      type: 'Variant[Integer, String]',
      desc: 'Number of versions of each package to keep. If empty all versions will be kept.',
      default: '',
    },
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

    # bower-proxy-specific #
    rewrite_package_urls: {
      type: 'Variant[Boolean, String]',
      desc: 'Force Bower to retrieve packages through the proxy repository.',
      default: '',
    },

    # npm-proxy-specific #
    remove_non_cataloged: {
      type: 'Variant[Boolean, String]',
      desc: 'Non-cataloged versions will not be downloaded. IQ: Audit and Quarantine capability must be enabled for this feature to take effect.',
      default: '',
    },
    remove_quarantined_versions: {
      type: 'Variant[Boolean, String]',
      desc: 'Non-cataloged versions will not be downloaded. IQ: Audit and Quarantine capability must be enabled for this feature to take effect.',
      default: '',
    },

    # nuget-proxy-specific #
    nuget_version: {
      type: 'Pattern[/\A(V2|V3)?\z/]',
      desc: 'NuGet protocol version.',
      default: '',
    },
    query_cache_item_max_age: {
      type: 'Variant[Integer, String]',
      desc: 'How long to cache query results from the proxied repository (in seconds)',
      default: '',
    },

    # proxy-specific #
    auto_block: {
      type: 'Variant[Boolean, String]',
      desc: 'Whether to automatically block outbound connections to remote repository in case of unresponsiveness. Only useful for proxy-type repositories.',
      default: '',
    },
    blocked: {
      type: 'Variant[Boolean, String]',
      desc: 'Whether to block connection to remote repository. Only useful for proxy-type repositories.',
      default: '',
    },
    negative_cache_enabled: {
      type: 'Variant[Boolean, String]',
      desc: 'Whether to cache responses for content not present in the proxied repository. Only useful for proxy-type repositories.',
      default: '',
    },
    negative_cache_ttl: {
      type: 'Variant[Integer, String]',
      desc: 'How long to cache the fact that a file was not found in the repository (in minutes). Only useful for proxy-type repositories.',
      default: '',
    },
    remote_url: {
      type: 'String',
      desc: 'This is the location of the remote repository being proxied. Only HTTP/HTTPs urls are currently supported. Only useful for proxy-type repositories.',
      default: '',
    },
    content_max_age: {
      type: 'Variant[Integer, String]',
      desc: 'How long (in minutes) to cache artifacts before rechecking the remote repository. Release repositories should use -1. Only useful for proxy-type repositories.',
      default: '',
    },
    metadata_max_age: {
      type: 'Variant[Integer, String]',
      desc: 'How long (in minutes) to cache metadata before rechecking the remote repository. Only useful for proxy-type repositories.',
      default: '',
    },
    remote_auth_type: {
      type: 'Pattern[/\A(none|username|ntlm|bearerToken)\z/]',
      desc: 'Define the type of authentication to be used to the remote repository.',
      default: 'none',
    },
    remote_bearer_token: {
      type: 'String',
      desc: 'The token used for authentication to the NPM remote repository. Only useful for proxy-type repositories.',
      default: '',
    },
    remote_user: {
      type: 'String',
      desc: 'The username used for authentication to the remote repository. Only useful for proxy-type repositories.',
      default: '',
    },
    remote_password: {
      type: 'String',
      desc: 'The password used for authentication to the remote repository. Will be only used if `remote_password` is set to `present`. Only useful for proxy-type repositories.',
      default: '',
    },
    remote_ntlm_host: {
      type: 'String',
      desc: 'The Windows NT Lan Manager host for authentication to the remote repository. Only useful for proxy-type repositories.',
      default: '',
    },
    remote_ntlm_domain: {
      type: 'String',
      desc: 'The Windows NT Lan Manager domain for authentication to the remote repository. Only useful for proxy-type repositories.',
      default: '',
    },
    remote_user_agent: {
      type: 'String',
      desc: 'Custom fragment to append to "User-Agent" header in HTTP requests. Only useful for proxy-type repositories.',
      default: '',
    },
    remote_retries: {
      type: 'Variant[Integer, String]',
      desc: 'Total retries if the initial connection attempt suffers a timeout. Only useful for proxy-type repositories.',
      default: '',
    },
    remote_connection_timeout: {
      type: 'Variant[Integer, String]',
      desc: 'Seconds to wait for activity before stopping and retrying the connection. Leave blank to use the globally defined HTTP timeout. Only useful for proxy-type repositories.',
      default: '',
    },
    remote_enable_circular_redirects: {
      type: 'Variant[Boolean, String]',
      desc: 'Enable redirects to the same location (may be required by some servers). Only useful for proxy-type repositories.',
      default: '',
    },
    remote_enable_cookies: {
      type: 'Variant[Boolean, String]',
      desc: 'Allow cookies to be stored and used. Only useful for proxy-type repositories.',
      default: '',
    },
    routing_rule: {
      type: 'String',
      desc: 'The routing rule to be used while sending requests to proxied server.',
      default: '',
    },
  },
  autorequire: {
    file: Nexus3::Config.file_path,
  },
)
