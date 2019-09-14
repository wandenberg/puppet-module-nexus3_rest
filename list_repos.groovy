/*
  Useful script that will read in all of the repository
  configuration attributes and output result in json format.
  Run this as Admin Task and look for Task log file in the log.
   *SYSTEM org.sonatype.nexus.internal.script.ScriptTask - Task log: /path/to.log
*/
def repositories = repository.repositoryManager.browse()
def infos = repositories.findResults { repository ->
  def config = repository.getConfiguration()
  def (providerType, type) = config.recipeName.split('-')

  def httpclient = config.attributes('httpclient');

  def authentication = httpclient.child('authentication');
  [
    name: config.repositoryName,
    type: type,
    provider_type: providerType,
    online: config.isOnline(),
    attributes: config.attributes,
  ]
}
def outputFile = '/tmp/nexus3_repos.json'
def jsonOut = groovy.json.JsonOutput.toJson(infos)
new File(outputFile).write(groovy.json.JsonOutput.prettyPrint(jsonOut))
