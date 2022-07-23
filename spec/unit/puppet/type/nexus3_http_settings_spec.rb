# frozen_string_literal: true

require 'spec_helper'

describe Puppet::Type.type(:nexus3_http_settings) do
  let(:required_values) do
    {
      name: 'example',
      http_enabled: true,
      http_host: 'local.host',
      http_port: 9991,
      https_enabled: true,
      https_host: 'foo.host',
      https_port: 9992,
    }
  end

  describe 'connection_timeout' do
    specify 'should accept minimum 1' do
      expect {
        described_class.new(required_values.merge(connection_timeout: 0))
      }.to raise_error(ArgumentError, %r{connection_timeout must be within \[1, 3600\]})
    end

    specify 'should accept maximum 3600' do
      expect {
        described_class.new(required_values.merge(connection_timeout: 3601))
      }.to raise_error(ArgumentError, %r{connection_timeout must be within \[1, 3600\]})
    end

    specify 'should use default value when empty string' do
      expect(described_class.new(required_values.merge(connection_timeout: ''))[:connection_timeout]).to be(20)
    end
  end

  describe 'connection_maximum_retries' do
    specify 'should accept minimum 1' do
      expect {
        described_class.new(required_values.merge(connection_maximum_retries: 0))
      }.to raise_error(ArgumentError, %r{connection_maximum_retries must be within \[1, 10\]})
    end

    specify 'should accept maximum 10' do
      expect {
        described_class.new(required_values.merge(connection_maximum_retries: 11))
      }.to raise_error(ArgumentError, %r{connection_maximum_retries must be within \[1, 10\]})
    end

    specify 'should use default value when empty string' do
      expect(described_class.new(required_values.merge(connection_maximum_retries: ''))[:connection_maximum_retries]).to be(2)
    end
  end

  describe 'http_port' do
    specify 'should default to empty' do
      expect(described_class.new(name: 'global')[:http_port]).to be('')
    end

    specify 'should not accept characters' do
      expect {
        described_class.new(required_values.merge(http_port: 'abc'))
      }.to raise_error(ArgumentError, %r{Port must be within \[1, 65535\]})
    end

    specify 'should not accept port 0' do
      expect {
        described_class.new(required_values.merge(http_port: 0))
      }.to raise_error(ArgumentError, %r{Port must be within \[1, 65535\]})
    end

    specify 'should accept port 1' do
      expect { described_class.new(required_values.merge(http_port: 1)) }.not_to raise_error
    end

    specify 'should accept port as string' do
      expect { described_class.new(required_values.merge(http_port: '25')) }.not_to raise_error
    end

    specify 'should accept port 65535' do
      expect { described_class.new(required_values.merge(http_port: 65_535)) }.not_to raise_error
    end

    specify 'should not accept ports larger than 65535' do
      expect {
        described_class.new(required_values.merge(http_port: 65_536))
      }.to raise_error(ArgumentError, %r{Port must be within \[1, 65535\]})
    end
  end

  describe 'https_port' do
    specify 'should default to empty' do
      expect(described_class.new(name: 'global')[:https_port]).to be('')
    end

    specify 'should not accept characters' do
      expect {
        described_class.new(required_values.merge(https_port: 'abc'))
      }.to raise_error(ArgumentError, %r{Port must be within \[1, 65535\]})
    end

    specify 'should not accept port 0' do
      expect {
        described_class.new(required_values.merge(https_port: 0))
      }.to raise_error(ArgumentError, %r{Port must be within \[1, 65535\]})
    end

    specify 'should accept port 1' do
      expect { described_class.new(required_values.merge(https_port: 1)) }.not_to raise_error
    end

    specify 'should accept port as string' do
      expect { described_class.new(required_values.merge(https_port: '25')) }.not_to raise_error
    end

    specify 'should accept port 65535' do
      expect { described_class.new(required_values.merge(https_port: 65_535)) }.not_to raise_error
    end

    specify 'should not accept ports larger than 65535' do
      expect {
        described_class.new(required_values.merge(https_port: 65_536))
      }.to raise_error(ArgumentError, %r{Port must be within \[1, 65535\]})
    end
  end

  context 'http proxy enabled' do
    it 'requires a host' do
      expect {
        described_class.new(required_values.merge(http_host: ''))
      }.to raise_error(ArgumentError, %r{http_host must not be empty})
    end

    it 'requires a port' do
      expect {
        described_class.new(required_values.merge(http_port: ''))
      }.to raise_error(ArgumentError, %r{http_port must not be empty})
    end

    context 'auth type is username' do
      it 'requires a username' do
        expect {
          described_class.new(required_values.merge(http_auth_type: 'username', http_auth_username: ''))
        }.to raise_error(ArgumentError, %r{http_auth_username must not be empty})
      end
    end

    context 'auth type is ntlm' do
      it 'requires a username' do
        expect {
          described_class.new(required_values.merge(http_auth_type: 'ntlm', http_auth_username: ''))
        }.to raise_error(ArgumentError, %r{http_auth_username must not be empty})
      end

      it 'requires a ntlm_host' do
        expect {
          described_class.new(required_values.merge(http_auth_type: 'ntlm', http_auth_username: 'user', http_auth_ntlm_host: ''))
        }.to raise_error(ArgumentError, %r{http_auth_ntlm_host must not be empty})
      end

      it 'requires a ntlm_domain' do
        expect {
          described_class.new(required_values.merge(http_auth_type: 'ntlm', http_auth_username: 'user', http_auth_ntlm_host: 'n_host', http_auth_ntlm_domain: ''))
        }.to raise_error(ArgumentError, %r{http_auth_ntlm_domain must not be empty})
      end
    end

    context 'https proxy enabled' do
      it 'requires a host' do
        expect {
          described_class.new(required_values.merge(https_host: ''))
        }.to raise_error(ArgumentError, %r{https_host must not be empty})
      end

      it 'requires a port' do
        expect {
          described_class.new(required_values.merge(https_port: ''))
        }.to raise_error(ArgumentError, %r{https_port must not be empty})
      end

      context 'auth type is username' do
        it 'requires a username' do
          expect {
            described_class.new(required_values.merge(http_auth_type: 'username', http_auth_username: ''))
          }.to raise_error(ArgumentError, %r{http_auth_username must not be empty})
        end
      end

      context 'auth type is ntlm' do
        it 'requires a username' do
          expect {
            described_class.new(required_values.merge(https_auth_type: 'ntlm', https_auth_username: ''))
          }.to raise_error(ArgumentError, %r{https_auth_username must not be empty})
        end

        it 'requires a ntlm_host' do
          expect {
            described_class.new(required_values.merge(https_auth_type: 'ntlm', https_auth_username: 'user', https_auth_ntlm_host: ''))
          }.to raise_error(ArgumentError, %r{https_auth_ntlm_host must not be empty})
        end

        it 'requires a ntlm_domain' do
          expect {
            described_class.new(required_values.merge(https_auth_type: 'ntlm', https_auth_username: 'user', https_auth_ntlm_host: 'n_host', https_auth_ntlm_domain: ''))
          }.to raise_error(ArgumentError, %r{https_auth_ntlm_domain must not be empty})
        end
      end
    end

    context 'https proxy disabled' do
      it 'rejects all https properties' do
        expect {
          described_class.new(name: 'global', http_enabled: true, https_enabled: false, http_host: 'localhost', https_port: 8888)
        }.to raise_error(ArgumentError, %r{https_port not allowed when https proxy is disabled})
      end
    end
  end

  context 'http proxy disabled' do
    it 'rejects all http and https properties' do
      expect {
        described_class.new(name: 'global', http_enabled: false, http_host: 'localhost', https_port: 8888)
      }.to raise_error(ArgumentError, %r{http_host and https_port not allowed when http proxy is disabled})
    end
  end
end
