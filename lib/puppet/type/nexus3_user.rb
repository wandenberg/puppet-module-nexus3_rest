require 'puppet/property/boolean'

Puppet::Type.newtype(:nexus3_user) do
  @doc = 'Manages Nexus 3 user.'

  ensurable

  newparam(:name, namevar: true) do
    desc 'Id of the user.'
  end

  newproperty(:firstname) do
    desc 'The first name of the user.'
    validate do |value|
      raise ArgumentError, 'First name must not be empty' if value.nil? || value.to_s.empty?
    end
  end

  newproperty(:lastname) do
    desc 'The last name of the user.'
    validate do |value|
      raise ArgumentError, 'Last name must not be empty' if value.nil? || value.to_s.empty?
    end
  end

  newparam(:password) do
    desc 'The password of the user.'
  end

  newproperty(:email) do
    desc 'The email of the user.'
    validate do |value|
      raise ArgumentError, 'Email must not be empty' if value.nil? || value.to_s.empty?
      raise ArgumentError, "Invalid email address '#{value}'." if value !~ /@/
    end
  end

  newproperty(:read_only, parent: Puppet::Property::Boolean) do
    desc 'When user is read only or not.'
    newvalues(:true, :false)
    defaultto :false
    munge { |value| super(value).to_s.intern }
  end

  newproperty(:status) do
    desc 'When user is activated or not.'
    newvalues(:active, :disabled)
  end

  newproperty(:roles, array_matching: :all) do
    desc 'A list of roles the user have'
    validate do |value|
      raise ArgumentError, 'roles must be provided in an array' if value.empty? || value.include?(',')
    end

    def insync?(is)
      is.sort == should.sort
    end
  end

  validate do
    if self[:ensure] == :present
      raise ArgumentError, 'roles must be provided as a non empty array' unless self[:roles].is_a?(Array) && !self[:roles].empty?
    end
  end

  autorequire(:file) do
    Nexus3::Config::file_path
  end
end
