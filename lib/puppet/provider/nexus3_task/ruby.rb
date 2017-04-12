require 'erb'
require File.join(File.dirname(__FILE__), '..', 'nexus3_base')

Puppet::Type.type(:nexus3_task).provide(:ruby, parent: Puppet::Provider::Nexus3Base) do
  desc 'Ruby-based management of the Nexus 3 task.'

  def self.templates_folder
    File.join(File.dirname(__FILE__), 'templates')
  end

  mk_resource_methods

  def id=(value)
    raise Puppet::Error, Puppet::Provider::Nexus3Base::WRITE_ONCE_ERROR_MESSAGE % 'id'
  end

  def type=(value)
    raise Puppet::Error, Puppet::Provider::Nexus3Base::WRITE_ONCE_ERROR_MESSAGE % 'type'
  end
end
