require 'puppet/property/boolean'

Puppet::Type.newtype(:nexus3_role) do
  @doc = 'Manages Nexus 3 Role'

  ensurable

  newparam(:name, namevar: true) do
    desc 'Unique role name.'
  end

  newproperty(:role_name) do
    desc 'The title of the role.'
  end

  newproperty(:description) do
    desc 'The description of the role'
  end

  newproperty(:read_only, parent: Puppet::Property::Boolean) do
    desc 'When role is read only or not.'
    newvalues(:true, :false)
    defaultto :false
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:source) do
    desc 'The source of the role.'
  end

  newproperty(:roles, array_matching: :all) do
    desc 'A list of roles names'
    defaultto []
    validate do |value|
      raise ArgumentError, "roles names must be provided in an array" if value.empty? || value.include?(',')
    end

    def insync?(is)
      is.sort == should.sort
    end
  end

  newproperty(:privileges, array_matching: :all) do
    desc 'A list of privileges names'
    defaultto []
    validate do |value|
      raise ArgumentError, "privileges names must be provided in an array" if value.empty? || value.include?(',')
    end

    def insync?(is)
      is.sort == should.sort
    end
  end

  autorequire(:file) do
    Nexus3::Config::file_path
  end
end
