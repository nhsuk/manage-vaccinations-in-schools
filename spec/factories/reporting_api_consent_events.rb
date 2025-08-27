FactoryBot.define do
  factory :reporting_api_consent_event, class: "ReportingAPI::ConsentEvent" do
    transient do
      consent { build(:consent) }
    end

    source { association(:source) } 
    event_timestamp { consent.consent_form&.recorded_at || consent.submitted_at }
    event_type { consent.response }
    
    after(:build) do |instance, context|
      instance.source.team.strict_loading!(false)

      instance.copy_attributes_from_references(
        patient: instance.source.patient,
        # patient_local_authority: instance.source.patient&.local_authority_from_postcode,
        parent: instance.source.parent,
        parent_relationship: instance.source.patient.parent_relationships.find_by(parent_id: instance.source.parent_id),
        consent: instance.source,
        programme: instance.source.programme,
        team: instance.source.team,
        organisation: instance.source.team&.organisation,
      )
    end
  end

  factory :reporting_api_consent_notification_event, class: "ReportingAPI::ConsentEvent" do
     
    patient { build(:patient, parents: build_list(:parent, 2)) }
    source { association(:source) } 
    event_timestamp { Time.current }
    event_type { 'request' }
    programme_id { source.programmes.first.id }
    programme_type { source.programmes.first.type }
    
    after(:build) do |instance, context|
      instance.source.session.team.strict_loading!(false)
    
      instance.copy_attributes_from_references(
        consent_notification: instance.source,
        patient: instance.patient,
        patient_school: instance.patient.school,
        # patient_local_authority: instance.patient&.local_authority_from_postcode,
        parent: instance.patient.parents.first,
        parent_relationship: instance.patient.parent_relationships.find_by(parent_id: instance.patient.parents.first&.id),
        team: instance.source.session&.team,
        organisation: instance.source.session&.team&.organisation 
      )
    end
  end
end