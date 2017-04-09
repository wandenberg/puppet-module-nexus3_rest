require 'puppet/property/boolean'

Puppet::Type.newtype(:nexus3_realm_settings) do
  @doc = 'Manages Nexus 3 Realm settings.'

  newparam(:name, namevar: true) do
    desc 'Name of the configuration.'
  end

  newproperty(:names, array_matching: :all) do
    desc 'A list of realms names'
    validate do |value|
      raise ArgumentError, 'realms names must be provided in an array' if value.empty? || value.include?(',')
    end
  end

  autorequire(:file) do
    Nexus3::Config::file_path
  end
end
