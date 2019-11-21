require 'puppet/property/boolean'

Puppet::Type.newtype(:nexus3_repository) do
  @doc = 'Manages Nexus 3 Repository'

  ensurable

  newparam(:name, namevar: true) do
    desc 'Unique repository identifier; once created cannot be changed unless the repository is destroyed. The Nexus UI will show it as repository id.'
  end

  newproperty(:type) do
    desc 'Type of this repository. Can be hosted or proxy; cannot be changed after creation without deleting the repository.'
    newvalues(:hosted, :proxy)
  end

  newproperty(:provider_type) do
    desc 'The content provider of the repository'
    newvalues(:apt, :bower, :composer, :docker, :gitlfs, :maven2, :npm, :nuget, :pypi, :raw, :rubygems, :yum)
  end

  newproperty(:online, parent: Puppet::Property::Boolean) do
    desc 'When repository is enabled or not to receive connections.'
    newvalues(:true, :false)
    defaultto :true
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:blobstore_name) do
    desc 'The blobstore name to store data of the repository'
    defaultto 'default'
  end

  newproperty(:cleanup_policies, array_matching: :all) do
    desc 'A list of cleanup policies to apply to this repository'
    defaultto []
    validate do |value|
      raise ArgumentError, 'cleanup policies must be provided as array' if value.empty? || value.include?(',')
    end

    def insync?(is)
      is.sort == should.sort
    end
  end

  newproperty(:version_policy) do
    desc 'Maven2 repositories can store release, snapshot or mixed artifacts.'
    defaultto do @resource[:provider_type] == :maven2 ? :release : nil end
    newvalues(:snapshot, :release, :mixed)
  end

  newproperty(:layout_policy) do
    desc 'Maven2 repositories can check if all paths are maven artifact or metadata paths.'
    defaultto do @resource[:provider_type] == :maven2 ? :strict : nil end
    newvalues(:strict, :permissive)
  end

  newproperty(:write_policy) do
    desc 'Controls if users are allowed to deploy and/or update artifacts in this repository. Responds to the \'Deployment Policy\' setting in the UI and is applicable for hosted repositories only.'
    defaultto do @resource[:type] == :hosted ? :allow_write_once : nil end
    newvalues(:read_only, :allow_write_once, :allow_write)
  end

  newproperty(:strict_content_type_validation, parent: Puppet::Property::Boolean) do
    desc 'When should validate or not that all content uploaded to this repository is of a MIME type appropriate for the repository format.'
    newvalues(:true, :false)
    defaultto :true
    munge { |value| super(value).to_s.intern }
  end

  # docker-specific #
  newproperty(:http_port) do
    desc 'Docker repositories have Repository Connectors for http and https.'
  end

  newproperty(:https_port) do
    desc 'Docker repositories have Repository Connectors for http and https.'
  end

  newproperty(:force_basic_auth) do
    desc 'Disable to allow anonymous pull (Note: also requires Docker Bearer Token Realm to be activated)'
    defaultto do @resource[:provider_type] == :docker ? :true : nil end
    newvalues(:true, :false)
  end

  newproperty(:v1_enabled) do
    desc 'Allow clients to use the V1 API to interact with this Repository'
    defaultto do @resource[:provider_type] == :docker ? :true : nil end
    newvalues(:true, :false)
  end

  # docker-proxy-specific #
  newproperty(:index_type) do
    desc 'Docker proxy index_type
    * Use REGISTRY to use the proxy url for the index as well.
    * Use HUB to use the index from DockerHub.
    * Use CUSTOM in conjunction with the index_url param to
    * specify a custom index location '
    defaultto do ((@resource[:provider_type] == :docker) && (@resource[:type] == :proxy)) ? :registry : nil end
    newvalues(:registry, :hub, :custom)
  end

  newproperty(:index_url) do
    desc 'Docker proxy repository index_url param to specify a custom index location'
  end

  # yum-specific #
  newproperty(:depth) do
    desc 'Depth in directory tree where repodata structure is created.'
    newvalues(0, 1, 2, 3, 4, 5)
    defaultto do @resource[:provider_type] == :yum ? 0 : nil end
    munge { |value| super(value).to_s }
  end

  # apt-specific #
  newproperty(:distribution) do
    desc 'Distribution to fetch, for example trusty.'
  end

  newproperty(:is_flat) do
    desc 'Is this repository flat?'
    newvalues(:true, :false)
    defaultto do ((@resource[:provider_type] == :apt) && (@resource[:type] == :proxy)) ? :false : nil end
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:asset_history_limit) do
    desc 'Number of versions of each package to keep. If empty all versions will be kept.'
  end

  newproperty(:pgp_keypair) do
    desc 'PGP signing key pair.'
  end

  newproperty(:pgp_keypair_passphrase) do
    desc 'Passphrase of the PGP signing key pair.'
  end

  # proxy-specific #
  newproperty(:auto_block, parent: Puppet::Property::Boolean) do
    desc 'Whether to automatically block outbound connections to remote repository in case of unresponsiveness.' \
         'Only useful for proxy-type repositories.'
    newvalues(:true, :false)
    defaultto do @resource[:type] == :proxy ? :true : nil end
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:blocked, parent: Puppet::Property::Boolean) do
    desc 'Whether to block connection to remote repository.' \
         'Only useful for proxy-type repositories.'
    newvalues(:true, :false)
    defaultto do @resource[:type] == :proxy ? :false : nil end
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:remote_url) do
    desc 'This is the location of the remote repository being proxied. Only HTTP/HTTPs urls are currently supported. ' \
         'Only useful for proxy-type repositories.'
  end

  newproperty(:remote_auth_type) do
    desc 'Define the type of authentication to be used to the remote repository.'
    defaultto do @resource[:provider_type] == :maven2 ? :username : :none end
    newvalues(:none, :username, :ntlm)
  end

  newproperty(:remote_user) do
    desc 'The username used for authentication to the remote repository. ' \
         'Only useful for proxy-type repositories.'
  end

  newproperty(:remote_password) do
    desc 'The password used for authentication to the remote repository. ' \
         'Will be only used if `remote_password` is set to `present`. ' \
         'Only useful for proxy-type repositories.'
    def is_to_s(current_value)
      '[old password]'
    end

    def should_to_s(new_value)
      '[new password]'
    end

    def change_to_s(current_value, new_value)
      '[old password] to [new password]'
    end
  end

  newproperty(:remote_ntlm_host) do
    desc 'The Windows NT Lan Manager for authentication to the remote repository. ' \
         'Only useful for proxy-type repositories.'
  end

  newproperty(:remote_ntlm_domain) do
    desc 'The Windows NT Lan Manager domain for authentication to the remote repository. ' \
         'Only useful for proxy-type repositories.'
  end

  validate do
    if self[:ensure] == :present
      raise ArgumentError, 'blobstore_name must be provided' if self[:blobstore_name].to_s.empty?
      raise ArgumentError, 'provider_type must be provided' if self[:provider_type].to_s.empty?
      raise ArgumentError, 'type must be provided' if self[:type].to_s.empty?
    end
  end

  autorequire(:file) do
    Nexus3::Config::file_path
  end
end
