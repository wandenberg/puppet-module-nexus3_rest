node default {
  $version          = '3.14.0-04'
  $version_checksum = '7e577cfd3c72bac488913d19dfad39e90019490f'
  $work_dir         = '/opt/nexus/sonatype-work'
  $install_dir      = '/opt/nexus'
  $mirror_url       = 'https://sonatype-download.global.ssl.fastly.net/nexus/3/'
  $archive_name     = "nexus-${version}-unix"
  $archive_ext      = 'tar.gz'
  $archive          = "${archive_name}.${archive_ext}"
  $download_url     = "${mirror_url}${archive}"
  $service_file     = "${install_dir}/nexus/bin/nexus"

  include ::archive

  package { 'openjdk-8-jre': ensure => present }

  group { 'nexus': ensure => present }

  user { 'nexus':
    ensure  => present,
    home    => $work_dir,
    shell   => '/bin/bash',
    require => Group['nexus']
  }

  file { [
    $install_dir,
    $work_dir,
    "${work_dir}/nexus3",
    "${work_dir}/nexus3/log",
    "${work_dir}/nexus3/tmp",
    "${work_dir}/nexus3/orient",
    "${work_dir}/nexus3/instances",
    "${work_dir}/nexus3/orient/plugins" ]:
    ensure  => directory,
    owner   => 'nexus',
    group   => 'nexus',
    mode    => '0755',
    require => [
      User['nexus']
    ]
  }

  archive { "$install_dir/$archive":
    ensure       => present,
    source       => $download_url,
    extract      => true,
    extract_path => $install_dir,
    cleanup      => false,
    require      => [
      User['nexus'],
      File[$install_dir]
    ]
  }

  file { "${install_dir}/nexus":
    ensure  => link,
    owner   => 'nexus',
    group   => 'nexus',
    target  => "${install_dir}/nexus-${version}",
    require => [
      Archive["$install_dir/$archive"],
    ]
  }

  file_line { 'run as nexus user':
    path    => $service_file,
    line    => "run_as_user=nexus",
    match   => '^#?run_as_user=.*',
    require => File["${install_dir}/nexus"],
  }

  file { '/etc/init.d/nexus':
    ensure  => link,
    target  => $service_file,
    require => [
      File_line['run as nexus user']
    ]
  }

  service { 'nexus':
    ensure  => running,
    enable  => true,
    require => [
      File[$work_dir],
      File['/etc/init.d/nexus'],
    ]
  }

  file { '/etc/puppetlabs/puppet/nexus_rest.conf':
    ensure  => file,
    content => '#!yaml
---
# credentials of a user with administrative power
admin_username: admin
admin_password: admin123

# the base url of the Nexus service to be managed
nexus_base_url: http://localhost:8081/

can_delete_repositories: true'
  }

  include hello_nexus
}
