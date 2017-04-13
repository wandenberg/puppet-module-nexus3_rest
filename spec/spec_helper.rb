require 'rspec-puppet'
require 'puppetlabs_spec_helper/module_spec_helper'
require 'webmock/rspec'
require 'coco'

RSpec.configure do |config|
  config.mock_with :rspec
end
