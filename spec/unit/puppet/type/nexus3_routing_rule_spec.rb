require 'spec_helper'

describe Puppet::Type.type(:nexus3_routing_rule) do
  let(:required_values) do
    {
      name: 'foo',
      matchers: ['a'],
    }
  end

  describe 'by default' do
    let(:instance) { described_class.new(required_values) }

    it { expect(instance[:mode]).to eq('BLOCK') }
  end

  it 'validate mode' do
    expect {
      described_class.new(required_values.merge(mode: 'invalid'))
    }.to raise_error(Puppet::ResourceError, %r{Parameter mode failed})
  end

  it 'validate matchers' do
    expect {
      described_class.new(required_values.merge(matchers: []))
    }.to raise_error(ArgumentError, %r{At least one matcher is required})
  end

  specify 'should accept ALLOW mode' do
    described_class.new(required_values.merge(mode: 'ALLOW'))
  end

  describe 'when removing' do
    it { expect { described_class.new(name: 'foo', ensure: :absent) }.not_to raise_error }
  end
end
