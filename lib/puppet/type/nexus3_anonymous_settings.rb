require 'puppet/property/boolean'

Puppet::Type.newtype(:nexus3_anonymous_settings) do
  @doc = 'Manages Nexus 3 Anonymous settings.'

  newparam(:name, namevar: true) do
    desc 'Name of the Anonymous settings.'
  end

  newproperty(:username) do
    desc 'Username of the  Anonymous settings.'
  end

  newproperty(:realm) do
    desc 'The realm name of the Anonymous settings.'
  end

  newproperty(:enabled, parent: Puppet::Property::Boolean) do
    desc 'When Anonymous user can access the server or not.'
    newvalues(:true, :false)
    defaultto :false
    munge { |value| super(value).to_s.to_sym }
  end

  autorequire(:file) do
    Nexus3::Config.file_path
  end
end
