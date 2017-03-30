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
    newvalues(:bower, :docker, :gitlfs, :maven2, :npm, :nuget, :pypi, :raw, :rubygems)
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

  # proxy-specific #
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
    end
  end

  autorequire(:file) do
    Nexus3::Config::file_path
  end
end
