source ENV['GEM_SOURCE'] || 'https://rubygems.org'

ruby '2.7.1'

gem 'rake', '~> 13.0.1'

group :development do
  puppetversion = ENV.key?('PUPPET_VERSION') ? ENV['PUPPET_VERSION'] : ['>= 3.7.3']
  gem 'facter', '>= 1.7.0'
  gem 'metadata-json-lint', '~> 2.2.0'
  gem 'puppet', puppetversion
  gem 'puppet-lint', '~> 2.4.2'
  gem 'guard-rspec', '~> 4.7.3', :require => false
end

group :test do
  gem 'coco', '~> 0.15.0'
  gem 'rspec-puppet'
  gem 'puppetlabs_spec_helper', '>= 2.12.0'
  gem 'webmock', '~> 3.8.3'
end
