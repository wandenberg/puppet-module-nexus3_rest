require File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus3', 'api')

Puppet::Type.type(:nexus3_admin_password).provide(:ruby, parent: Puppet::Provider) do
  desc 'Ruby-based management of the Nexus 3 admin password.'

  def self.prefetch(resources)
    raise Puppet::Error, "There are more then 1 instance of '#{resources.values[0].class.name}': #{resources.keys.join(', ')}" if resources.size > 1
  end

  def flush
    if resource[:admin_password_file]
      # needed for the admin.password file to be created
      Nexus3::API.service.ensure_running
      set_password = !File.exist?("#{resource[:admin_password_file]}.set")
      if File.exist?(resource[:admin_password_file])
        old_password = File.read(resource[:admin_password_file])
      end
    else
      old_password = resource[:old_password]
      set_password = old_password != resource[:password]
    end

    if set_password
      Nexus3::API.service.ensure_running
      Nexus3::API.service.client.request(Net::HTTP::Get, '', 'application/json', nil, 'admin', resource[:password]) do |response|
        case response
          when Net::HTTPOK, Net::HTTPNoContent
            Puppet.debug('Admin password is already with the correct value')
          else
            Puppet.debug('Admin password is with a incorrect value. Trying to set the correct one')
            command_name = Nexus3::API.upload_script("security.securitySystem.changePassword('admin', '#{ resource[:password] }')", 'admin', old_password)
            begin
              Nexus3::API.run_command(command_name, 'admin', old_password)
              Nexus3::API.delete_command(command_name, 'admin', resource[:password])
            rescue
              Nexus3::API.delete_command(command_name, 'admin', old_password)
            end
            Nexus3::Config.reset
        end
      end
      File.rename(resource[:admin_password_file], "#{resource[:admin_password_file]}.set") if resource[:admin_password_file]
    end
  end

  mk_resource_methods
end
