
FactoryBot.define do
  factory :reporting_api_vaccination_event, class: "ReportingAPI::VaccinationEvent" do
    transient do
      outcome { 'administered' }
      year_group { 9 }
      for_patient { build(:patient, year_group: year_group, random_nhs_number: true) }
      programme { Programme.find_by(type: 'flu') || build(:programme, type: 'flu') }
    end

    source { build(:vaccination_record, patient: for_patient, programme: programme, outcome: outcome, performed_by: User.first) }
    patient { for_patient }
    vaccination_record_outcome { outcome }
    patient_year_group { year_group }
  end
end