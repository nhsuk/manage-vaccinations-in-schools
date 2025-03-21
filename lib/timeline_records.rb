# frozen_string_literal: true

class TimelineRecords
  DEFAULT_DETAILS_CONFIG = {
      cohort_imports: [],
      class_imports: [],
      patient_sessions: %i[session_id],
      school_moves: %i[school_id source],
      school_move_log_entries: %i[school_id user_id],
      consents: %i[response route],
      triages: %i[status performed_by_user_id],
      vaccination_records: %i[outcome session_id]
    }.freeze

  AVAILABLE_DETAILS_CONFIG = {
    cohort_imports: %i[rows_count status uploaded_by_user_id],
    class_imports: %i[rows_count year_groups uploaded_by_user_id session_id],
    patient_sessions: %i[session_id],
    school_moves: %i[source school_id home_educated],
    school_move_log_entries: %i[user_id school_id home_educated],
    consents: %i[programme_id response route parent_id withdrawn_at invalidated_at],
    triages: %i[status performed_by_user_id programme_id invalidated_at],
    vaccination_records: %i[outcome performed_by_user_id programme_id session_id vaccine_id]
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

  def initialize(
      patient_id, 
      detail_config: {}, 
      audit_config: {}
    )
    @patient = Patient.find(patient_id)
    @patient_id = patient_id
    @patient_events = patient_events(@patient)
    @additional_events = additional_events(@patient)
    @detail_config = extract_detail_config(detail_config)
    @events = []
    @audit_config = audit_config
  end

  def generate_timeline_console(*event_names, truncate_columns: true)
    load_grouped_events(event_names)
    format_timeline_console(truncate_columns)
  end

  def additional_events(patient)
    patient_imports = patient_events(patient)[:class_imports]
    class_imports = ClassImport.where(session_id: patient_events(patient)[:sessions])
    class_imports = class_imports.where.not(id: patient_imports) if patient_imports.present?
    {
      class_imports: class_imports.group_by(&:session_id).transform_values { |imports| imports.map(&:id) },
      cohort_imports: patient.organisation.cohort_imports
                        .reject { 
                          |ci| patient_events(patient)[:cohort_imports].include?(ci.id) 
                        }
                        .map(&:id)
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
          event_details = fields.map { |field| 
            field_value = record.send(field)
            [field.to_s, field_value.nil? ? "nil" : field_value]
          }.to_h
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
    @events.sort_by!{ |event| event[:created_at] }.reverse!
  end 

  def load_grouped_events(event_names)
    load_events(event_names)
    @events.each do |event|
      event[:details] = format_details(event)
    end
    @grouped_events = @events.group_by { |event|
    event[:created_at].strftime(Date::DATE_FORMATS[:long]) }.sort_by{ |date, _events| date }.reverse!.to_h
  end

  private

  def format_details(event)
    if event[:details].is_a?(Hash)
      event[:details].map { |k, v| "#{k}: #{v}" }.join(", ")
    else
      event[:details].to_s
    end
  end

  def custom_event_handler(event_type)
    case event_type
    when :org_cohort_imports
      @events += org_cohort_imports_events
    when /^add_class_imports_\d+$/ # e.g. add_class_imports_123
      session_id = event_type.to_s.split('_').last
      @events += add_class_imports_events(session_id)
    when :audits
      @events += audits_events
    else
      puts "No handler for event type: #{event_type}"
    end
  end

  def org_cohort_imports_events
    @additional_events[:cohort_imports].map do |cohort_import_id|
      cohort_import = CohortImport.find(cohort_import_id)
      {
        event_type: 'CohortImport',
        id: cohort_import.id,
        details: "excluding patient",
        created_at: cohort_import.created_at
      }
    end
  end

  def add_class_imports_events(session_id)
    @additional_events[:class_imports][session_id.to_i].map do |class_import_id|
      class_import = ClassImport.find(class_import_id)
      { 
        event_type: 'ClassImport',
        id: class_import.id,
        details: { session_id: "#{class_import.session_id}, excluding patient" },
        created_at: class_import.created_at.to_time
      }
    end
  end

  def audits_events
    audit_events = audits[:include_associated_audits] ? @patient.own_and_associated_audits : @patient.audits
    
    audit_events.map do |audit|
      filtered_changes = audit.audited_changes.transform_keys(&:to_s).each_with_object({}) do |(key, value), hash|
        if ALLOWED_AUDITED_CHANGES.include?(key.to_sym)
          hash[key] = value
        elsif audits[:include_filtered_audit_changes]
          hash[key] = "[FILTERED]"
        end
      end
      
      event_type = "#{audit.auditable_type}-Audit"
      
      event_details = { action: audit.action }
      event_details[:audited_changes] = filtered_changes.deep_symbolize_keys unless filtered_changes.empty?
      
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
    header_format = if truncate_columns
                      "%-12s %-10s %-#{event_type_width}s %-12s %-#{details_width}s"
                    else
                      "%-12s %-10s %-20s %-10s %-s"
                    end 
    puts sprintf(header_format, "DATE", "TIME", "EVENT_TYPE", "EVENT-ID", "DETAILS")
    puts "-" * 115
    
    @grouped_events.each do |date, events|
      puts "=== #{date} ===\n" + "-" * 115
      events.each do |event|
        time = event[:created_at].strftime('%H:%M:%S')
        event_type = event[:event_type].to_s
        event_id = event[:id].to_s
        details_string = if event[:details].is_a?(Hash)
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
