require 'puppet/property/boolean'

Puppet::Type.newtype(:nexus3_cleanup_policy) do
  @doc = 'Manages Nexus 3 Cleanup Policy'

  ensurable

  newparam(:name, namevar: true) do
    desc 'Unique cleanup policy name.'
  end

  newproperty(:format) do
    desc 'The repository format the policy should apply to (can also be "all").'
    newvalues(:all, :apt, :bower, :composer, :docker, :gitlfs, :maven2, :npm, :nuget, :pypi, :raw, :rubygems, :yum)
    defaultto :all
  end

  newproperty(:notes) do
    desc 'A short description of the policy.'
    defaultto ''
  end

  newproperty(:is_prerelease, parent: Puppet::Property::Boolean) do
    desc 'Restrict cleanup to components of release type "release" or "prerelease".' \
         'This is applicable to "maven2", "npm", or "yum" format repos only.'
    newvalues(:true, :false)
    defaultto do @resource[:format] in [:maven2, :npm, :yum] ? :false : nil end
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:last_blob_updated) do
    desc 'Restrict cleanup to components last updated before this number of days.'
    munge { |value| Integer(value) }
  end

  newproperty(:last_downloaded) do
    desc 'Restrict cleanup to components last downloaded before this number of days.'
    munge { |value| Integer(value) }
  end

  newproperty(:regex) do
    desc 'Restrict cleanup to components whose names match this regular expression.'
  end

  validate do
    if self[:ensure] == :present
      raise ArgumentError, 'At least one criteria must be provided' if self[:is_prerelease].nil? &&
                                                                       self[:last_blob_updated].nil? &&
                                                                       self[:last_downloaded].nil? &&
                                                                       self[:regex].nil?
    end
  end

  autorequire(:file) do
    Nexus3::Config::file_path
  end
end
