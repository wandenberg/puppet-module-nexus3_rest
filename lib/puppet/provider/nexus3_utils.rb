require File.join(File.dirname(__FILE__), '..', '..', 'puppet_x', 'nexus3', 'api')

# Base class to manage Nexus3 resources on Puppet
module Puppet::Provider::Nexus3Utils
  # Helper class to munge boolean values
  class Boolean
    # Normalize Boolean values
    #
    # @param [Object] v Something that vaguely resembles a boolean
    #
    # @raise [ArgumentError] The supplied parameter cannot be normalized.
    #
    # @return [true, false]
    def self.munge(v)
      case v
      when true, 'true', :true, :yes, 'yes'
        true
      when false, 'false', :false, :no, 'no', :undef, nil, :absent
        false
      else
        raise ArgumentError, "Value '#{v}':#{v.class} cannot be determined as a boolean value"
      end
    end
  end

  WRITE_POLICY_MAPPING = {
    'read_only' => 'DENY',
    'allow_write_once' => 'ALLOW_ONCE',
    'allow_write' => 'ALLOW',
    'allow_write_by_replication' => 'REPLICATION_ONLY',
  }.freeze

  DOCKER_PROXY_INDEX_TYPE = {
    'registry' => 'REGISTRY',
    'hub' => 'HUB',
    'custom' => 'CUSTOM'
  }.freeze

  TASK_TYPES = %w[blobstore.compact blobstore.rebuildComponentDB create.browse.nodes db.backup rebuild.asset.uploadMetadata repository.cleanup repository.cocoapods.store-remote-url-in-attributes
                  repository.docker.gc repository.docker.upload-purge repository.maven.publish-dotindex repository.maven.purge-unused-snapshots repository.maven.rebuild-metadata
                  repository.maven.remove-snapshots repository.maven.unpublish-dotindex repository.npm.rebuild-metadata repository.npm.reindex repository.p2.rewrite-composite-metdata
                  repository.purge-unused repository.pypi.delete-legacy-proxy-assets repository.rebuild-index repository.storage-facet-cleanup repository.vulnerability.statistics
                  repository.yum.rebuild.metadata script security.purge-api-keys tasklog.cleanup].freeze

  # Hook to return all instances of a resource type that its provider finds on the current system. Mainly used when
  # invoking `puppet resource`.
  def get(_context)
    config = get_current_config
    config = config.is_a?(Array) ? config : [config]
    config.map do |conf|
      conf[:name] = 'global' if max_instances_allowed == 1
      conf.merge(ensure: 'present')
    end
  end

  def set(context, changes)
    changes.each do |_name, change|
      is = change[:is]
      should = change[:should]

      next unless is[:ensure] == 'present' && should[:ensure] == 'present'

      raise ArgumentError, 'type cannot be changed' unless is[:type] == should[:type]
    end

    super(context, changes)
  end

  def create(_context, name, should)
    script = create_config_script(should)
    Puppet.debug("CREATE SCRIPT:\n#{script}")
    Nexus3::API.execute_script(script)
  rescue => e
    raise Puppet::Error, "Error while creating #{self.class.name} #{name}: #{e}"
  end

  def update(_context, name, should)
    script = write_config_script(should)
    Puppet.debug("UPDATE SCRIPT:\n#{script}")
    Nexus3::API.execute_script(script)
  rescue => e
    raise Puppet::Error, "Error while updating #{self.class.name} #{name}: #{e}"
  end

  def delete(_context, name)
    script = delete_config_script(name: name)
    Puppet.debug("DESTROY SCRIPT:\n#{script}")
    Nexus3::API.execute_script(script)
  rescue => e
    raise Puppet::Error, "Error while deleting #{self.class.name} #{name}: #{e}"
  end

  def skip_resource?(resource)
    resource.keys == [:title] || [:absent, 'absent'].include?(resource[:ensure])
  end

  def assert_present(value, message)
    raise ArgumentError, message if value.to_s.empty?
  end

  def apply_default_values(context, resource)
    context.type.attributes.each_pair do |key, conf|
      resource[key] = conf[:default] if resource[key].to_s.strip.empty? && !conf[:default].nil?
    end
  end

  def munge_booleans(context, resource)
    context.type.attributes.each_pair do |attribute, conf|
      next unless conf[:type] == 'Boolean' || conf[:type] == 'Variant[Boolean, String]'
      resource[attribute] = Puppet::Provider::Nexus3Utils::Boolean.munge(resource[attribute]) unless resource[attribute].to_s.empty?
    end
  end

  def munge_and_assert_port(resource, attribute)
    resource[attribute] = resource[attribute].to_i
    raise ArgumentError, 'Port must be within [1, 65535]' unless (1..65_535).cover?(resource[attribute])
  end

  def max_instances_allowed
    0
  end

  # Returns the current configuration
  #
  # {
  #    attribute1: ...
  #    attribute2: ...
  # }
  #
  def get_current_config
    script = read_config_script
    Puppet.debug("GET INSTANCES SCRIPT:\n#{script}")
    JSON.parse(Nexus3::API.execute_script(script), symbolize_names: true)
  rescue => e
    raise Puppet::Error, "Error while retrieving configuration: #{e}"
  end

  def read_config_script
    content = template_content('read_config.erb', {})
    return content if content
    raise Puppet::Error, "Method 'read_config_script' must be implemented or 'read_config.erb' template defined on #{self.class.name}"
  end

  def write_config_script(resource)
    content = template_content('write_config.erb', resource)
    return content if content
    raise Puppet::Error, "Method 'write_config_script' must be implemented or 'write_config.erb' template defined on #{self.class.name}"
  end

  def create_config_script(resource)
    content = template_content('create_config.erb', resource)
    return content if content
    raise Puppet::Error, "Method 'create_config_script' must be implemented or 'create_config.erb' template defined on #{self.class.name}"
  end

  def delete_config_script(resource)
    content = template_content('delete_config.erb', resource)
    return content if content
    raise Puppet::Error, "Method 'delete_config_script' must be implemented or 'delete_config.erb' template defined on #{self.class.name}"
  end

  def templates_folder
    File.join(File.dirname(__FILE__), self.class.name.split('::').last.gsub(%r{([^\^])([A-Z])}, '\1_\2').downcase, 'templates')
  end

  def template_content(template_name, resource)
    Puppet::Provider::Nexus3Utils.render_template(templates_folder, template_name, resource)
  end

  def self.render_template(templates_folder, template_name, resource)
    template_file = File.join(templates_folder, template_name)
    return unless File.exist?(template_file)

    template = ERB.new(File.read(template_file), nil, '-')
    template.result_with_hash(resource: resource, templates_folder: templates_folder, to_boolean: Puppet::Provider::Nexus3Utils.method(:to_boolean))
  end

  def self.to_boolean(value)
    value.to_s.empty? ? false : value
  end

  def self.to_groovy_properties(prefix, resource, skip_keys: %i[name ensure loglevel])
    lines = []
    resource.each_pair do |key, value|
      next if skip_keys.include?(key)
      lines.push("#{prefix}[toCamelCase('#{key}')] = #{value.is_a?(String) ? "'#{value}'" : value}")
    end
    lines.join("\n")
  end
end
