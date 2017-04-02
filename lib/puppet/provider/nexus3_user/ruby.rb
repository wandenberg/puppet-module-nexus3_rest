require File.join(File.dirname(__FILE__), '..', 'nexus3_base')

Puppet::Type.type(:nexus3_user).provide(:ruby, parent: Puppet::Provider::Nexus3Base) do
  desc 'Ruby-based management of the Nexus 3 user.'

  def self.templates_folder
    File.join(File.dirname(__FILE__), 'templates')
  end

  def delete_config_script
    "security.securitySystem.deleteUser('#{resource[:name]}')"
  end

  mk_resource_methods
end
