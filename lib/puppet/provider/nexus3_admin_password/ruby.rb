require File.join(File.dirname(__FILE__), '..', '..', '..', 'puppet_x', 'nexus3', 'api')

Puppet::Type.type(:nexus3_admin_password).provide(:ruby, parent: Puppet::Provider) do
  desc 'Ruby-based management of the Nexus 3 admin password.'

  def self.prefetch(resources)
    raise Puppet::Error, "There are more then 1 instance of '#{resources.values[0].class.name}': #{resources.keys.join(', ')}" if resources.size > 1
  end

  def flush
    if resource[:old_password] != resource[:password]
      Nexus3::API.service.ensure_running
      Nexus3::API.service.client.request(Net::HTTP::Get, '', 'application/json', nil, 'admin', resource[:password]) do |response|
        case response
          when Net::HTTPOK, Net::HTTPNoContent
            Puppet.debug('Admin password is already with the correct value')
          else
            Puppet.debug('Admin password is with a incorrect value. Trying to set the correct one')
            command_name = Nexus3::API.upload_script("security.securitySystem.changePassword('admin','#{ resource[:password] }')", 'admin', resource[:old_password])
            begin
              Nexus3::API.run_command(command_name, 'admin', resource[:old_password])
              Nexus3::API.delete_command(command_name, 'admin', resource[:password])
            rescue
              Nexus3::API.delete_command(command_name, 'admin', resource[:old_password])
            end
            Nexus3::Config.reset
        end
      end
    end
  end

  mk_resource_methods
end
