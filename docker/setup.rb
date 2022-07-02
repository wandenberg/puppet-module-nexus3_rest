require_relative '../lib/puppet_x/nexus3/api'
require 'yaml'

puts 'STARTING SETUP'
Puppet.settings[:confdir] = '/nexus3_rest/docker'
Nexus3::API.service.ensure_running
puts 'SERVER IS RUNNING'
old_password = File.read('/nexus-data/admin.password')
password = YAML.load_file(File.join(Puppet.settings[:confdir], '/nexus3_rest.conf'))['admin_password']
puts "REPLACING PASSWORD #{old_password} WITH #{password}"
custom_script = <<-EOS
security.securitySystem.changePassword('admin', '#{password}')
def anonymousManager = container.lookup(org.sonatype.nexus.security.anonymous.AnonymousManager.class.name)
def config = anonymousManager.getConfiguration()
config.enabled = true
config.userId = 'anonymous'
config.realmName = 'NexusAuthorizingRealm'
anonymousManager.setConfiguration(config)
EOS

command_name = Nexus3::API.upload_script(custom_script, 'admin', old_password)
begin
  Nexus3::API.run_command(command_name, 'admin', old_password)
  old_password = password
  puts 'PASSWORD CHANGED'
rescue
  # Ignored
end
Nexus3::API.delete_command(command_name, 'admin', old_password)
File.unlink('/nexus-data/admin.password')
puts 'FINISHING SETUP'
