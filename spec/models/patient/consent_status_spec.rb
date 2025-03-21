# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_consent_statuses
#
#  id                               :bigint           not null, primary key
#  health_answers_require_follow_up :boolean          default(FALSE), not null
#  status                           :integer          default("no_response"), not null
#  patient_id                       :bigint           not null
#  programme_id                     :bigint           not null
#
# Indexes
#
#  index_patient_consent_statuses_on_patient_id_and_programme_id  (patient_id,programme_id) UNIQUE
#  index_patient_consent_statuses_on_status                       (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
describe Patient::ConsentStatus do
  subject(:patient_consent_status) { build(:patient_consent_status) }

  it { should belong_to(:patient) }
  it { should belong_to(:programme) }

  it do
    expect(patient_consent_status).to define_enum_for(:status).with_values(
      %i[no_response given refused conflicts]
    )
  end
end
