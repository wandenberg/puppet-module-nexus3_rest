require 'json'
require 'yaml'
require 'securerandom'
require 'net/http'
require File.join(File.dirname(__FILE__), '..', 'nexus3')
require File.join(File.dirname(__FILE__), 'config')
require File.join(File.dirname(__FILE__), 'service')

# Class that wraps the calls to Nexus3 Script API
class Nexus3::API
  def self.execute_script(script)
    command_name = upload_script(script)
    begin
      result = run_command(command_name)
    ensure
      delete_command(command_name)
    end
    result
  end

  def self.upload_script(script, username = nil, password = nil)
    service.ensure_running
    command_name = SecureRandom.hex

    data = {
      'name' => command_name,
      'type' => 'groovy',
      'content' => script
    }

    service.client.request(Net::HTTP::Post, '', 'application/json', data.to_json, username, password) do |response|
      case response
      when Net::HTTPNoContent
        command_name
      else
        raise "Could not upload the script due to '#{response.code}' '#{response.body}'"
      end
    end
  end

  def self.run_command(command_name, username = nil, password = nil)
    service.ensure_running
    service.client.request(Net::HTTP::Post, "#{command_name}/run", 'text/plain', nil, username, password) do |response|
      case response
      when Net::HTTPOK
        JSON.parse(response.body)['result']
      else
        raise "Could not run the command due to '#{response.code}' '#{response.body}'"
      end
    end
  end

  def self.delete_command(command_name, username = nil, password = nil)
    service.ensure_running
    service.client.request(Net::HTTP::Delete, command_name, 'application/json', nil, username, password) do |response|
      raise "Could not delete the command due to '#{response.code}'" unless response.is_a?(Net::HTTPNoContent)
    end
  end

  def self.until_version(ver)
    version < ver
  end

  def self.service
    @service ||= init_service
  end

  def self.init_service
    Nexus3::Config.configure do |_nexus_base_url, options|
      client = Nexus3::Service::Client.new(options)
      service = Nexus3::Service.new(client, options)
      Nexus3::CachingService.new(service)
    end
  end

  def self.version
    @version ||= nexus3_server_version
  end

  def self.nexus3_server_version
    get_version = <<-SCRIPT
      clazz = null
      try {
        Class.forName("com.sonatype.nexus.edition.oss.ApplicationVersionImpl")
        clazz = container.lookup(com.sonatype.nexus.edition.oss.ApplicationVersionImpl.class.name)
      } catch (ClassNotFoundException e) {
        clazz = container.lookup(com.sonatype.nexus.edition.pro.ApplicationVersionImpl.class.name)
      }
      return clazz.getVersion()
    SCRIPT

    result = execute_script(get_version)
    result.split('.')[0..1].join('.').to_f
  rescue
    3.19
  end
end
