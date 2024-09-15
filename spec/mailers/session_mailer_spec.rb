# frozen_string_literal: true

describe SessionMailer do
  describe "#reminder" do
    subject(:mail) do
      described_class.with(session:, patient:, parent:).reminder
    end

    let(:patient) { create(:patient, common_name: "Joey") }
    let(:session) { create(:session, patients: [patient]) }
    let(:parent) { patient.parents.first }

    it { should have_attributes(to: [patient.parents.first.email]) }

    describe "personalisation" do
      subject(:personalisation) do
        mail.message.header["personalisation"].unparsed_value
      end

      it "sets the personalisation" do
        expect(personalisation.keys).to include(
          :full_and_preferred_patient_name,
          :location_name,
          :parent_name,
          :session_date,
          :short_patient_name,
          :short_patient_name_apos,
          :team_email,
          :team_name,
          :team_phone,
          :vaccination
        )
      end
    end
  end
end
