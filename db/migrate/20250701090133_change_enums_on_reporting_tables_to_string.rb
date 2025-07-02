class ChangeEnumsOnReportingTablesToString < ActiveRecord::Migration[8.0]
  def change
    add_column :reportable_vaccination_events, :vaccination_record_delivery_site, :string

    change_column :reportable_vaccination_events, :vaccination_record_delivery_method, :string
    change_column :reportable_vaccination_events, :vaccination_record_outcome, :string
    
    change_column :reportable_consent_events, :consent_response, :string
    change_column :reportable_consent_events, :consent_reason_for_refusal, :string
    change_column :reportable_consent_events, :consent_route, :string
  end
end
