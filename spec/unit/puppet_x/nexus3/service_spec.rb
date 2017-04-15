require 'puppet_x/nexus3/service'
require 'spec_helper'

describe Nexus3::Service do
  let(:configuration) do
    {
      nexus_base_url: 'http://example.com',
      admin_username: 'foobar',
      admin_password: 'secret',
      health_check_retries: 3,
      health_check_timeout: 0,
    }
  end

  describe 'Client.check_health' do
    let(:client) { Nexus3::Service::Client.new(configuration) }

    specify 'should talk to /service/siesta/rest/v1/script' do
      stub = stub_request(:any, /example.com\/service\/siesta\/rest\/v1\/script/).to_return(status: 403)
      client.check_health
      expect(stub).to have_been_requested
    end

    specify 'should report running if the instance is up' do
      stub_request(:any, /.*/).to_return(status: 200)
      expect(client.check_health.status).to eq(:running)

      stub_request(:any, /.*/).to_return(status: 403)
      expect(client.check_health.status).to eq(:running)
    end

    specify 'should report not running if the instance is still starting up' do
      stub_request(:any, /.*/).to_return(status: [500, 'Internal Server Error'])
      expect(client.check_health.status).to eq(:not_running)
      expect(client.check_health.log_message).to match(/Nexus service returned: 500./)
    end

    specify 'should report not running if the instance is not reachable' do
      stub_request(:any, /.*/).to_timeout
      expect(client.check_health.status).to eq(:not_running)
      expect(client.check_health.log_message).to match(/Caught an exception while checking status of Nexus service: execution expired./)
    end

  end

  describe 'CachingService.ensure_running' do
    let(:delegatee) { double('The real service') }
    let(:service) { Nexus3::CachingService.new(delegatee) }

    specify 'should delegate to the real service' do
      expect(delegatee).to receive(:ensure_running)
      expect { service.ensure_running }.to_not raise_error
    end

    specify 'should not cache successful result' do
      allow(delegatee).to receive(:ensure_running).exactly(2).times#.and_return()
      service.ensure_running
      expect { service.ensure_running }.to_not raise_error
    end

    specify 'should cache a negative result' do
      allow(delegatee).to receive(:ensure_running).exactly(1).times.and_raise('service is broken')
      expect { service.ensure_running }.to raise_error(RuntimeError, /service is broken/)
      expect { service.ensure_running }.to raise_error(RuntimeError, /Nexus service failed a previous health check/)
    end
  end

  describe :ensure_running do
    let(:client) { double('Dummy Health Check Client') }
    let(:service) { Nexus3::Service.new(client, configuration) }

    specify 'should retry if service is not running' do
      allow(client).to receive(:check_health).and_return(Nexus3::Service::Status.not_running('still starting'), Nexus3::Service::Status.running)
      expect { service.ensure_running }.to_not raise_error
    end

    specify 'should retry no more than configured' do
      allow(client).to receive(:check_health).at_most(configuration[:health_check_retries]).times.and_return(Nexus3::Service::Status.not_running('still starting'))
      expect { service.ensure_running }.to raise_error(RuntimeError, /Nexus service did not start up within 0 seconds/)
    end
  end
end
