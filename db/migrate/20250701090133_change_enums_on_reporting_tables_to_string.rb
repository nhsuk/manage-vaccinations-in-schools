class ChangeEnumsOnReportingTablesToString < ActiveRecord::Migration[8.0]
  def up
    add_column :reportable_vaccination_events, :vaccination_record_delivery_site, :string

    change_column :reportable_vaccination_events, :vaccination_record_delivery_method, :string
    change_column :reportable_vaccination_events, :vaccination_record_outcome, :string
    
    change_column :reportable_consent_events, :consent_response, :string
    change_column :reportable_consent_events, :consent_reason_for_refusal, :string
    change_column :reportable_consent_events, :consent_route, :string
  end

  def down
    add_column :reportable_consent_events, :consent_route_int, :integer
    add_column :reportable_consent_events, :consent_reason_for_refusal_int, :integer
    add_column :reportable_consent_events, :consent_response_int, :integer
    
    ReportableConsentEvent.find_each do |rce|
      rce.update(
        consent_response_int: Consent.responses[rce.consent_response&.to_sym],
        consent_reason_for_refusal_int: Consent.reason_for_refusals[rce.consent_reason_for_refusal&.to_sym],
        consent_route_int: Consent.routes[rce.consent_route&.to_sym],
      )
    end

    remove_column :reportable_consent_events, :consent_response
    remove_column :reportable_consent_events, :consent_reason_for_refusal
    remove_column :reportable_consent_events, :consent_route

    rename_column :reportable_consent_events, :consent_response_int, :consent_response
    rename_column :reportable_consent_events, :consent_reason_for_refusal_int, :consent_reason_for_refusal
    rename_column :reportable_consent_events, :consent_route_int, :consent_route
    

    add_column :reportable_vaccination_events, :vaccination_record_delivery_method_int, :integer
    add_column :reportable_vaccination_events, :vaccination_record_outcome_int, :integer

    ReportableVaccinationEvent.find_each do |rve|
      rve.update(
        vaccination_record_delivery_method_int: VaccinationRecord.delivery_methods[rve.vaccination_record_delivery_method&.to_sym],
        vaccination_record_outcome_int: VaccinationRecord.outcomes[rve.vaccination_record_outcome&.to_sym],
      )
    end

    remove_column :reportable_vaccination_events, :vaccination_record_delivery_method
    remove_column :reportable_vaccination_events, :vaccination_record_outcome

    rename_column :reportable_vaccination_events, :vaccination_record_delivery_method_int, :vaccination_record_delivery_method
    rename_column :reportable_vaccination_events, :vaccination_record_outcome_int, :vaccination_record_outcome

  end
end
