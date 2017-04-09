require File.join(File.dirname(__FILE__), '..', 'nexus3_base')

Puppet::Type.type(:nexus3_anonymous_settings).provide(:ruby, parent: Puppet::Provider::Nexus3Base) do
  desc 'Ruby-based management of the Nexus 3  Anonymous settings.'

  def self.templates_folder
    File.join(File.dirname(__FILE__), 'templates')
  end

  def self.max_instances_allowed
    1
  end

  mk_resource_methods
end
