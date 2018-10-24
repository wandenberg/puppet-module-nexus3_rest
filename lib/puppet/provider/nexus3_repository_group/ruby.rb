require File.join(File.dirname(__FILE__), '..', 'nexus3_base')

Puppet::Type.type(:nexus3_repository_group).provide(:ruby, parent: Puppet::Provider::Nexus3Base) do
  desc 'Ruby-based management of the Nexus 3 repository group.'

  def self.templates_folder
    File.join(File.dirname(__FILE__), 'templates')
  end

  def destroy
    raise "The current configuration prevents the deletion of nexus_repository #{resource[:name]}; If this change is" +
              " intended, please update the configuration file (#{Nexus3::Config.file_path}) in order to perform this change." \
      unless Nexus3::Config.can_delete_repositories
    super
  end

  def delete_config_script
    "repository.repositoryManager.delete('#{resource[:name]}')"
  end

  mk_resource_methods

  def provider_type=(value)
    raise Puppet::Error, Puppet::Provider::Nexus3Base::WRITE_ONCE_ERROR_MESSAGE % 'provider_type'
  end

  def blobstore_name=(value)
    raise Puppet::Error, Puppet::Provider::Nexus3Base::WRITE_ONCE_ERROR_MESSAGE % 'blobstore_name'
  end
end
