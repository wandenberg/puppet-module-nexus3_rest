require 'json'
require 'puppet'
require 'yaml'
require File.join(File.dirname(__FILE__), '..', 'nexus3')

# Class that wraps the configurations to access the Nexus3 Script API
class Nexus3::Config
  CONFIG_NEXUS_BASE_URL = :nexus_base_url
  CONFIG_NEXUS_SCRIPT_API_PATH = :nexus_script_api_path
  CONFIG_ADMIN_USERNAME = :admin_username
  CONFIG_ADMIN_PASSWORD = :admin_password
  CONFIG_CONNECTION_TIMEOUT = :connection_timeout
  CONFIG_CONNECTION_OPEN_TIMEOUT = :connection_open_timeout
  CONFIG_CAN_DELETE_REPOSITORIES = :can_delete_repositories
  CONFIG_HEALTH_CHECK_RETRIES = :health_check_retries
  CONFIG_HEALTH_CHECK_TIMEOUT = :health_check_timeout

  def self.configure
    @config ||= read_config
    yield @config[CONFIG_NEXUS_BASE_URL], @config
  end

  # Returns: the full path to the file where this class sources its information from.
  #
  # Notice: any provider should have a soft dependency on this file to make sure it is created before usage.
  #
  def self.file_path
    @config_file_path ||= File.expand_path(File.join(Puppet.settings[:confdir], '/nexus3_rest.conf'))
  end

  def self.can_delete_repositories
    configure { |_nexus_base_url, options| options[CONFIG_CAN_DELETE_REPOSITORIES] == true }
  end

  def self.reset
    @config = nil
    @config_file_path = nil
  end

  def self.resolve(url)
    if url.start_with?('http')
      url
    else
      configure do |nexus_base_url, _options|
        URI.join(nexus_base_url, url).to_s
      end
    end
  end

  def self.read_config
    begin
      Puppet.debug("Parsing configuration file #{file_path}")
      # each loop used to convert hash keys from String to Symbol; each doesn't return the modified hash ... ugly, I know
      config = {}
      YAML.load_file(file_path).each { |key, value| config[key.to_sym] = value }
    rescue => e
      raise Puppet::ParseError, "Could not parse YAML configuration file '#{file_path}': #{e}"
    end

    if config[CONFIG_NEXUS_BASE_URL].nil?
      raise Puppet::ParseError, "Config file #{file_path} must contain a value for key '#{CONFIG_NEXUS_BASE_URL}'."
    end

    config[CONFIG_NEXUS_SCRIPT_API_PATH] = '/service/rest/v1/script' if config[CONFIG_NEXUS_SCRIPT_API_PATH].to_s.empty?

    # TODO: add warning about insecure connection if protocol is http and host not localhost (credentials sent in plain text)
    if config[CONFIG_ADMIN_USERNAME].nil?
      raise Puppet::ParseError, "Config file #{file_path} must contain a value for key '#{CONFIG_ADMIN_USERNAME}'."
    end
    if config[CONFIG_ADMIN_PASSWORD].nil?
      raise Puppet::ParseError, "Config file #{file_path} must contain a value for key '#{CONFIG_ADMIN_PASSWORD}'."
    end
    if config[CONFIG_CAN_DELETE_REPOSITORIES].nil?
      raise Puppet::ParseError, "Config file #{file_path} must contain a value for key '#{CONFIG_CAN_DELETE_REPOSITORIES}'."
    end

    {
      CONFIG_NEXUS_BASE_URL          => config[CONFIG_NEXUS_BASE_URL].chomp('/'),
      CONFIG_NEXUS_SCRIPT_API_PATH   => config[CONFIG_NEXUS_SCRIPT_API_PATH].chomp('/'),
      CONFIG_ADMIN_USERNAME          => config[CONFIG_ADMIN_USERNAME],
      CONFIG_ADMIN_PASSWORD          => config[CONFIG_ADMIN_PASSWORD],
      CONFIG_CONNECTION_TIMEOUT      => Integer(config.fetch(CONFIG_CONNECTION_TIMEOUT, 10)),
      CONFIG_CONNECTION_OPEN_TIMEOUT => Integer(config.fetch(CONFIG_CONNECTION_OPEN_TIMEOUT, 10)),
      CONFIG_CAN_DELETE_REPOSITORIES => config[CONFIG_CAN_DELETE_REPOSITORIES],
      CONFIG_HEALTH_CHECK_RETRIES    => Integer(config.fetch(CONFIG_HEALTH_CHECK_RETRIES, 50)),
      CONFIG_HEALTH_CHECK_TIMEOUT    => Integer(config.fetch(CONFIG_HEALTH_CHECK_TIMEOUT, 3))
    }
  end
end
