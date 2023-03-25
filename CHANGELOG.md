## 1.0.3
- Fix idempotence on configuring cleanup policies on repositories

## 1.0.2
- Fix support for http settings on Nexus 3.41+
- Fix how boolean values are set for repositories
- Adjust how user passwords are handled to be required and checked only on user creation
- Prevent changes on version_policy for repository groups

## 1.0.1
- Adjust upper version restriction of puppetlabs-stdlib

## 1.0.0
- Complete refactor to use the resource_api base class
- Refactor tests to use a running Nexus server instead of mocks

## 0.4.3
- Convert to PDK project

## 0.4.2
- Add support for Helm repository type
- Add support to configure the Negative Cache in proxied repositories
- Add support to configure http authentication as Preemptive Bearer Token

## 0.4.1
- Extend support to Nexus 3.20+
- Add support to manage routing rules
- Improve configurations for repositories

## 0.4.0
- Change the configuration file name to nexus3_rest.conf
- Add support to manage cleanup policies
- Improve configurations for repositories
- Fix differences by array elements order

## 0.3.0
- Add support to apt, composer and yum repository types
- Add support to docker specific attributes
- Add support to new Tasks
- Add nexus3_privilege and nexus3_blobstore types

## 0.2.0
- Add support to Nexus 3.8+ due to changes in the script API path [(release notes)](https://help.sonatype.com/repomanager3/release-notes/2018-release-notes#id-2018ReleaseNotes-RepositoryManager3.8.0)

## 0.1.0
- Initial version
