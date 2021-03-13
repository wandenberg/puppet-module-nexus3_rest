require 'erb'
require File.join(File.dirname(__FILE__), '..', 'nexus3_base')

Puppet::Type.type(:nexus3_privilege).provide(:ruby, parent: Puppet::Provider::Nexus3Base) do
  desc 'Ruby-based management of the Nexus 3 privilege.'

  def self.templates_folder
    File.join(File.dirname(__FILE__), 'templates')
  end

  def to_groovy_properties(key, value)
    case key
    when :provider, :ensure, :loglevel
      # Do nothing
    when :name
      "privilege.setName('#{value}')"
    when :type
      "privilege.setType('#{value}')"
    when :description
      "privilege.setDescription('#{value}')"
    when :script_name
      "privilege.properties.name = '#{value}'"
    when :repository_name
      "privilege.properties.repository = '#{value}'"
    else
      "privilege.properties['#{key.to_s.split('_').each_with_index.map { |item, index| index > 0 ? item.capitalize : item }.join}'] = '#{value}'"
    end
  end

  mk_resource_methods
end
