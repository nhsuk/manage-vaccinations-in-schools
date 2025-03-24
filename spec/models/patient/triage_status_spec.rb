# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_triage_statuses
#
#  id           :bigint           not null, primary key
#  status       :integer          default("not_required"), not null
#  patient_id   :bigint           not null
#  programme_id :bigint           not null
#
# Indexes
#
#  index_patient_triage_statuses_on_patient_id_and_programme_id  (patient_id,programme_id) UNIQUE
#  index_patient_triage_statuses_on_status                       (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
describe Patient::TriageStatus do
  subject(:patient_triage_status) { build(:patient_triage_status) }

  it { should belong_to(:patient) }
  it { should belong_to(:programme) }

  it do
    expect(patient_triage_status).to define_enum_for(:status).with_values(
      %i[
        not_required
        required
        safe_to_vaccinate
        do_not_vaccinate
        delay_vaccination
      ]
    )
  end
end
