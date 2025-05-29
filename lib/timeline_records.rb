# frozen_string_literal: true

class TimelineRecords
  DEFAULT_DETAILS_CONFIG = {
    consents: %i[response route],
    sessions: %i[],
    session_attendances: %i[],
    triages: %i[status performed_by_user_id],
    vaccination_records: %i[outcome session_id],
    organisation: %i[],
    cohort_imports: %i[],
    class_imports: %i[],
    parents: %i[],
    patient_sessions: %i[session_id],
    gillick_assessments: %i[],
    parent_relationships: %i[],
    school_moves: %i[school_id source],
    school_move_log_entries: %i[school_id user_id]
  }.freeze

  AVAILABLE_DETAILS_CONFIG = {
    consents: %i[response route updated_at withdrawn_at invalidated_at],
    sessions: %i[slug academic_year],
    session_attendances: %i[attending updated_at],
    triages: %i[status updated_at invalidated_at performed_by_user_id],
    vaccination_records: %i[
      outcome
      performed_at
      updated_at
      discarded_at
      uuid
      session_id
    ],
    organisation: %i[name ods_code],
    cohort_imports: %i[
      csv_filename
      processed_at
      status
      rows_count
      new_record_count
      exact_duplicate_record_count
      changed_record_count
    ],
    class_imports: %i[
      csv_filename
      processed_at
      status
      rows_count
      new_record_count
      exact_duplicate_record_count
      changed_record_count
      year_groups
    ],
    parents: %i[],
    patient_sessions: %i[],
    gillick_assessments: %i[],
    parent_relationships: %i[],
    school_moves: %i[school_id source],
    school_move_log_entries: %i[school_id user_id]
  }.freeze

  AVAILABLE_DETAILS_CONFIG_WITH_PII = {
    consents: %i[response route updated_at withdrawn_at invalidated_at],
    sessions: %i[slug academic_year],
    session_attendances: %i[attending updated_at],
    triages: %i[status updated_at invalidated_at performed_by_user_id],
    vaccination_records: %i[
      outcome
      performed_at
      updated_at
      discarded_at
      uuid
      session_id
    ],
    organisation: %i[name ods_code],
    cohort_imports: %i[
      csv_filename
      processed_at
      status
      rows_count
      new_record_count
      exact_duplicate_record_count
      changed_record_count
    ],
    class_imports: %i[
      csv_filename
      processed_at
      status
      rows_count
      new_record_count
      exact_duplicate_record_count
      changed_record_count
      year_groups
    ],
    parents: %i[full_name email phone],
    patient_sessions: %i[session_id],
    gillick_assessments: %i[
      knows_vaccination
      knows_disease
      knows_consequences
      knows_delivery
      knows_side_effects
    ],
    parent_relationships: %i[type other_name],
    school_moves: %i[school_id source],
    school_move_log_entries: %i[school_id user_id]
  }.freeze

  DEFAULT_AUDITS_CONFIG = {
    include_associated_audits: true,
    include_filtered_audit_changes: false
  }.freeze

  ALLOWED_AUDITED_CHANGES = %i[
    patient_id
    session_id
    programme_id
    vaccine_id
    organisation_id
    school_id
    gp_practice_id
    uploaded_by_user_id
    performed_by_user_id
    user_id
    parent_id
    status
    outcome
    response
    route
    date_of_death_recorded_at
    restricted_at
    invalidated_at
    withdrawn_at
    rows_count
    year_groups
    home_educated
    source
  ].freeze

  ALLOWED_AUDITED_CHANGES_WITH_PII = %i[
    full_name
    email
    phone
    nhs_number
    given_name
    family_name
    date_of_birth
    address_line_1
    address_line_2
    address_town
    address_postcode
    home_educated
    updated_from_pds_at
    restricted_at
    date_of_death
    pending_changes
    patient_id
    session_id
    programme_id
    vaccine_id
    organisation_id
    school_id
    gp_practice_id
    uploaded_by_user_id
    performed_by_user_id
    user_id
    parent_id
    status
    outcome
    response
    route
    date_of_death_recorded_at
    restricted_at
    invalidated_at
    withdrawn_at
    rows_count
    year_groups
    home_educated
    source
  ].freeze

  def initialize(patient, detail_config: {}, audit_config: {}, show_pii: false)
    @patient = patient
    @patient_id = @patient.id
    @patient_events = patient_events(@patient)
    @additional_events = additional_events(@patient)
    @detail_config = extract_detail_config(detail_config)
    @events = []
    @audit_config = audit_config
    @show_pii = show_pii
  end

  def render_timeline(*event_names, truncate_columns: false)
    load_grouped_events(event_names)
    format_timeline_console(truncate_columns)
  end

  def additional_events(patient)
    patient_imports = patient_events(patient)[:class_imports]
    class_imports =
      ClassImport.where(session_id: patient_events(patient)[:sessions])
    class_imports =
      class_imports.where.not(id: patient_imports) if patient_imports.present?
    {
      class_imports:
        class_imports
          .group_by(&:session_id)
          .transform_values { |imports| imports.map(&:id) },
      cohort_imports:
        patient
          .organisation
          .cohort_imports
          .map(&:id)
          .reject { |id| patient_events(patient)[:cohort_imports].include?(id) }
    }
  end

  def patient_events(patient)
    {
      class_imports: patient.class_imports.map(&:id),
      cohort_imports: patient.cohort_imports.map(&:id),
      sessions: patient.sessions.map(&:id)
    }
  end

  def extract_detail_config(detail_config)
    detail_config.deep_symbolize_keys
  end

  def details
    @details ||= DEFAULT_DETAILS_CONFIG.merge(@detail_config)
  end

  def audits
    @audits ||= DEFAULT_AUDITS_CONFIG.merge(@audit_config)
  end

  def load_events(event_names)
    event_names.each do |event_name|
      event_type = event_name.to_sym

      if details.key?(event_type)
        fields = details[event_type]
        records = @patient.send(event_type)
        records = Array(records)

        records.each do |record|
          event_details =
            fields.each_with_object({}) do |field, hash|
              field_value = record.send(field)
              hash[field.to_s] = field_value.nil? ? "nil" : field_value
            end
          @events << {
            event_type: record.class.name,
            id: record.id,
            details: event_details,
            created_at: record.created_at
          }
        end
      else
        custom_event_handler(event_type)
      end
    end
    @events.sort_by! { |event| event[:created_at] }.reverse!
  end

  def load_grouped_events(event_names)
    load_events(event_names)
    @grouped_events =
      @events.group_by do |event|
        event[:created_at].strftime(Date::DATE_FORMATS[:long])
      end
  end

  private

  def custom_event_handler(event_type)
    case event_type
    when :org_cohort_imports
      @events += org_cohort_imports_events
    when /^add_class_imports_\d+$/ # e.g. add_class_imports_123
      session_id = event_type.to_s.split("_").last
      @events += add_class_imports_events(session_id)
    when :audits
      @events += audits_events
    else
      puts "No handler for event type: #{event_type}"
    end
  end

  def org_cohort_imports_events
    CohortImport
      .where(id: @additional_events[:cohort_imports])
      .map do |cohort_import|
        {
          event_type: "CohortImport",
          id: cohort_import.id,
          details: "excluding patient",
          created_at: cohort_import.created_at
        }
      end
  end

  def add_class_imports_events(session_id)
    ClassImport
      .where(id: @additional_events[:class_imports][session_id.to_i])
      .map do |class_import|
        {
          event_type: "ClassImport",
          id: class_import.id,
          details: {
            session_id: "#{class_import.session_id}, excluding patient"
          },
          created_at: class_import.created_at.to_time
        }
      end
  end

  def audits_events
    audit_events =
      (
        if audits[:include_associated_audits]
          @patient.own_and_associated_audits
        else
          @patient.audits
        end
      ).reject { it.audited_changes.keys == ["updated_from_pds_at"] }

    allowed_changes =
      @show_pii ? ALLOWED_AUDITED_CHANGES_WITH_PII : ALLOWED_AUDITED_CHANGES

    audit_events.map do |audit|
      filtered_changes =
        audit
          .audited_changes
          .each_with_object({}) do |(key, value), hash|
            if allowed_changes.include?(key.to_sym)
              hash[key] = value
            elsif audits[:include_filtered_audit_changes]
              hash[key] = "[FILTERED]"
            end
          end

      event_type = "#{audit.auditable_type}-Audit"

      event_details = { action: audit.action }
      event_details[
        :audited_changes
      ] = filtered_changes.deep_symbolize_keys unless filtered_changes.empty?
      event_details[:auditable_id] = audit.auditable_id

      {
        event_type: event_type,
        id: audit.id,
        details: event_details,
        created_at: audit.created_at
      }
    end
  end

  def format_timeline_console(truncate_columns)
    event_type_width = 25
    details_width = 50
    header_format =
      if truncate_columns
        "%-12s %-10s %-#{event_type_width}s %-12s %-#{details_width}s"
      else
        "%-12s %-10s %-20s %-10s %-s"
      end
    puts sprintf(
           header_format,
           "DATE",
           "TIME",
           "EVENT_TYPE",
           "EVENT-ID",
           "DETAILS"
         )
    puts "-" * 115

    @grouped_events.each do |date, events|
      puts "=== #{date} ===\n" + "-" * 115
      events.each do |event|
        time = event[:created_at].strftime("%H:%M:%S")
        event_type = event[:event_type].to_s
        event_id = event[:id].to_s
        details_string =
          if event[:details].is_a?(Hash)
            event[:details].map { |k, v| "#{k}: #{v}" }.join(", ")
          else
            event[:details].to_s
          end
        if truncate_columns
          event_type = event_type.ljust(event_type_width)[0...event_type_width]
          details = details_string.ljust(details_width)[0...details_width]
        else
          details = details_string
        end
        puts sprintf(header_format, "", time, event_type, event_id, details)
      end
    end
    nil
  end
end
