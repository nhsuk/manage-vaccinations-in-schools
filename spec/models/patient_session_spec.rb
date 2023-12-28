# == Schema Information
#
# Table name: patient_sessions
#
#  id                       :bigint           not null, primary key
#  gillick_competence_notes :text
#  gillick_competent        :boolean
#  state                    :string
#  created_at               :datetime         not null
#  updated_at               :datetime         not null
#  patient_id               :bigint           not null
#  session_id               :bigint           not null
#
# Indexes
#
#  index_patient_sessions_on_patient_id_and_session_id  (patient_id,session_id) UNIQUE
#  index_patient_sessions_on_session_id_and_patient_id  (session_id,patient_id) UNIQUE
#
require "rails_helper"

RSpec.describe PatientSession do
  describe "#vaccine_record" do
    it "returns the last non-draft vaccination record" do
      patient_session = create(:patient_session)
      vaccination_record = create(:vaccination_record, patient_session:)
      vaccination_record.update!(recorded_at: 1.day.ago)
      draft_vaccination_record = create(:vaccination_record, patient_session:)
      draft_vaccination_record.update!(recorded_at: nil)

      expect(patient_session.vaccination_record).to eq vaccination_record
    end
  end
end
