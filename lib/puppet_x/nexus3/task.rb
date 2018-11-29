require File.join(File.dirname(__FILE__), 'task_field')

module Nexus3
  class Task
    FIELDS_BY_TYPE = {
      'blobstore.compact' => [Nexus3::TaskField.new('blobstore_name')],
      'repository.docker.upload-purge' => [Nexus3::TaskField.new('age', 'integer')],
      'repository.maven.publish-dotindex' => [Nexus3::TaskField.new('repository_name')],
      'repository.maven.purge-unused-snapshots' => [Nexus3::TaskField.new('last_used', 'integer'), Nexus3::TaskField.new('repository_name')],
      'repository.maven.rebuild-metadata' => [Nexus3::TaskField.new('artifact_id'), Nexus3::TaskField.new('base_version'),
                                              Nexus3::TaskField.new('group_id'), Nexus3::TaskField.new('repository_name')],
      'repository.maven.remove-snapshots' => [Nexus3::TaskField.new('grace_period_in_days', 'integer'), Nexus3::TaskField.new('minimum_retained', 'integer'),
                                              Nexus3::TaskField.new('remove_if_released', 'boolean'), Nexus3::TaskField.new('repository_name'),
                                              Nexus3::TaskField.new('snapshot_retention_days', 'integer')],
      'repository.maven.unpublish-dotindex' => [Nexus3::TaskField.new('repository_name')],
      'repository.purge-unused' => [Nexus3::TaskField.new('last_used', 'integer'), Nexus3::TaskField.new('repository_name')],
      'repository.rebuild-index' => [Nexus3::TaskField.new('repository_name')],
      'script' => [Nexus3::TaskField.new('language'), Nexus3::TaskField.new('source')],
      'security.purge-api-keys' => [],
      'db.backup' => [Nexus3::TaskField.new('location')],
    }

    def self.frequency_to_schedule(resource)
      case resource[:frequency]
      when :manual
        'org.sonatype.nexus.scheduling.schedule.Manual()'
      when :once
        "org.sonatype.nexus.scheduling.schedule.Once(java.util.Date.parse('yyyy-MM-dd HH:mm', '#{resource[:start_date]} #{resource[:start_time]}'))"
      when :hourly
        "org.sonatype.nexus.scheduling.schedule.Hourly(java.util.Date.parse('yyyy-MM-dd HH:mm', '#{resource[:start_date]} #{resource[:start_time]}'))"
      when :daily
        "org.sonatype.nexus.scheduling.schedule.Daily(java.util.Date.parse('yyyy-MM-dd HH:mm', '#{resource[:start_date]} #{resource[:start_time]}'))"
      when :weekly
        days_to_run = "#{resource[:recurring_day].split(',').map{|day| day[0..2].upcase}}.collect{ org.sonatype.nexus.scheduling.schedule.Weekly.Weekday.valueOf(it) }"
        "org.sonatype.nexus.scheduling.schedule.Weekly(java.util.Date.parse('yyyy-MM-dd HH:mm', '#{resource[:start_date]} #{resource[:start_time]}'), new HashSet(#{days_to_run}))"
      when :monthly
        days_to_run = "#{resource[:recurring_day].split(',').map{|day| day == 'last' ? 999 : day.to_i}}.collect{ org.sonatype.nexus.scheduling.schedule.Monthly.CalendarDay.day(it) }"
        "org.sonatype.nexus.scheduling.schedule.Monthly(java.util.Date.parse('yyyy-MM-dd HH:mm', '#{resource[:start_date]} #{resource[:start_time]}'), new HashSet(#{days_to_run}))"
      when :advanced
        "org.sonatype.nexus.scheduling.schedule.Cron(new java.util.Date(), '#{resource[:cron_expression]}')"
      end
    end
  end
end
