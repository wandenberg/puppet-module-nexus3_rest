Puppet::Type.newtype(:nexus3_routing_rule) do
  @doc = 'Manages Nexus 3 Routing Rule'

  ensurable

  newparam(:name, namevar: true) do
    desc 'Unique rule name.'
  end

  newproperty(:description) do
    desc 'The description of the rule'
  end

  newproperty(:mode) do
    desc 'When rule is to block or allow.'
    newvalues(:ALLOW, :BLOCK)
    defaultto :BLOCK
  end

  newproperty(:matchers, array_matching: :all) do
    desc 'A list of matchers'
    defaultto []
    validate do |value|
      raise ArgumentError, 'matcher expressions must be provided in an array' if value.empty? || value.include?(',')
    end

    def insync?(is)
      is.sort == should.sort
    end
  end

  autorequire(:file) do
    Nexus3::Config.file_path
  end
end
