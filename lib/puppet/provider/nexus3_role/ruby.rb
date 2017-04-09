require 'erb'
require File.join(File.dirname(__FILE__), '..', 'nexus3_base')

Puppet::Type.type(:nexus3_role).provide(:ruby, parent: Puppet::Provider::Nexus3Base) do
  desc 'Ruby-based management of the Nexus 3 role.'

  def self.templates_folder
    File.join(File.dirname(__FILE__), 'templates')
  end

  mk_resource_methods
end
