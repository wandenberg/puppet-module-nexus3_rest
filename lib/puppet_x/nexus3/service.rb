require 'json'
require 'net/http'
require 'forwardable'
require File.join(File.dirname(__FILE__), '..', 'nexus3')

module Nexus3
  # Ensures the referenced Nexus instance is up and running. It does the health check only once and caches the result.
  class CachingService
    extend Forwardable

    # delegatee - the actual Nexus::Service to be used to do the health checking
    #
    def initialize(delegatee)
      @delegatee = delegatee
    end

    def_delegators :@delegatee, :client

    # See Nexus::Service.ensure_running.
    #
    def ensure_running
      raise('Nexus service failed a previous health check.') if @last_result == :not_running

      begin
        # FIXME: checking all the times
        @delegatee.ensure_running
        @last_result = :running
      rescue => e
        @last_result = :not_running
        raise e
      end
    end
  end

  # Class that wraps the interactions with the Nexus3 instance
  class Service
    attr_reader :client

    def initialize(client, configuration)
      @client = client
      @retries = configuration[:health_check_retries]
      @timeout = configuration[:health_check_timeout]
    end

    # Ensures the referenced Nexus instance is up and running.
    #
    # If the service is down or cannot be reached for some reason, the method will wait up to the configured limit.
    # If the retry limit has been reached, the method will raise an exception.
    #
    def ensure_running
      @retries.times do
        result = @client.check_health
        case result.status
        when :not_running
          Puppet.debug("%s Waiting #{@timeout} seconds before trying again." % result.log_message)
          sleep(@timeout)
        when :running
          Puppet.debug('Nexus service is running.')
          return
        end
      end
      raise("Nexus service did not start up within #{@timeout * @retries} seconds. You should check the Nexus log " \
               'files to see if something is wrong or consider increasing the timeout if the service is not starting up in ' \
               'time.')
    end

    # Class to wrap the status of a Nexus3 instance
    class Status
      attr_reader :status, :log_message

      def initialize(status, log_message)
        @status = status
        @log_message = log_message
      end

      # Service is still starting up ...
      #
      def self.not_running(log_message)
        Status.new(:not_running, log_message)
      end

      # Service is running.
      #
      def self.running
        Status.new(:running, '')
      end
    end

    # Class to verify the connection to Nexus3 instance
    class Client
      def initialize(configuration)
        @configuration = configuration
        @script_base_path = URI.parse("#{configuration[:nexus_base_url].chomp('/')}#{configuration[:nexus_script_api_path].chomp('/')}/").request_uri
        uri = URI.parse(configuration[:nexus_base_url])
        @nexus = Net::HTTP.new(uri.host, uri.port)
        @nexus.open_timeout = configuration[:connection_open_timeout]
        @nexus.read_timeout = configuration[:connection_timeout]
      end

      def check_health
        request(Net::HTTP::Get, '', 'application/json') do |response|
          # The GET to script endpoint without the credentials will always end up in a Forbidden response
          case response
          when Net::HTTPOK, Net::HTTPUnauthorized, Net::HTTPForbidden
            Puppet.debug('Nexus service is running.')
            Service::Status.running
          else
            Service::Status.not_running("Nexus service returned: #{response.code}.")
          end
        end
      rescue => e
        Service::Status.not_running("Caught an exception while checking status of Nexus service: #{e}.")
      end

      def request(method, path, content_type = 'text/plain', body = nil, username = nil, password = nil)
        request = method.new("#{@script_base_path.chomp('/')}/#{path.chomp('/')}")
        request.initialize_http_header('Accept' => 'application/json', 'Content-Type' => content_type)
        request.basic_auth(username || @configuration[:admin_username], password || @configuration[:admin_password])
        request.body = body if body
        # FIXME: add support to config over https
        # FIXME unify client with healthcheck service

        yield @nexus.request(request)
      end
    end
  end
end
