# frozen_string_literal: true

require 'webmock/rspec'
require 'simplecov'
SimpleCov.start do
  enable_coverage :branch

  add_filter 'spec'

  track_files 'lib/**/*.rb'
end

RSpec.configure do |c|
  c.filter_run focus: true
  c.run_all_when_everything_filtered = true
  c.mock_with :rspec
end

require 'puppetlabs_spec_helper/module_spec_helper'
require 'rspec-puppet-facts'

require 'spec_helper_local' if File.file?(File.join(File.dirname(__FILE__), 'spec_helper_local.rb'))

include RspecPuppetFacts

default_facts = {
  puppetversion: Puppet.version,
  facterversion: Facter.version,
}

default_fact_files = [
  File.expand_path(File.join(File.dirname(__FILE__), 'default_facts.yml')),
  File.expand_path(File.join(File.dirname(__FILE__), 'default_module_facts.yml')),
]

default_fact_files.each do |f|
  next unless File.exist?(f) && File.readable?(f) && File.size?(f)

  begin
    default_facts.merge!(YAML.safe_load(File.read(f), [], [], true))
  rescue => e
    RSpec.configuration.reporter.message "WARNING: Unable to load #{f}: #{e}"
  end
end

# read default_facts and merge them over what is provided by facterdb
default_facts.each do |fact, value|
  add_custom_fact fact, value
end

RSpec.configure do |c|
  c.default_facts = default_facts
  c.before :each do
    # set to strictest setting for testing
    # by default Puppet runs at warning level
    Puppet.settings[:strict] = :warning
    Puppet.settings[:strict_variables] = true
    WebMock.disable_net_connect!(allow_localhost: true)
    Nexus3::API.instance_variable_set(:@service, nil)
    Nexus3::API.instance_variable_set(:@version, nil)
    Nexus3::Config.reset
  end
  c.filter_run_excluding(bolt: true) unless ENV['GEM_BOLT']
  c.after(:suite) do
  end
end

# Ensures that a module is defined
# @param module_name Name of the module
def ensure_module_defined(module_name)
  module_name.split('::').reduce(Object) do |last_module, next_module|
    last_module.const_set(next_module, Module.new) unless last_module.const_defined?(next_module, false)
    last_module.const_get(next_module, false)
  end
end

# 'spec_overrides' from sync.yml will appear below this line

def stub_default_config
  default_config = {
    nexus_base_url: 'http://example.com',
    nexus_script_api_path: '/service/rest/v1/script/',
    admin_username: 'foobar',
    admin_password: 'secret',
    health_check_retries: 1,
    health_check_timeout: 10,
    can_delete_repositories: true,
  }
  allow(Nexus3::Config).to receive(:read_config).and_return(default_config)
  allow(Nexus3::API).to receive(:nexus3_server_version).and_return(3.19)
end

def stub_default_config_and_healthcheck
  stub_default_config
  # healthcheck
  stub_request(:get, 'http://example.com/service/rest/v1/script/')
    .with(headers: { 'Accept' => 'application/json', 'Authorization' => 'Basic Zm9vYmFyOnNlY3JldA==', 'Content-Type' => 'application/json' })
    .to_return(status: 403)
end

def stub_config
  config = {
    nexus_base_url: ENV.fetch('NEXUS_TEST_BASE_URL', 'http://localhost:8081'),
    nexus_script_api_path: '/service/rest/v1/script/',
    admin_username: ENV.fetch('NEXUS_TEST_USERNAME', 'admin'),
    admin_password: ENV.fetch('NEXUS_TEST_PASSWORD', 'admin123'),
    health_check_retries: 1,
    health_check_timeout: 10,
    can_delete_repositories: true,
  }
  allow(Nexus3::Config).to receive(:read_config).and_return(config)
end

Puppet.settings[:confdir] = '/etc/puppetlabs/puppet'
