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
