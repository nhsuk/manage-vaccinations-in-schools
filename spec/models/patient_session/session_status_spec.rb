# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_session_session_statuses
#
#  id                 :bigint           not null, primary key
#  status             :integer          default("none_yet"), not null
#  patient_session_id :bigint           not null
#  programme_id       :bigint           not null
#
# Indexes
#
#  idx_on_patient_session_id_programme_id_8777f5ba39  (patient_session_id,programme_id) UNIQUE
#  index_patient_session_session_statuses_on_status   (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
describe PatientSession::SessionStatus do
  subject(:patient_session_session_status) do
    build(:patient_session_session_status, patient_session:, programme:)
  end

  let(:patient_session) { create(:patient_session, programmes: [programme]) }
  let(:programme) { create(:programme) }

  it { should belong_to(:patient_session) }
  it { should belong_to(:programme) }

  it do
    expect(patient_session_session_status).to define_enum_for(
      :status
    ).with_values(
      %i[
        none_yet
        vaccinated
        already_had
        had_contraindications
        refused
        absent_from_session
        unwell
        absent_from_school
      ]
    )
  end
end
