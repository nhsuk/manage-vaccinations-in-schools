# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_session_registration_statuses
#
#  id                 :bigint           not null, primary key
#  status             :integer          default("unknown"), not null
#  patient_session_id :bigint           not null
#
# Indexes
#
#  idx_on_patient_session_id_438fc21144                   (patient_session_id) UNIQUE
#  index_patient_session_registration_statuses_on_status  (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_session_id => patient_sessions.id) ON DELETE => cascade
#
describe PatientSession::RegistrationStatus do
  subject(:patient_session_registration_status) do
    build(:patient_session_registration_status)
  end

  it { should belong_to(:patient_session) }

  it do
    expect(patient_session_registration_status).to define_enum_for(
      :status
    ).with_values(%i[unknown attending not_attending completed])
  end
end
