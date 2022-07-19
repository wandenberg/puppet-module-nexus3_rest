require 'spec_helper'

type_class = Puppet::Type.type(:nexus3_admin_password)

describe type_class.provider(:ruby) do
  let(:values) do
    {
      old_password: 'old_value',
      password: 'new_value',
    }
  end

  let(:instance) do
    resource = type_class.new(values.merge(name: 'example'))
    instance = described_class.new(values.merge(name: 'example'))
    resource.provider = instance
    instance
  end

  describe 'define getters and setters to each type properties or params' do
    let(:instance) { described_class.new }

    %i[old_password password admin_password_file].each do |method|
      specify { expect(instance.respond_to?(method)).to be_truthy }
      specify { expect(instance.respond_to?("#{method}=")).to be_truthy }
    end
  end

  describe 'prefetch' do
    it 'raise error if more than one resource of this type is configured' do
      expect {
        described_class.prefetch({ example1: type_class.new(values.merge(name: 'example1')), example2: type_class.new(values.merge(name: 'example2')) })
      }.to raise_error(Puppet::Error, %r{There are more then 1 instance of 'nexus3_admin_password': example1, example2})
    end

    it 'not raise error if just one resource of this type is configured' do
      expect {
        described_class.prefetch({ example1: type_class.new(values.merge(name: 'example1')) })
      }.not_to raise_error
    end
  end

  describe 'instances' do
    specify 'should not define instances method' do
      expect { described_class.instances }.to raise_error(Puppet::DevError, %r{(Provider ruby has not defined the 'instances' class method|provider needs to implement an 'instances' class method)})
    end
  end

  describe 'password' do
    before(:each) { stub_default_config_and_healthcheck }

    it 'verify if the current password is the one set on password property' do
      stub = stub_request(:get, 'http://example.com/service/rest/v1/script/')
               .with(headers: { 'Accept' => 'application/json', 'Authorization' => 'Basic YWRtaW46bmV3X3ZhbHVl', 'Content-Type' => 'application/json' })
               .to_return(status: 200)

      instance.password

      expect(stub).to have_been_requested
    end

    describe 'when need to change password' do
      before(:each) do
        stub_request(:post, %r{.*}).to_return(status: 204)
        stub_request(:post, %r{.*/run}).to_return(status: 200, body: '{}')
        stub_request(:delete, %r{.*}).to_return(status: 204)

        stub_request(:get, 'http://example.com/service/rest/v1/script/')
          .with(headers: { 'Accept' => 'application/json', 'Authorization' => 'Basic YWRtaW46bmV3X3ZhbHVl', 'Content-Type' => 'application/json' })
          .to_return(status: 403)
      end

      it 'upload the update script with the old password' do
        expect(Nexus3::API).to receive(:upload_script).with("security.securitySystem.changePassword('admin', 'new_value')", 'admin', 'old_value').and_return('command_name')

        instance.password = 'new_value'
      end

      it 'run the update script with the old password' do
        expect(Nexus3::API).to receive(:run_command).with(anything, 'admin', 'old_value')

        instance.password = 'new_value'
      end

      it 'delete the update script with the new password' do
        expect(Nexus3::API).to receive(:delete_command).with(anything, 'admin', 'new_value')

        instance.password = 'new_value'
      end

      it 'try to delete the update script with the old password in case the execute command failed' do
        allow(Nexus3::API).to receive(:run_command).and_raise('stupid error')

        expect(Nexus3::API).to receive(:delete_command).with(anything, 'admin', 'old_value')

        instance.password = 'new_value'
      end

      it 'force clear config after change password' do
        expect(Nexus3::Config).to receive(:reset)

        instance.password = 'new_value'
      end
    end

    describe 'when old and new passwords are equals' do
      let(:instance) do
        resource = type_class.new(values.merge(name: 'example', old_password: 'same_value', password: 'same_value'))
        instance = described_class.new(values.merge(name: 'example', old_password: 'same_value', password: 'same_value'))
        resource.provider = instance
        instance
      end

      it 'not verify if the current password is the one set on password property' do
        stub = stub_request(:get, 'http://example.com/service/rest/v1/script/')

        instance.password

        expect(stub).not_to have_been_requested
      end
    end
  end
end
