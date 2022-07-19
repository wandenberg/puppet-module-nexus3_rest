# frozen_string_literal: true

require 'puppet/resource_api/simple_provider'
require 'puppet/provider/nexus3_utils'

# Implementation for the nexus3_task type using the Resource API.
class Puppet::Provider::Nexus3Task::Nexus3Task < Puppet::ResourceApi::SimpleProvider
  include Puppet::Provider::Nexus3Utils

  def canonicalize(context, resources)
    resources.each do |r|
      next if skip_resource?(r)

      apply_default_values(context, r)

      assert_present(r[:type], 'type must not be empty')
      raise ArgumentError, 'Multiple recurring days must be provided as an array.' unless r[:recurring_day].to_s.empty? || r[:recurring_day].is_a?(Array)

      munge_booleans(context, r)

      case r[:frequency]
      when 'once', 'hourly', 'daily'
        reject_specified_properties(r, %i[cron_expression recurring_day])
        ensure_specified_properties(r, %i[start_date start_time])
      when 'weekly'
        reject_specified_properties(r, %i[cron_expression])
        ensure_specified_properties(r, %i[start_date start_time recurring_day])
        ensure_recurring_day_in(r, %w[monday tuesday wednesday thursday friday saturday sunday])
      when 'monthly'
        reject_specified_properties(r, %i[cron_expression])
        ensure_specified_properties(r, %i[start_date start_time recurring_day])
        ensure_recurring_day_in(r, [('1'..'31').to_a, 'last'].flatten)
      when 'advanced'
        reject_specified_properties(r, %i[start_date start_time recurring_day])
        assert_present(r[:cron_expression], 'cron_expression must not be empty')
      else
        reject_specified_properties(r, %i[cron_expression recurring_day start_date start_time])
      end
    end
  end

  private

  # Ensure all listed properties have non-empty values set.
  #
  def ensure_specified_properties(resource, properties)
    missing_fields = properties.map { |property| property if resource[property].to_s.empty? || resource[property].empty? }.compact
    raise ArgumentError, "Setting frequency to '#{resource[:frequency]}' requires #{missing_fields.join(' and ')} to be set as well" unless missing_fields.empty?
  end

  # Ensure none of the listed properties is specified (the properties references a value).
  #
  def reject_specified_properties(resource, properties)
    rejected_properties = properties.map { |property| property unless resource[property].to_s.empty? || resource[property].empty? }.compact
    raise ArgumentError, "#{rejected_properties.join(' and ')} not allowed when frequency is set to '#{resource[:frequency]}'" unless rejected_properties.empty?
  end

  # Ensure all items of the recurring_day property are included in the given list of items.
  #
  # Note: make sure to pass an array with elements of the type string; otherwise there may be issues with the data types.
  def ensure_recurring_day_in(resource, valid_items)
    resource[:recurring_day].each do |item|
      raise ArgumentError, "Recurring day must be one of [#{valid_items.join(', ')}], got '#{item}'" unless valid_items.include?(item.to_s)
    end
  end
end
