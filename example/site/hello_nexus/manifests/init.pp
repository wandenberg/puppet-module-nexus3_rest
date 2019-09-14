class hello_nexus (
) {
  notify { 'Add here the resources to test on Nexus3': }
  nexus3_repository { 'jcenter':
    ensure                         => 'present',
    layout_policy                  => 'strict',
    online                         => 'true',
    provider_type                  => 'maven2',
    remote_auth_type               => 'none',
    remote_url                     => 'https://jcenter.bintray.com',
    strict_content_type_validation => 'true',
    type                           => 'proxy',
    version_policy                 => 'release',
  }
}
