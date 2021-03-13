require 'puppet/property/boolean'

Puppet::Type.newtype(:nexus3_repository_group) do
  @doc = 'Manages Nexus 3 Repository Group'

  ensurable

  newparam(:name, namevar: true) do
    desc 'Unique repository group identifier; once created cannot be changed unless the repository group is destroyed. The Nexus UI will show it as group id.'
  end

  newproperty(:provider_type) do
    desc 'The content provider of the repository'
    newvalues(:bower, :composer, :docker, :maven2, :npm, :nuget, :pypi, :raw, :rubygems, :yum)
    validate do |value|
      super(value)
      raise ArgumentError, 'provider_type must be provided' if value.empty?
    end
  end

  newproperty(:blobstore_name) do
    desc 'The blobstore name to store data of the repository'
    defaultto 'default'
  end

  newproperty(:online, parent: Puppet::Property::Boolean) do
    desc 'When repository is enabled or not to receive connections.'
    newvalues(:true, :false)
    defaultto :true
    munge { |value| super(value).to_s.to_sym }
  end

  newproperty(:repositories, array_matching: :all) do
    desc 'A list of repositories contained in this Repository Group'
    validate do |value|
      raise ArgumentError, 'repositories in group must be provided in an array' if value.empty? || value.include?(',')
    end
  end

  newproperty(:http_port) do
    desc 'Docker repositories have Repository Connectors for http and https.'
  end

  newproperty(:https_port) do
    desc 'Docker repositories have Repository Connectors for http and https.'
  end

  newproperty(:force_basic_auth) do
    desc 'Disable to allow anonymous pull (Note: also requires Docker Bearer Token Realm to be activated)'
    defaultto { @resource[:provider_type] == :docker ? :true : nil }
    newvalues(:true, :false)
  end

  newproperty(:v1_enabled) do
    desc 'Allow clients to use the V1 API to interact with this Repository'
    defaultto { @resource[:provider_type] == :docker ? :true : nil }
    newvalues(:true, :false)
  end

  newproperty(:strict_content_type_validation, parent: Puppet::Property::Boolean) do
    desc 'When should validate or not that all content uploaded to this repository is of a MIME type appropriate for the repository format.'
    newvalues(:true, :false)
    defaultto :true
    munge { |value| super(value).to_s.to_sym }
  end

  validate do
    if self[:ensure] == :present
      raise ArgumentError, 'blobstore_name must be provided' if self[:blobstore_name].to_s.empty?
      raise ArgumentError, 'provider_type must be provided' if self[:provider_type].to_s.empty?
      raise ArgumentError, 'repositories in group must be provided as a non empty array' unless self[:repositories].is_a?(Array) && !self[:repositories].empty?
    end
  end

  autorequire(:file) do
    Nexus3::Config.file_path
  end
end
