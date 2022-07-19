node default {
  nexus3_anonymous_settings { 'global':
    enabled  => true,
    username => 'anonymous',
    realm    => 'NexusAuthorizingRealm',
  }

  nexus3_blobstore { 'default':
    type => 'File',
    path => 'default',
  }

  nexus3_privilege { 'nx-all':
    type        => 'wildcard',
    description => 'All permissions',
    pattern     => 'nexus:*',
  }

  nexus3_realm_settings { 'global':
    names => ['NexusAuthenticatingRealm', 'NexusAuthorizingRealm'],
  }

  nexus3_repository { 'maven-central':
    type                           => 'proxy',
    provider_type                  => 'maven2',
    strict_content_type_validation => false,
    remote_url                     => 'https://repo1.maven.org/maven2/',
    layout_policy                  => 'permissive',
    auto_block                     => false,
  }

  nexus3_repository { 'maven-releases':
    type                           => 'hosted',
    provider_type                  => 'maven2',
    strict_content_type_validation => false,
  }

  nexus3_repository { 'maven-snapshots':
    type                           => 'hosted',
    provider_type                  => 'maven2',
    write_policy                   => 'allow_write',
    strict_content_type_validation => false,
    version_policy                 => 'snapshot',
  }

  nexus3_repository { 'nuget-hosted':
    type          => 'hosted',
    provider_type => 'nuget',
    write_policy  => 'allow_write',
  }

  nexus3_repository { 'nuget.org-proxy':
    type          => 'proxy',
    provider_type => 'nuget',
    remote_url    => 'https://api.nuget.org/v3/index.json',
    auto_block    => false,
  }

  nexus3_repository_group { 'maven-public':
    provider_type  => 'maven2',
    repositories   => ['maven-releases', 'maven-snapshots', 'maven-central'],
    version_policy => 'mixed',
  }

  nexus3_repository_group { 'nuget-group':
    provider_type => 'nuget',
    repositories  => ['nuget-hosted', 'nuget.org-proxy'],
  }

  nexus3_role { 'nx-admin':
    description => 'Administrator Role',
    privileges  => ['nx-all'],
  }

  nexus3_role { 'nx-anonymous':
    description => 'Anonymous Role',
    privileges  => ['nx-healthcheck-read', 'nx-repository-view-*-*-browse', 'nx-repository-view-*-*-read', 'nx-search-read'],
  }

  nexus3_smtp_settings { 'global':
    from_address => 'nexus@example.org',
    host         => 'localhost',
    port         => 25,
  }

  nexus3_task { 'Cleanup service':
    type            => 'repository.cleanup',
    frequency       => 'advanced',
    cron_expression => '0 0 1 * * ?',
  }

  nexus3_task { 'Storage facet cleanup':
    type            => 'repository.storage-facet-cleanup',
    frequency       => 'advanced',
    cron_expression => '0 */10 * * * ?',
  }

  nexus3_task { 'Task log cleanup':
    type            => 'tasklog.cleanup',
    frequency       => 'advanced',
    cron_expression => '0 0 0 * * ?',
  }

  include nexus
}
