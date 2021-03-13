require 'puppet/property/boolean'

Puppet::Type.newtype(:nexus3_privilege) do
  @doc = 'Manages Nexus 3 Privilege'

  ensurable

  newparam(:name, namevar: true) do
    desc 'Unique privilege name.'
  end

  newproperty(:type) do
    desc 'The type of the privilege'
  end

  newproperty(:description) do
    desc 'The description of the privilege'
  end

  newproperty(:pattern) do
    desc 'The regex pattern'
  end

  newproperty(:domain) do
    desc 'The domain for the privilege'
  end

  newproperty(:actions) do
    desc 'The comma-delimited list of actions'
  end

  newproperty(:format) do
    desc 'The format(s) for the repository'
  end

  newproperty(:repository_name) do
    desc 'The repository name'
  end

  newproperty(:script_name) do
    desc 'The name of the script'
  end

  newproperty(:content_selector) do
    desc 'The name of the script'
  end

  autorequire(:file) do
    Nexus3::Config.file_path
  end
end
