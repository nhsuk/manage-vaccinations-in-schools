require "rails_helper"

describe SessionMailer, type: :mailer do
  describe "#session_reminder" do
    let(:patient) { create(:patient, common_name: "Joey") }
    let(:session) { create(:session, patients: [patient]) }
    subject(:mail) { SessionMailer.session_reminder(session:, patient:) }

    it { should have_attributes(to: [patient.parent.email]) }

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
