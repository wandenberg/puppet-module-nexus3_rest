require 'erb'
require File.join(File.dirname(__FILE__), '..', 'nexus3_base')

Puppet::Type.type(:nexus3_task).provide(:ruby, parent: Puppet::Provider::Nexus3Base) do
  desc 'Ruby-based management of the Nexus 3 task.'

  def self.templates_folder
    File.join(File.dirname(__FILE__), 'templates')
  end

  mk_resource_methods

  def self.map_config_to_resource(config)
    resource_hash = super(config)

    Nexus3::Task::FIELDS.select { |field| field.type == 'boolean' }.each do |field|
      key = field.key.to_sym
      resource_hash[key] = resource_hash[key].to_s
    end

    resource_hash
  end

  def id=(_value)
    raise Puppet::Error, Puppet::Provider::Nexus3Base::WRITE_ONCE_ERROR_MESSAGE % 'id'
  end

  def type=(_value)
    raise Puppet::Error, Puppet::Provider::Nexus3Base::WRITE_ONCE_ERROR_MESSAGE % 'type'
  end
end
