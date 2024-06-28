# frozen_string_literal: true

require "rails_helper"

describe ConsentRequestMailer, type: :mailer do
  describe "#consent_request" do
    subject(:mail) { ConsentRequestMailer.consent_request(session, patient) }
    let(:patient) { create(:patient) }
    let(:session) { create(:session, patients: [patient]) }

    it { should have_attributes(to: [patient.parent.email]) }

    describe "personalisation" do
      subject { mail.message.header["personalisation"].unparsed_value }

      it { should include(session_date: session.date.strftime("%A %-d %B")) }
      it { should include(session_short_date: session.date.strftime("%-d %B")) }
      it do
        should include(
                 close_consent_date:
                   session.close_consent_at.strftime("%A %-d %B")
               )
      end
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

  describe "#consent_reminder" do
    subject(:mail) { ConsentRequestMailer.consent_reminder(session, patient) }
    let(:patient) { create(:patient) }
    let(:session) { create(:session, patients: [patient]) }

    it { should have_attributes(to: [patient.parent.email]) }

    describe "personalisation" do
      subject { mail.message.header["personalisation"].unparsed_value }

      it { should include(session_date: session.date.strftime("%A %-d %B")) }
      it do
        should include(
                 close_consent_date:
                   session.close_consent_at.strftime("%A %-d %B")
               )
      end
      it do
        should include(
                 close_consent_short_date:
                   session.close_consent_at.strftime("%-d %B")
               )
      end
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
