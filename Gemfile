source ENV['GEM_SOURCE'] || 'https://rubygems.org'

ruby '2.5.3'

gem 'rake', '~> 12.3.3'

group :development do
  puppetversion = ENV.key?('PUPPET_VERSION') ? ENV['PUPPET_VERSION'] : ['>= 3.7.3']
  gem 'facter', '>= 1.7.0'
  gem 'metadata-json-lint', '~> 1.1.0'
  gem 'puppet', puppetversion
  gem 'puppet-lint', '~> 2.1.1'
  gem 'guard-rspec', '~> 4.2.9', :require => false
end

group :test do
  gem 'coco', '~> 0.15.0'
  gem 'rspec-puppet'
  gem 'puppetlabs_spec_helper', '>= 2.12.0'
  gem 'webmock', '~> 3.4.2'
end
