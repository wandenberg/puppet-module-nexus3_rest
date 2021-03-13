require 'puppet/property/boolean'

Puppet::Type.newtype(:nexus3_smtp_settings) do
  @doc = 'Manages Nexus 3 SMTP settings.'

  newparam(:name, namevar: true) do
    desc 'Name of the configuration.'
  end

  newproperty(:hostname) do
    desc 'The host name of the SMTP server.'
    validate do |value|
      raise ArgumentError, 'Hostname must not be empty' if value.to_s.empty?
    end
  end

  newproperty(:port) do
    desc 'The port number the SMTP server is listening on. Must be within 1 and 65535.'
    defaultto 25
    validate do |value|
      raise ArgumentError, "Port must be a non-negative integer, got #{value}" unless %r{\d+}.match?(value.to_s)
      raise ArgumentError, "Port must within [1, 65535], got #{value}" unless (1..65_535).cover?(value.to_i)
    end
    munge { |value| Integer(value) }
  end

  newproperty(:enabled, parent: Puppet::Property::Boolean) do
    desc 'When SMTP settings is enabled or not.'
    newvalues(:true, :false)
    defaultto :false
    munge { |value| super(value).to_s.to_sym }
  end

  newproperty(:username) do
    desc 'The username used to access the SMTP server.'
  end

  newparam(:password) do
    desc 'The expected value of the password.'
  end

  newproperty(:sender_email) do
    desc 'Email address used in the `From:` field.'
    validate do |value|
      raise ArgumentError, 'Sender email must not be empty' if value.to_s.empty?
      raise ArgumentError, "Invalid email address '#{value}'." unless %r{@}.match?(value.to_s)
    end
  end

  newproperty(:subject_prefix) do
    desc 'Email subject prefix.'
  end

  autorequire(:file) do
    Nexus3::Config.file_path
  end
end
