source ENV['GEM_SOURCE'] || 'https://rubygems.org'

ruby '2.3.0'

gem 'rake', '~> 12.0.0'

group :development do
  puppetversion = ENV.key?('PUPPET_VERSION') ? ENV['PUPPET_VERSION'] : ['>= 3.7.3']
  gem 'facter', '>= 1.7.0'
  gem 'metadata-json-lint', '~> 1.1.0'
  gem 'puppet', puppetversion
  gem 'puppet-lint', '~> 2.1.1'
  gem 'guard-rspec', '~> 4.2.9', :require => false
end

group :test do
  gem 'coco', '~> 0.14.0'
  gem 'rspec-puppet'
  gem 'puppetlabs_spec_helper', '>= 1.0.0'
  gem 'webmock', '~> 3.0.1'
end
