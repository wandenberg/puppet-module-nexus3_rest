require 'erb'
require File.join(File.dirname(__FILE__), '..', 'nexus3_base')

Puppet::Type.type(:nexus3_repository).provide(:ruby, parent: Puppet::Provider::Nexus3Base) do
  desc 'Ruby-based management of the Nexus 3 repository.'

  WRITE_POLICY_MAPPING = {
      read_only: 'DENY',
      allow_write_once: 'ALLOW_ONCE',
      allow_write: 'ALLOW'
  }

  def self.templates_folder
    File.join(File.dirname(__FILE__), 'templates')
  end

  def destroy
    raise "The current configuration prevents the deletion of nexus_repository #{resource[:name]}; If this change is" +
              " intended, please update the configuration file (#{Nexus3::Config.file_path}) in order to perform this change." \
      unless Nexus3::Config.can_delete_repositories

    super
  end

  def self.map_config_to_resource(config)
    resource_hash = super(config)
    resource_hash[:write_policy] = WRITE_POLICY_MAPPING.invert[resource_hash[:write_policy]]
    resource_hash
  end

  mk_resource_methods

  def type=(value)
    raise Puppet::Error, Puppet::Provider::Nexus3Base::WRITE_ONCE_ERROR_MESSAGE % 'type'
  end

  def provider_type=(value)
    raise Puppet::Error, Puppet::Provider::Nexus3Base::WRITE_ONCE_ERROR_MESSAGE % 'provider_type'
  end

  def version_policy=(value)
    raise Puppet::Error, Puppet::Provider::Nexus3Base::WRITE_ONCE_ERROR_MESSAGE % 'version_policy'
  end

  def blobstore_name=(value)
    raise Puppet::Error, Puppet::Provider::Nexus3Base::WRITE_ONCE_ERROR_MESSAGE % 'blobstore_name'
  end

  def write_policy=(value)
    raise Puppet::Error, Puppet::Provider::Nexus3Base::WRITE_ONCE_ERROR_MESSAGE % 'write_policy' unless resource[:type] == :hosted
    mark_config_dirty if @property_hash[:write_policy] != value
    @property_hash[:write_policy] = value
  end
end
