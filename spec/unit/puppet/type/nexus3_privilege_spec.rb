require 'spec_helper'

describe Puppet::Type.type(:nexus3_privilege) do
  describe 'for application' do
    it 'requires actions' do
      expect {
        described_class.new(name: 'privilege', type: 'application', domain: 'domain')
      }.to raise_error(ArgumentError, %r{actions must not be empty})
    end

    it 'requires domain' do
      expect {
        described_class.new(name: 'privilege', type: 'application', actions: 'a, b')
      }.to raise_error(ArgumentError, %r{domain must not be empty})
    end
  end

  describe 'for repository-admin' do
    it 'requires actions' do
      expect {
        described_class.new(name: 'privilege', type: 'repository-admin', format: 'format', repository_name: 'default')
      }.to raise_error(ArgumentError, %r{actions must not be empty})
    end

    it 'requires format' do
      expect {
        described_class.new(name: 'privilege', type: 'repository-admin', actions: 'a, b', repository_name: 'default')
      }.to raise_error(ArgumentError, %r{format must not be empty})
    end

    it 'requires repository_name' do
      expect {
        described_class.new(name: 'privilege', type: 'repository-admin', actions: 'a, b', format: 'format')
      }.to raise_error(ArgumentError, %r{repository_name must not be empty})
    end
  end

  describe 'for repository-view' do
    it 'requires actions' do
      expect {
        described_class.new(name: 'privilege', type: 'repository-view', format: 'format', repository_name: 'default')
      }.to raise_error(ArgumentError, %r{actions must not be empty})
    end

    it 'requires format' do
      expect {
        described_class.new(name: 'privilege', type: 'repository-view', actions: 'a, b', repository_name: 'default')
      }.to raise_error(ArgumentError, %r{format must not be empty})
    end

    it 'requires repository_name' do
      expect {
        described_class.new(name: 'privilege', type: 'repository-view', actions: 'a, b', format: 'format')
      }.to raise_error(ArgumentError, %r{repository_name must not be empty})
    end
  end

  describe 'for repository-content-selector' do
    it 'requires actions' do
      expect {
        described_class.new(name: 'privilege', type: 'repository-content-selector', content_selector: 'content_selector', repository_name: 'default')
      }.to raise_error(ArgumentError, %r{actions must not be empty})
    end

    it 'requires format' do
      expect {
        described_class.new(name: 'privilege', type: 'repository-content-selector', actions: 'a, b', repository_name: 'default')
      }.to raise_error(ArgumentError, %r{content_selector must not be empty})
    end

    it 'requires repository_name' do
      expect {
        described_class.new(name: 'privilege', type: 'repository-content-selector', actions: 'a, b', content_selector: 'content_selector')
      }.to raise_error(ArgumentError, %r{repository_name must not be empty})
    end
  end

  describe 'for script' do
    it 'requires actions' do
      expect {
        described_class.new(name: 'privilege', type: 'script', script_name: 'script_name')
      }.to raise_error(ArgumentError, %r{actions must not be empty})
    end

    it 'requires script_name' do
      expect {
        described_class.new(name: 'privilege', type: 'script', actions: 'a, b')
      }.to raise_error(ArgumentError, %r{script_name must not be empty})
    end
  end

  describe 'for wildcard' do
    it 'requires pattern' do
      expect {
        described_class.new(name: 'privilege', type: 'wildcard')
      }.to raise_error(ArgumentError, %r{pattern must not be empty})
    end
  end

  describe 'for invalid type ' do
    it 'requires pattern' do
      expect {
        described_class.new(name: 'privilege', type: 'invalid')
      }.to raise_error(ArgumentError, %r{Type 'invalid' not supported})
    end
  end

  describe 'when removing' do
    it { expect { described_class.new(name: 'any', ensure: :absent) }.not_to raise_error }
  end
end
