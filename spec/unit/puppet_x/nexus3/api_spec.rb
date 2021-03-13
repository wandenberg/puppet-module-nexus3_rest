require 'spec_helper'
require 'puppet_x/nexus3/api'

describe Nexus3::API do
  # health check always successful ...
  let!(:health_check_stub) { stub_request(:get, 'http://example.com/service/rest/v1/script/').to_return(status: 200) }

  before(:each) { stub_default_config }

  describe '#upload_script' do
    specify 'should ensure service is running' do
      example_script = 'script'
      stub_request(:post, 'http://example.com/service/rest/v1/script/').to_return(status: 204)

      described_class.upload_script(example_script)

      expect(health_check_stub).to have_been_requested
    end

    specify 'should use a random hex code as command name on each call' do
      example_script = 'script'

      stub_request(:post, 'http://example.com/service/rest/v1/script/').to_return(status: 204)

      command_name_1 = described_class.upload_script(example_script)
      command_name_2 = described_class.upload_script(example_script)
      expect(command_name_1).not_to eq command_name_2
    end

    specify 'should POST the groovy script as a JSON' do
      example_script = %(
        multiline
        script
      )
      command_name = '79b317d1abf4f6334ce9cc801a3e9990'

      allow(SecureRandom).to receive(:hex).and_return(command_name)
      stub = stub_request(:post, 'http://example.com/service/rest/v1/script/')
               .with(body: '{"name":"79b317d1abf4f6334ce9cc801a3e9990","type":"groovy","content":"\n        multiline\n        script\n      "}',
                     headers: { 'Accept' => 'application/json', 'Authorization' => 'Basic Zm9vYmFyOnNlY3JldA==', 'Content-Type' => 'application/json' })
               .to_return(status: 204)

      expect(described_class.upload_script(example_script)).to eq command_name

      expect(stub).to have_been_requested
    end

    specify 'should use given username and password instead of the ones on configuration file' do
      example_script = 'script'

      stub = stub_request(:post, %r{.*})
               .with(headers: { 'Authorization' => 'Basic b3RoZXJfdXNlcjpzZWNyZXQ=' })
               .to_return(status: 204)

      described_class.upload_script(example_script, 'other_user')

      expect(stub).to have_been_requested

      stub = stub_request(:post, %r{.*})
               .with(headers: { 'Authorization' => 'Basic Zm9vYmFyOm90aGVyX3Bhc3N3b3Jk' })
               .to_return(status: 204)

      described_class.upload_script(example_script, 'foobar', 'other_password')

      expect(stub).to have_been_requested

      stub = stub_request(:post, %r{.*})
               .with(headers: { 'Authorization' => 'Basic b3RoZXJfdXNlcjpvdGhlcl9wYXNzd29yZA==' })
               .to_return(status: 204)

      described_class.upload_script(example_script, 'other_user', 'other_password')

      expect(stub).to have_been_requested
    end

    specify 'should raise an error when is not possible to upload the script' do
      example_script = 'script'

      stub_request(:post, 'http://example.com/service/rest/v1/script/')
        .to_return(status: 403)

      expect { described_class.upload_script(example_script) }.to raise_error(RuntimeError, %r{Could not upload the script due to '403'})
    end
  end

  describe '#run_command' do
    specify 'should ensure service is running' do
      command_name = '79b317d1abf4f6334ce9cc801a3e9990'
      stub_request(:post, 'http://example.com/service/rest/v1/script/79b317d1abf4f6334ce9cc801a3e9990/run')
        .to_return(status: 200, body: '{}')

      described_class.run_command(command_name)

      expect(health_check_stub).to have_been_requested
    end

    specify 'should execute the command calling a POST on the command name' do
      command_name = '79b317d1abf4f6334ce9cc801a3e9990'

      stub = stub_request(:post, 'http://example.com/service/rest/v1/script/79b317d1abf4f6334ce9cc801a3e9990/run')
               .with(headers: { 'Accept' => 'application/json', 'Authorization' => 'Basic Zm9vYmFyOnNlY3JldA==', 'Content-Type' => 'text/plain' })
               .to_return(status: 200, body: '{}')

      described_class.run_command(command_name)

      expect(stub).to have_been_requested
    end

    specify 'should return the content present on result key' do
      command_name = '79b317d1abf4f6334ce9cc801a3e9990'

      stub_request(:post, 'http://example.com/service/rest/v1/script/79b317d1abf4f6334ce9cc801a3e9990/run')
        .with(headers: { 'Accept' => 'application/json', 'Authorization' => 'Basic Zm9vYmFyOnNlY3JldA==', 'Content-Type' => 'text/plain' })
        .to_return(status: 200, body: '{"result": "command output"}')

      expect(described_class.run_command(command_name)).to eq 'command output'
    end

    specify 'should use given username and password instead of the ones on configuration file' do
      command_name = '79b317d1abf4f6334ce9cc801a3e9990'

      stub = stub_request(:post, %r{.*})
               .with(headers: { 'Authorization' => 'Basic b3RoZXJfdXNlcjpzZWNyZXQ=' })
               .to_return(status: 200, body: '{}')

      described_class.run_command(command_name, 'other_user')

      expect(stub).to have_been_requested

      stub = stub_request(:post, %r{.*})
               .with(headers: { 'Authorization' => 'Basic Zm9vYmFyOm90aGVyX3Bhc3N3b3Jk' })
               .to_return(status: 200, body: '{}')

      described_class.run_command(command_name, 'foobar', 'other_password')

      expect(stub).to have_been_requested

      stub = stub_request(:post, %r{.*})
               .with(headers: { 'Authorization' => 'Basic b3RoZXJfdXNlcjpvdGhlcl9wYXNzd29yZA==' })
               .to_return(status: 200, body: '{}')

      described_class.run_command(command_name, 'other_user', 'other_password')

      expect(stub).to have_been_requested
    end

    specify 'should raise an error when is not possible to execute the command' do
      command_name = '79b317d1abf4f6334ce9cc801a3e9990'

      stub_request(:post, 'http://example.com/service/rest/v1/script/79b317d1abf4f6334ce9cc801a3e9990/run')
        .to_return(status: 404)

      expect { described_class.run_command(command_name) }.to raise_error(RuntimeError, %r{Could not run the command due to '404'})
    end
  end

  describe '#delete_command' do
    specify 'should ensure service is running' do
      command_name = '79b317d1abf4f6334ce9cc801a3e9990'
      stub_request(:delete, 'http://example.com/service/rest/v1/script/79b317d1abf4f6334ce9cc801a3e9990')
        .to_return(status: 204)

      described_class.delete_command(command_name)

      expect(health_check_stub).to have_been_requested
    end

    specify 'should delete the command calling a DELETE on the command name' do
      command_name = '79b317d1abf4f6334ce9cc801a3e9990'

      stub = stub_request(:delete, 'http://example.com/service/rest/v1/script/79b317d1abf4f6334ce9cc801a3e9990')
               .with(headers: { 'Accept' => 'application/json', 'Authorization' => 'Basic Zm9vYmFyOnNlY3JldA==', 'Content-Type' => 'application/json' })
               .to_return(status: 204)

      described_class.delete_command(command_name)

      expect(stub).to have_been_requested
    end

    specify 'should use given username and password instead of the ones on configuration file' do
      command_name = '79b317d1abf4f6334ce9cc801a3e9990'

      stub = stub_request(:delete, %r{.*})
               .with(headers: { 'Authorization' => 'Basic b3RoZXJfdXNlcjpzZWNyZXQ=' })
               .to_return(status: 204)

      described_class.delete_command(command_name, 'other_user')

      expect(stub).to have_been_requested

      stub = stub_request(:delete, %r{.*})
               .with(headers: { 'Authorization' => 'Basic Zm9vYmFyOm90aGVyX3Bhc3N3b3Jk' })
               .to_return(status: 204)

      described_class.delete_command(command_name, 'foobar', 'other_password')

      expect(stub).to have_been_requested

      stub = stub_request(:delete, %r{.*})
               .with(headers: { 'Authorization' => 'Basic b3RoZXJfdXNlcjpvdGhlcl9wYXNzd29yZA==' })
               .to_return(status: 204)

      described_class.delete_command(command_name, 'other_user', 'other_password')

      expect(stub).to have_been_requested
    end

    specify 'should raise an error when is not possible to delete the command' do
      command_name = '79b317d1abf4f6334ce9cc801a3e9990'

      stub_request(:delete, 'http://example.com/service/rest/v1/script/79b317d1abf4f6334ce9cc801a3e9990')
        .to_return(status: 404)

      expect { described_class.delete_command(command_name) }.to raise_error(RuntimeError, %r{Could not delete the command due to '404'})
    end
  end

  describe '#execute_script' do
    specify 'should upload the script, execute the command and delete it' do
      example_script = %(
        multiline
        script
      )

      expect(described_class).to receive(:upload_script).with(example_script).and_return('abc').ordered
      expect(described_class).to receive(:run_command).with('abc').and_return('output').ordered
      expect(described_class).to receive(:delete_command).with('abc').ordered

      expect(described_class.execute_script(example_script)).to eq 'output'
    end

    specify 'should always delete the command even if the execution raised an error' do
      example_script = %(
        multiline
        script
      )

      expect(described_class).to receive(:upload_script).with(example_script).and_return('abc').ordered
      expect(described_class).to receive(:run_command).with('abc').and_raise('unexpected error').ordered
      expect(described_class).to receive(:delete_command).with('abc').ordered

      expect { described_class.execute_script(example_script) }.to raise_error(RuntimeError, %r{unexpected error})
    end
  end
end
