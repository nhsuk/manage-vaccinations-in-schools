# frozen_string_literal: true

describe SessionMailer, type: :mailer do
  describe "#session_reminder" do
    subject(:mail) do
      described_class.session_reminder(session:, patient:, parent:)
    end

    let(:patient) { create(:patient, common_name: "Joey") }
    let(:session) { create(:session, patients: [patient]) }
    let(:parent) { patient.parents.first }

    it { should have_attributes(to: [patient.parents.first.email]) }

    describe "personalisation" do
      subject { mail.message.header["personalisation"].unparsed_value }

      it "sets the personalisation" do
        expect(subject.keys).to include(
          :full_and_preferred_patient_name,
          :location_name,
          :long_date,
          :parent_name,
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
