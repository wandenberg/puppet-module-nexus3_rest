require 'puppet/property/boolean'

Puppet::Type.newtype(:nexus3_admin_password) do
  @doc = 'Manages Nexus 3 admin password.'

  newparam(:name, namevar: true) do
    desc 'Resource ID.'
  end

  newparam(:admin_password_file) do
    desc 'Use this admin.password file on a new setup.'
  end

  newparam(:old_password) do
    desc 'The old password of the user.'

    validate do |value|
      raise ArgumentError, 'old_password must be provided.' if value.empty?
    end
  end

  newproperty(:password) do
    desc 'The password of the user.'
    # rubocop:disable Naming/PredicateName
    def is_to_s(_current_value)
      '[old password]'
    end

    def should_to_s(_new_value)
      '[new password]'
    end

    def change_to_s(_current_value, _new_value)
      '[check if the correct password is assigned]'
    end

    def insync?(is)
      is == 'ok'
    end

    validate do |value|
      raise ArgumentError, 'password must be provided.' if value.empty?
    end
  end

  autorequire(:file) do
    Nexus3::Config.file_path
  end
end
