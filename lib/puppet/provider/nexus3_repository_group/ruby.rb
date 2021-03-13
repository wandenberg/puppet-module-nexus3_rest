require File.join(File.dirname(__FILE__), '..', 'nexus3_base')

Puppet::Type.type(:nexus3_repository_group).provide(:ruby, parent: Puppet::Provider::Nexus3Base) do
  desc 'Ruby-based management of the Nexus 3 repository group.'

  def self.templates_folder
    File.join(File.dirname(__FILE__), 'templates')
  end

  def delete_config_script
    "repository.repositoryManager.delete('#{resource[:name]}')"
  end

  mk_resource_methods

  def provider_type=(_value)
    raise Puppet::Error, Puppet::Provider::Nexus3Base::WRITE_ONCE_ERROR_MESSAGE % 'provider_type'
  end

  def blobstore_name=(_value)
    raise Puppet::Error, Puppet::Provider::Nexus3Base::WRITE_ONCE_ERROR_MESSAGE % 'blobstore_name'
  end
end
