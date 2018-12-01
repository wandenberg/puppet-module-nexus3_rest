module Nexus3
  class TaskField
    include Comparable

    attr_reader :key, :key_name, :type, :getter, :full_getter, :setter

    def initialize(key, type = 'string')
      @key = key
      @key_name = convert_to_task_key_name(key)
      @type = type
      @getter = "get#{type.capitalize}"
      @setter = "set#{type.capitalize}"
      @full_getter = case type
                       when 'string'
                         "get#{type.capitalize}('#{@key_name}')"
                       when 'integer'
                         "get#{type.capitalize}('#{@key_name}', 0)"
                       when 'boolean'
                         "get#{type.capitalize}('#{@key_name}', false)"
                     end
    end

    def get_value_to_setter(resource)
      value = resource[@key.to_sym]
      case @type
        when 'string'
          "'#{value}'"
        when 'integer'
          value.to_i
        when 'boolean'
          value.to_s == 'true'
      end
    end

    def hash
      "#{key}-#{type}".hash
    end

    def eql?(other)
      self.hash == other.hash
    end

    def <=>(other)
      return -1 if other.nil? || !other.is_a?(Nexus3::TaskField)

      id = "#{self.key}-#{self.type}"
      other_id = "#{other.key}-#{other.type}"

      if id < other_id
        -1
      elsif id > other_id
        1
      else
        0
      end
    end

    private

    def convert_to_task_key_name(value)
      value.split('_').each_with_index.map{ |word,index| index == 0 ? word : word.capitalize }.join
    end
  end
end
