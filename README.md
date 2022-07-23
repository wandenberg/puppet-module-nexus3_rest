# Puppet Module for Sonatype Nexus 3 #

## Overview ##

Puppet Module for Sonatype Nexus 3 aims to offer native configuration of Nexus
instances in Puppet. The module uses Nexus REST interface to manage configuration.

Nexus 3 does not have the XML configuration files in the `sonatype-work/nexus/conf` directory as the previous versions. 
It uses a binary local database to save its configurations.
The only current supported way to automate configurations is to use the REST API, uploading and executing groovy code.

At this point not all options covered by the admin configuration web page are covered by this module, but the module is
designed to be easily extensible and pull requests are welcome.

It was based on the Atlassian [nexus_puppet](https://bitbucket.org/atlassian/puppet-module-nexus_rest) module for Nexus 2,

Puppet Module for Sonatype Nexus 3 allows configuration like this:

```
  #manifest/.../config.pp
  nexus3_repository { 'public':
    label          => 'Public Repository',
    provider_type  => 'maven2',
    type           => 'hosted',
    policy         => 'release',
  }
```

## Requirements ##

The module doesn't have any dependencies on other Puppet modules. It is using Ruby libraries that are contained in 
the default Ruby 2.1+ installation, like:

* json
* erb

### Enable Script API for Nexus 3.21.2+

Starting on version 3.21.2 of Nexus, the scripting API is disabled by default, check this [reference](https://issues.sonatype.org/browse/NEXUS-23205) on how to enable it before be able to use this module.

## Usage ##

First of all you need to create a configuration file `$confdir/nexus3_rest.conf` (whereas `$confdir` defaults to
`/etc/puppet`):

```
#!yaml
---
# credentials of a user with administrative power
admin_username: admin
admin_password: secret

# the base url of the Nexus service to be managed
nexus_base_url: http://localhost:8081/

# the path for the script API
# nexus_script_api_path: /service/rest/v1/script # default value

# Certain operations may result in data loss. The following parameter(s) control if Puppet should perform those
# changes or not. Set the parameter to `false` to prevent Puppet from enforcing the change and cause the Puppet run to
# fail instead.
can_delete_repositories: false

# timeout in seconds for opening the connection to the Nexus service
# connection_open_timeout: 10

# timeout in seconds for reading the answer from the Nexus service
# connection_timeout: 10

# Number of retries before giving up on the health check and consider the service not running.
# health_check_retries: 50

# Timeout in seconds to wait between single health checks.
# health_check_timeout: 3
```

The configuration file will provide the module with the required information about where Nexus is listening and which credentials to use to enforce the configuration. Obviously it is
recommended to manage the file within Puppet and limit the visibility to the root.

Any change is enforced through Nexus REST API. Hence, the Nexus service has to be running before any modification can
be made. In general, any ordering between the `service { 'nexus': }` resource and resources provided by this module
should be made explicit in the Puppet manifest itself. This module doesn't express any autorequire dependency ('soft
dependency') on the service resource itself - this is up to the user of the Puppet module. However, any resource provided by this module
will wait a certain amount of time in order to give Nexus the chance to properly start up. The default timeout is 150
seconds and can be configured via the configuration file.

All resources are implemented as providers. This means that if you have a running Nexus instance you can simply inspect the current state with:
```
puppet resource <resource-name>
```
for example:
```
puppet resource nexus3_repository
```
and copy/paste the result into your manifest file.

## Available resources ##

### Admin Password ###

To allow change the admin user password the module provides the `nexus3_admin_password` resource.
It will take care of check if the password needs to be changed and do the proper requests using the old and the new passwords.

```
#!puppet
nexus3_admin_password { 'admin_password':
  old_password => 'admin123',
  password     => '123admin',
}
```

As of Nexus version 3.17.0 the initial admin password is randomly generated and stored in the admin.password file on the server.
[Changelog - Repository Manager 3.17.0](https://help.sonatype.com/repomanager3/release-notes/2019-release-notes#id-2019ReleaseNotes-RepositoryManager3.17.0)
To automatically use that file to set the new password use the `admin_password_file` parameter to point to it.

```
#!puppet
nexus3_admin_password { 'admin_password':
  admin_password_file => '/opt/sonatype-work/nexus3/admin.password',
  password            => '123admin',
}
```

### Global Configuration ###

The global configuration has been decomposed into different resources. The following examples show how to use them.

#### Email configuration ####

To change the Email settings the module provides the `nexus3_smtp_settings` resource.

```
#!puppet
nexus3_smtp_settings { 'global':
  enabled      => true,
  host         => 'mail.example.com',
  port         => 25,
  username     => 'jdoe',
  password     => 'keepitsecret',
  from_address => 'nexus@example.com',
}
```

#### Realms configuration ####

To change the Realms settings the module provides the `nexus3_realm_settings` resource.
It allows to change the order of the realms used to authenticate the users.

```
#!puppet
nexus3_realm_settings { 'global':
  names => ['NexusAuthenticatingRealm', 'NexusAuthorizingRealm', 'LdapRealm'],
}

```

#### Anonymous configuration ####

To change the Anonymous user settings the module provides the `nexus3_anonymous_settings` resource.
It allows to change the username and realm used when a non identified user tries to use the Nexus web site.

```
#!puppet
nexus3_anonymous_settings { 'global':
  enabled  => true,
  realm    => 'NexusAuthorizingRealm',
  username => 'anonymous',
}
```

#### HTTP(S) Proxy configuration ####

To change the HTTP(S) proxy settings the module provides the `nexus3_http_settings` resource.
It allows to change the parameters used by nexus when doing an HTTP(S) request to an external server.

```
#!puppet
nexus3_http_settings { 'global':
  connection_user_agent      => 'nexus3_useragent',
  connection_timeout         => 90,
  connection_maximum_retries => 2,
  http_enabled               => true,
  http_host                  => 'local.com',
  http_port                  => 1234,
  http_auth_type             => 'username',
  http_auth_username         => 'user',
}
```

### LDAP configuration ###

The Nexus LDAP settings can be configured using the `nexus3_ldap` resource:

```
#!puppet
nexus3_ldap_settings { 'company_ldap':
  hostname                 => 'somehost',           #required: LDAP server hostname
  port                     => '389'                 #389 is default
  protocol                 => 'ldap',               #ldap is default, valid values: ldap, ldaps
  search_base              => 'dc=example,dc=com',  #required
  max_incidents_count      => '3',
  connection_retry_delay   => '300',
  connection_timeout       => '30',
  authentication_scheme    => 'none',               #none is default, valid values: simple, none, DIGEST_MD5, CRAM_MD5
  username                 => 'someuser',           #required (when authentication_scheme is not none): User to authenticate with LDAP service
  password                 => 'hunter2',            #default is unspecified
  sasl_realm               => '',                   #optional
  user_base_dn             => 'OU=users',           #OU=users is default
  user_subtree             => false,                #false is default
  user_object_class        => 'user',               #user is default
  user_id_attribute        => 'cn',                 #cn is default
  user_real_name_attribute => 'displayName',        #default is displayName
  user_email_attribute     => 'email',              #email is default
  user_password_attribute  => 'pw',                 #optional
  user_member_of_attribute => '',                   #optional
  ldap_filter              => '',                   #optional
  ldap_groups_as_roles     => false,                #true is default
  group_type               => 'static',             #static is default. Valid values are static or dynamic
  group_base_dn            => 'OU=groups',          #OU=groups is default, required if ldap_groups_as_roles is true
  group_subtree            => false,                #false is default
  group_object_class       => 'group',              #group is default, required if ldap_groups_as_roles is true
  group_id_attribute       => 'cn',                 #cn is default, required if ldap_groups_as_roles is true
  group_member_attribute   => 'uniqueMember',       #uniqueMember is default, required if ldap_groups_as_roles is true
  group_member_format      => '${dn}',              #${dn} is default, required if ldap_groups_as_roles is true
  order                    => 0,                    #optional, to set the order of the available LDAP servers
}
```

### User configuration ###

The Nexus User settings can be configured using the `nexus3_user` resource:
It allows to manage users changing roles, email, first and last names, ...

```
#!puppet
nexus3_user { 'anonymous':
  firstname => 'Anonymous',
  lastname  => 'User',
  password  => 'mysecret'               #only used whilw creating the user
  email     => 'anonymous@example.org',
  read_only => 'false',
  roles     => ['nx-anonymous'],
  status    => 'active',
}
```

### Privilege configuration ###

The Nexus Privilege settings can be configured using the `nexus3_privilege` resource:

```
#!puppet
nexus3_privilege { 'nx-repository-view-docker-*-browse':
  ensure          => 'present',
  actions         => 'browse',
  description     => 'Browse privilege for all \'docker\'-format repository views',
  format          => 'docker',
  repository_name => '*',
  type            => 'repository-view',
}
```

### Role configuration ###

The Nexus Role settings can be configured using the `nexus3_role` resource:

```
#!puppet
nexus3_role { 'nx-anonymous':
  description => 'Anonymous Role',  #optional
  roles       => ['nx-logging-all'],
  privileges  => ['nx-search-read', 'nx-repository-view-*-*-read', 'nx-repository-view-*-*-browse'],
}

```

### Blobstore configuration ###

The Nexus Blobstore settings can be configured using the `nexus3_blobstore` resource:

```
#!puppet
nexus3_blobstore { 'docker':
  ensure             => 'present',
  type               => 'File',
  path               => '/mnt/nexus/docker-store',
  quota_limit_bytes  => 35, # in MB
  quota_type         => 'spaceRemainingQuota', # accept also spaceUsedQuota
  soft_quota_enabled => 'true',
}
```

### Cleanup Policies ###

Cleanup policies can be set up using the `nexus3_cleanup_policy` resource:

```
#!puppet
nexus3_cleanup_policy { 'new_cleanup_policy':
  format            => 'apt',               #Repository format this policy applies to. Valid values: 'all', 'apt', 'bower', 'docker', 'gitlfs' (hosted), 'helm', 'maven2', 'npm', 'nuget', 'pypi', 'raw', 'rubygems', 'yum'
  notes             => 'Short description', #Optional: default is ''
  is_prerelease     => true,                #Whether the policy should apply to "release" or "prerelease" type repos. Valid values: true, false (default). Only applies to 'maven2', 'npm' or 'yum' repos
  last_blob_updated => 7,                   #Whether the policy should consider time (in days) of a components last update
  last_downloaded   => 14,                  #Whether the policy should consider time (in days) of a components last download
  regex             => '.*all\.deb',        #Match component name by this regular expression (not available if format is 'all', 'gitlfs' or 'yum')
}
```

### Repository Configuration ###

The Nexus Repository settings can be configured using the `nexus3_repository` and `nexus3_repository_group` resources:

```
#!puppet
nexus3_repository { 'new-repository':
  type                           => 'hosted',             #valid values: 'hosted', 'proxy'
  provider_type                  => 'maven2',             #valid values: 'apt', 'bower', 'docker', 'gitlfs' (hosted), 'helm', 'maven2', 'npm', 'nuget', 'pypi', 'raw', 'rubygems', 'yum'
  online                         => false,                #valid values: true (default), false
  blobstore_name                 => 'blob',               #optional, default is 'default'
  cleanup_policies               => [                     #names of existing cleanup policies
                                      'policy1',
                                      'policy2',
                                    ],
  version_policy                 => 'snapshot',           #valid values: 'snapshot', 'release' (default for maven2), 'mixed'
  write_policy                   => 'allow_write_once',   #valid values: 'read_only', 'allow_write_once (default for maven2)', 'allow_write', 'allow_write_by_replication'
  strict_content_type_validation => true,                 #valid values: true (default), false

  #the following 'remote_' and '*block*' properties may only be used when type => 'proxy'

  auto_block                     => false,                #optional, default is true
  blocked                        => false,                #optional, default is false
  remote_url                     => 'http://some-repo/',  #required
  remote_auth_type               => 'none',               #valid values: 'none' (default), 'username' (default for maven2), 'ntlm'
  remote_user                    => 'some_user',          #optional, default is unspecified
  remote_password                => 'hunter2',            #optional, default is unspecified
  remote_ntlm_host               => 'nt_host',            #optional, default is unspecified
  remote_ntlm_domain             => 'nt_domain',          #optional, default is unspecified

  #the following property may only be used when provider_type => 'yum'

  depth                          => 3                     #optional, default is 0: depth where 'repodata' is created

  routing_rule                   => 'images'              #optional, default is empty: routing rule to be applied to a proxy repository
}
```

```
#!puppet
nexus3_repository_group { 'example-repo-group':
  provider_type                  => 'maven2',             #valid values: 'bower', 'docker', 'gitlfs' (hosted), 'maven2', 'npm', 'nuget', 'pypi', 'raw', 'rubygems', 'yum'
  online                         => true,                 #valid values: true (default), false
  blobstore_name                 => 'blob',               #optional, default is 'default'
  strict_content_type_validation => true,                 #valid values: true (default), false
  repositories                   => [                     #note: these must be existing `nexus3_repository` resources  with the same `provider_type` as the repository group, order is significant
                                      'new-repository',
                                      'other-repository',
                                      'repository-3'
                                    ]
}
```

### Routing Rule configuration ###

The Nexus Routing Rule settings can be configured using the `nexus3_routing_rule` resource:

```
#!puppet
nexus3_routing_rule { 'images':
  description => 'Block all images',
  ensure      => 'present',
  mode        => 'BLOCK',
  matchers    => ['/.*.jpg', '/.*.svg', '/.*.gif'],
}
```

### Scheduled Tasks ###

The Nexus Task settings can be configured using the `nexus3_task` resource:
There are different kinds of tasks, each one requires a set of configurations.
The example will show only the common fields. The specific one can be determined looking the Task class code,
or manually configuring the Nexus 3 one first time and then running the `puppet resource nexus3_task` command.

```
#!puppet

nexus3_task { 'Empty Trash':
  enabled         => true,                   # true (default) or false
  type            => 'script',               # required, valid values: `blobstore.compact`, `blobstore.rebuildComponentDB`,
                                             # `create.browse.nodes`, `db.backup`, `rebuild.asset.uploadMetadata`,
                                             # `repository.docker.gc`, `repository.docker.upload-purge`,
                                             # `repository.maven.publish-dotindex`, `repository.maven.purge-unused-snapshots`,
                                             # `repository.maven.rebuild-metadata`, `repository.maven.remove-snapshots`,
                                             # `repository.maven.unpublish-dotindex`, `repository.npm.reindex`,
                                             # `repository.purge-unused`, `repository.rebuild-index`,
                                             # `repository.storage-facet-cleanup`, `repository.yum.rebuild.metadata`,
                                             # `script`, `security.purge-api-keys`, `tasklog.cleanup`
                                             #
  alert_email     => 'ops@example.com',      # optional; use `absent` (default) to disable the email notification
  frequency       => 'daily',                # one of `manual` (default), `once`, `daily`, `weekly`, `monthly` or `advanced`
  start_date      => '2014-05-31',
  start_time      => '20:00',
  cron_expression => '0 */10 * * * ?',
  recurring_day   => ['sunday', 'tuesday'],

  # specific task fields
}
```

Notes:

* Date and times are base on the timezone that is used on the server running Nexus. As Puppet should normally run on
  same server this shouldn't cause any trouble. However, when using the web ui on a computer with a different timezone,
  the values shown there are relative to that timezone and can appear different.
* Be very careful with one-off tasks (`reoccurrence => 'once'`); due to the way Nexus works, it will reject any updates
  of the one-off task once the scheduled date has passed. This will cause you Puppet run to fail. You have been warned.

Due to the complexity of the resource it is strongly recommended to configure the task via the user interface and use
`puppet resource` to generate the corresponding Puppet manifest.

#### Date and time related properties ###

Setting `reoccurrence` to one of the following values requires to specify additional properties:

* `manual` - no further property required
* `once` - `start_date` and `start_time`
* `hourly` - `start_date` and `start_time`
* `daily` - `start_date` and  `start_time`
* `weekly` - `start_date`, `start_time` and `recurring_day` (`recurring_day` should be a day of the _week_, e.g.
  `monday`, `tuesday`, ..., `sunday`)
* `monthly` - `start_date`, `start_time` and `recurring_day` (`recurring_day` should be a day of the _month_, e.g.
  1, 2, .... 29, 30, 31 or `last`)
* `advanced` - `cron_expression`

It is expected that `start_date` matches `YYYY-MM-DD` and `start_time` match `HH:MM` (including
leading zeros). The `recurring_day` accepts multiple values as a list (e.g. `[1, 2, 'last'])`.

Furthermore, you should keep your manifest clean and not specify properties that are not required (e.g. specify
`cron_expression` for a `manual` task).


## Limitations ##

### Ruby and Puppet compatibility ###
The module has been tested to work with the following Puppet and Ruby versions:

* Ruby 2.1.9p490

and

* Puppet 4.5.1

### Nexus compatibility ###
Furthermore, the module has been tested with the following Nexus versions:

* Nexus OSS 3.1.0-04+ running on Ubuntu 16.04
* Nexus OSS 3.19.1-01 running on Ubuntu 18.04 (for the cleanup policy stuff)

### A note on passwords ###

Due to the limitation of the Nexus REST api it is not possible to retrieve the current value of a password. Hence,
Puppet can only manage the existence of the password but won't notice when passwords change. Either way, passwords will
be updated when attributes of the same resource change as well.

## Contributing ##

1. Raise an issue
2. Fork it
3. Create your feature branch (`git checkout -b my-new-feature`)
4. Commit your changes (`git commit -am 'Add some feature'`)
5. Push to the branch (`git push origin my-new-feature`)
6. Create new pull request targeting master

## Running tests ##

The tests run now against a real Nexus3 Server.  
It can be an ordinary server instance, but dummy objects will be created on it on every run, or can be executed against a server instance inside docker.  
To build the Docker image run: `./docker/build.sh [NEXUS_VERSION, for instance, 3.40.1]`  
To execute the container in CI mode run: `./docker/run.sh true [NEXUS_VERSION, for instance, 3.40.1]`  
To execute the container in interactive mode run: `./docker/run.sh false [NEXUS_VERSION, for instance, 3.40.1] [container_name, for instance, nexus3-tests]`. Then enter on bash and run `bundle exec rspec`.
