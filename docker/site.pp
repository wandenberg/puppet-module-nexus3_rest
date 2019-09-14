class custom::nexus (
  Optional[Hash] $repositories = {},
  Optional[Hash] $repository_groups = {},
  Optional[Hash] $tasks = {},
){
  ensure_resources( 'nexus3_repository', $repositories )
  ensure_resources( 'nexus3_repository_group', $repository_groups )
  ensure_resources( 'nexus3_task', $tasks )
}


node default {
  include custom::nexus

  nexus3_blobstore { 'test1':
    type => 'File',
    path => '/tmp/01',
  }

  nexus3_blobstore { 'test2':
    type => 'File',
    path => '023',
    ensure => absent
  }

  # nexus3_privilege { 'content-selector-example':
  #   ensure           => 'present',
  #   actions          => 'a,b,c,d',
  #   content_selector => 'Test',
  #   description      => 'My content Selector',
  #   repository_name  => '*-npm',
  #   type             => 'repository-content-selector',
  # }

}
