class AddIndexesForReportingTables < ActiveRecord::Migration[8.0]
  def change
    add_index :reportable_consent_events, [:event_timestamp], name: 'ix_rpt_consent_event_tstamp'
    add_index :reportable_consent_events, [:event_timestamp_academic_year, :event_timestamp_month], name: 'ix_rpt_consent_event_ac_year_month'
    add_index :reportable_consent_events, [:source_type, :source_id], name: 'ix_rpt_consent_source_type_id'
    add_index :reportable_consent_events, [:event_timestamp_academic_year, :event_timestamp_month, :programme_id, :event_type], name: 'ix_rpt_consent_event_tstamp_year_month_prog_type'

    add_index :reportable_vaccination_events, [:event_timestamp], name: 'ix_rpt_vaccination_event_tstamp'
    add_index :reportable_vaccination_events, [:event_timestamp_academic_year, :event_timestamp_month], name: 'ix_rpt_vaccination_event_ac_year_month'
    add_index :reportable_vaccination_events, [:source_type, :source_id], name: 'ix_rpt_vaccination_source_type_id'
    add_index :reportable_vaccination_events, [:event_timestamp_academic_year, :event_timestamp_month, :programme_id, :event_type], name: 'ix_rpt_vaccination_event_tstamp_year_month_prog_type'
  end
end
