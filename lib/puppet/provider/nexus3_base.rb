require File.join(File.dirname(__FILE__), '..', '..', 'puppet_x', 'nexus3', 'api')

class Puppet::Provider::Nexus3Base < Puppet::Provider
  desc 'Manage Nexus3 configuration.'

  WRITE_ONCE_ERROR_MESSAGE = "%s is write-once only and cannot be changed."

  def initialize(value = {})
    super(value)
    @update_required = false
  end

  # Hook to return all instances of a resource type that its provider finds on the current system. Mainly used when
  # invoking `puppet resource`.
  #
  # Relies on the `map_config_to_resource` method being implemented by any provider extending this class.
  #
  def self.instances
    Puppet.debug('INSTANCES')
    config = get_current_config
    config = config.is_a?(Array) ? config : [config]
    config.map do |conf|
      Puppet.debug(conf)
      hash = map_config_to_resource(conf)
      hash[:name] = 'global' if max_instances_allowed == 1
      new(hash)
    end
  end

  # Hook that is always invoked before any resources of that type are applied. Used when invoking `puppet agent` or
  # `puppet apply`.
  #
  def self.prefetch(resources)
    raise Puppet::Error, "There are more then #{max_instances_allowed} instance(s) of '#{resources.values[0].class.name}': #{resources.keys.join(', ')}" if max_instances_allowed > 0 && resources.size > max_instances_allowed
    settings = instances
    if max_instances_allowed == 1
      resources.values[0].provider = settings[0]
    else
      resources.each do |name, resource|
        if provider = settings.find { |setting| setting.name.to_s == name.to_s }
          resource.provider = provider
        end
      end
    end
  end

  # Update the configuration referenced by the current resource (e.g. just the SMTP settings).
  #
  def flush
    if @update_required
      update_config
      @property_hash = resource.to_hash
    end
  end

  def create
    begin
      script = create_config_script
      Puppet.debug("CREATE SCRIPT:\n#{script}")
      Nexus3::API.execute_script(script)
    rescue Exception => e
      raise Puppet::Error, "Error while creating #{resource.class.name} #{resource[:name]}: #{e}"
    end
  end

  def destroy
    begin
      script = delete_config_script
      Puppet.debug("DESTROY SCRIPT:\n#{script}")
      Nexus3::API.execute_script(script)
    rescue Exception => e
      raise Puppet::Error, "Error while deleting #{resource.class.name} #{resource[:name]}: #{e}"
    end
  end

  def exists?
    @property_hash[:ensure] == :present
  end


  # Update the configuration. Intended to be used when updating multiple things with one flush invocation.
  #
  def update_config
    script = write_config_script
    Puppet.debug("UPDATE SCRIPT:\n#{script}")
    Nexus3::API.execute_script(script)
  rescue Exception => e
    raise Puppet::Error, "Error while updating #{resource.class.name} #{resource[:name]}: #{e}"
  end

  # Mark the resource as dirty effectively forcing an update.
  #
  def mark_config_dirty
    @update_required = true
  end

  def self.mk_resource_methods
    [resource_type.validproperties, resource_type.parameters].flatten.each do |attr|
      attr = attr.intern
      next if attr == :name
      define_method(attr) do
        if @property_hash[attr].nil?
          :absent
        else
          @property_hash[attr]
        end
      end

      define_method(attr.to_s + '=') do |val|
        mark_config_dirty if @property_hash[attr] != val
        @property_hash[attr] = val
      end
    end
  end

  def self.max_instances_allowed
    0
  end

  # Returns the current configuration
  #
  # {
  #    'attribute1': ...
  #    'attribute2': ...
  # }
  #
  def self.get_current_config
    script = read_config_script
    Puppet.debug("GET INSTANCES SCRIPT:\n#{script}")
    JSON.parse(Nexus3::API.execute_script(script))
  rescue => e
    raise Puppet::Error, "Error while retrieving configuration: #{e}"
  end

  def self.read_config_script
    template = self.template('read_config.erb')
    return template.result(binding) if template
    raise Puppet::Error, "Method 'read_config_script' must be implemented or 'read_config.erb' template defined on #{resource.class.name}"
  end

  def write_config_script
    template = self.class.template('write_config.erb')
    return template.result(binding) if template
    raise Puppet::Error, "Method 'write_config_script' must be implemented or 'write_config.erb' template defined on #{resource.class.name}"
  end

  def create_config_script
    template = self.class.template('create_config.erb')
    return template.result(binding) if template
    raise Puppet::Error, "Method 'create_config_script' must be implemented or 'create_config.erb' template defined on #{resource.class.name}"
  end

  def delete_config_script
    template = self.class.template('delete_config.erb')
    return template.result(binding) if template
    raise Puppet::Error, "Method 'delete_config_script' must be implemented or 'delete_config.erb' template defined on #{resource.class.name}"
  end

  def self.map_config_to_resource(config)
    [resource_type.validproperties, resource_type.parameters].flatten.inject({}) do |entries, attr|
      attribute = attr.intern
      current_value = config[attribute.to_s]
      value = case current_value
        when false, 'false'
          :false
        when true, 'true'
          :true
        else
          attribute == :ensure ? :present : (current_value || '')
        end
      entries[attribute] = value
      entries
    end
  end

  private

  def self.templates_folder
    raise Puppet::Error, "Method 'templates_folder' must be implemented on #{resource.class.name}"
  end

  def self.template(template_name)
    template_file = File.join(self.templates_folder, template_name)
    return ERB.new(File.read(template_file), nil, '-') if File.exists?(template_file)
  end
end
