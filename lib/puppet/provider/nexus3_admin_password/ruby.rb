require File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus3', 'api')

Puppet::Type.type(:nexus3_admin_password).provide(:ruby, parent: Puppet::Provider) do
  desc 'Ruby-based management of the Nexus 3 admin password.'

  def self.prefetch(resources)
    raise Puppet::Error, "There are more then 1 instance of '#{resources.values[0].class.name}': #{resources.keys.join(', ')}" if resources.size > 1
  end

  mk_resource_methods

  def password
    return 'ok' if resource[:old_password] && resource[:old_password] == resource[:password]
    return 'nok' if resource[:admin_password_file] && File.exist?(resource[:admin_password_file])
    Nexus3::API.service.ensure_running
    Nexus3::API.service.client.request(Net::HTTP::Get, '', 'application/json', nil, 'admin', resource[:password]) do |response|
      case response
      when Net::HTTPOK, Net::HTTPNoContent
        'ok'
      else
        'nok'
      end
    end
  end

  def password=(_value)
    Puppet.debug('Admin password is with an incorrect value. Trying to set the correct one.')
    old_password = resource[:admin_password_file] && File.exist?(resource[:admin_password_file]) ? File.read(resource[:admin_password_file]) : resource[:old_password]
    Nexus3::API.service.ensure_running
    command_name = Nexus3::API.upload_script("security.securitySystem.changePassword('admin', '#{resource[:password]}')", 'admin', old_password)
    begin
      Nexus3::API.run_command(command_name, 'admin', old_password)
      old_password = resource[:password]
    rescue
      # Ignored
    end
    Nexus3::API.delete_command(command_name, 'admin', old_password)
    Nexus3::Config.reset
    File.delete(resource[:admin_password_file]) if resource[:admin_password_file] && File.exist?(resource[:admin_password_file])
  end
end
