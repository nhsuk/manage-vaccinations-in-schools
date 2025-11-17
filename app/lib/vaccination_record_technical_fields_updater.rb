# frozen_string_literal: true

# Service object to update technically functional fields on a vaccination record
# Extracted so it can be reused by CLI commands like `vaccination-records edit`
# and `vaccination-records bulk-edit`.
class VaccinationRecordTechnicalFieldsUpdater
  ALLOWED_ATTRIBUTES = %w[
    confirmation_sent_at
    nhs_immunisations_api_etag
    nhs_immunisations_api_identifier_system
    nhs_immunisations_api_identifier_value
    nhs_immunisations_api_primary_source
    nhs_immunisations_api_sync_pending_at
    nhs_immunisations_api_synced_at
    source
    uuid
    created_at
    updated_at
    nhs_immunisations_api_id
    session_id
  ].freeze

  DATETIME_COLUMNS = %w[
    confirmation_sent_at
    nhs_immunisations_api_sync_pending_at
    nhs_immunisations_api_synced_at
    created_at
    updated_at
  ].freeze

  BOOLEAN_COLUMNS = %w[nhs_immunisations_api_primary_source].freeze

  INTEGER_COLUMNS = %w[session_id source].freeze

  def initialize(vaccination_record:, updates:)
    @record = vaccination_record
    @updates = updates
  end

  def call
    unless updates.is_a?(Hash)
      raise "updates must be a Hash of attribute=>value"
    end

    parsed_updates = {}

    updates.each do |raw_key, raw_value|
      key = raw_key.to_s

      unless ALLOWED_ATTRIBUTES.include?(key)
        raise "Attribute '#{key}' is not editable by this tool"
      end

      parsed_updates[key] = coerce_value(key, raw_value)
    end

    record.assign_attributes(parsed_updates)
    record.save!(touch: false)
  end

  def self.call(...) = new(...).call

  private_class_method :new

  private

  attr_reader :record, :updates

  def coerce_value(key, value)
    # nil handling
    return nil if value.nil?
    return nil if value.is_a?(String) && value.strip.casecmp("nil").zero?

    # datetime
    if DATETIME_COLUMNS.include?(key)
      if value.respond_to?(:in_time_zone)
        return value
      elsif value.is_a?(String)
        t = Time.zone.parse(value)
        raise ArgumentError, "invalid datetime '#{value}'" if t.nil?
        return t
      else
        raise ArgumentError, "invalid datetime '#{value.inspect}'"
      end
    end

    # boolean
    if BOOLEAN_COLUMNS.include?(key)
      return value if [true, false].include?(value)
      return to_bool(value) if value.is_a?(String)
      raise ArgumentError, "invalid boolean '#{value.inspect}'"
    end

    # integer
    if INTEGER_COLUMNS.include?(key)
      return value.to_i if value.is_a?(Integer)
      return Integer(value) if value.is_a?(String) || value.is_a?(Numeric)
      raise ArgumentError, "invalid integer '#{value.inspect}'"
    end

    # default: pass through as-is (e.g. string)
    value
  end

  def to_bool(val)
    case val.strip.downcase
    when "true", "1", "yes", "y"
      true
    when "false", "0", "no", "n"
      false
    else
      raise ArgumentError, "invalid boolean '#{val}'"
    end
  end
end
