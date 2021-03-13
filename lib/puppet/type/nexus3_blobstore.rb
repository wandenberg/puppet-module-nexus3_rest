require 'puppet/property/boolean'

Puppet::Type.newtype(:nexus3_blobstore) do
  @doc = 'Manages Nexus 3 Blob Store'

  ensurable

  newparam(:name, namevar: true) do
    desc 'Unique blob store name.'
  end

  newproperty(:type) do
    desc 'The type of the blob store'
  end

  newproperty(:path) do
    desc 'The path of the blob store'
  end

  newproperty(:soft_quota_enabled, parent: Puppet::Property::Boolean) do
    desc 'Enable soft quota'
    newvalues(:true, :false)
    defaultto :false
    munge { |value| super(value).to_s.to_sym }
  end

  newproperty(:quota_limit_bytes) do
    desc 'The quota limit bytes of the blob store'
    munge { |value| Integer(value) }
  end

  newproperty(:quota_type) do
    desc 'The quota type of the blob store'
    newvalues(:spaceRemainingQuota, :spaceUsedQuota)
    munge { |value| super(value).to_s.to_sym }
  end

  newproperty(:bucket) do
    desc 'The bucket on S3 store'
  end

  newproperty(:prefix) do
    desc 'The prefix on S3 store'
  end

  newproperty(:access_key_id) do
    desc 'The access_key_id on S3 store'
  end

  newproperty(:secret_access_key) do
    desc 'The secret_access_key on S3 store'
  end

  newproperty(:session_token) do
    desc 'The session_token on S3 store'
  end

  newproperty(:assume_role) do
    desc 'The assume_role on S3 store'
  end

  newproperty(:region) do
    desc 'The region on S3 store'
  end

  newproperty(:endpoint) do
    desc 'The expiration on S3 store'
  end

  newproperty(:expiration) do
    desc 'The expiration on S3 store'
    munge { |value| Integer(value) }
  end

  newproperty(:signertype) do
    desc 'Signer type on S3 store'
    newvalues(:DEFAULT, :S3SignerType, :AWSS3V4SignerType)
    defaultto { @resource[:type] == 'S3' ? :DEFAULT : nil }
    munge { |value| super(value).to_s.to_sym }
  end

  newproperty(:forcepathstyle, parent: Puppet::Property::Boolean) do
    desc 'Force path style on S3 store'
    newvalues(:true, :false)
    defaultto { @resource[:type] == 'S3' ? :false : nil }
    munge { |value| super(value).to_s.to_sym }
  end

  validate do
    if self[:ensure] == :present
      if self[:soft_quota_enabled] == :true
        raise ArgumentError, 'quota_type must be provided to set quota_limit_bytes' if self[:quota_type].to_s.empty? && !self[:quota_limit_bytes].to_s.empty?
        raise ArgumentError, 'quota_limit_bytes must be provided to set quota_type' if !self[:quota_type].to_s.empty? && self[:quota_limit_bytes].to_s.empty?
        raise ArgumentError, 'quota_limit_bytes must be greater than 0' if !self[:quota_limit_bytes].to_s.empty? && self[:quota_limit_bytes].to_i <= 0
      end
    end
  end

  autorequire(:file) do
    Nexus3::Config.file_path
  end
end
