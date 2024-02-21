require "rails_helper"

RSpec.describe ConsentRequestMailer, type: :mailer do
  describe "#consent_request" do
    let(:patient) { create(:patient) }
    let(:session) { create(:session, patients: [patient]) }
    subject(:mail) { ConsentRequestMailer.consent_request(session, patient) }

    it { should have_attributes(to: [patient.parent_email]) }

    describe "personalisation" do
      subject { mail.message.header["personalisation"].unparsed_value }

      it { should include(short_date: session.date.strftime("%-d %B")) }
      it { should include(long_date: session.date.strftime("%A %-d %B")) }
      it { should include(location_name: session.location.name) }
      it { should include(team_email: session.team.email) }
      it { should include(team_phone: session.team.phone) }

      it "uses the consent url for the session" do
        should include(
                 consent_link:
                   start_session_parent_interface_consent_forms_url(session)
               )
      end
    end
  end
end
