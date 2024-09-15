# frozen_string_literal: true

describe ConsentMailer do
  describe "#confirmation_injection" do
    subject(:mail) do
      described_class.with(consent_form:).confirmation_injection
    end

    let(:consent_form) do
      create(
        :consent_form,
        :recorded,
        :refused,
        reason: :contains_gelatine,
        session: create(:session, programme: create(:programme, :flu))
      )
    end

    it "calls template_mail with correct reason_for_refusal" do
      expect(mail.message.header["personalisation"].unparsed_value).to include(
        reason_for_refusal: "of the gelatine in the nasal spray"
      )
    end
  end

  describe "#give_feedback" do
    context "with a consent form" do
      subject(:mail) { described_class.with(consent_form:).give_feedback }

      let(:consent_form) do
        create(:consent_form, :recorded, recorded_at: Date.new(2021, 1, 1))
      end

      it "calls template_mail with correct survey_deadline_date" do
        expect(
          mail.message.header["personalisation"].unparsed_value
        ).to include(survey_deadline_date: "8 January 2021")
      end
    end

    context "with a consent record" do
      subject(:mail) { described_class.with(consent:, session:).give_feedback }

      let(:session) { create(:session) }
      let(:consent) do
        create(
          :consent,
          :recorded,
          recorded_at: Date.new(2021, 1, 1),
          programme: session.programme
        )
      end

      it "calls template_mail with correct survey_deadline_date" do
        expect(
          mail.message.header["personalisation"].unparsed_value
        ).to include(survey_deadline_date: "8 January 2021")
      end
    end
  end

  describe "#request" do
    subject(:mail) { described_class.with(session:, patient:, parent:).request }

    let(:patient) { create(:patient) }
    let(:parent) { patient.parents.first }
    let(:session) { create(:session, patients: [patient]) }

    it { should have_attributes(to: [parent.email]) }

    describe "personalisation" do
      subject(:personalisation) do
        mail.message.header["personalisation"].unparsed_value
      end

      it { should include(session_date: session.date.strftime("%A %-d %B")) }
      it { should include(session_short_date: session.date.strftime("%-d %B")) }

      it do
        expect(personalisation).to include(
          close_consent_date: session.close_consent_at.strftime("%A %-d %B")
        )
      end

      it { should include(location_name: session.location.name) }
      it { should include(team_email: session.team.email) }
      it { should include(team_phone: session.team.phone) }

      it "uses the consent url for the session" do
        expect(subject).to include(
          consent_link:
            start_session_parent_interface_consent_forms_url(session)
        )
      end
    end
  end

  describe "#reminder" do
    subject(:mail) do
      described_class.with(session:, patient:, parent:).reminder
    end

    let(:patient) { create(:patient) }
    let(:parent) { patient.parents.first }
    let(:session) { create(:session, patients: [patient]) }

    it { should have_attributes(to: [parent.email]) }

    describe "personalisation" do
      subject(:personalisation) do
        mail.message.header["personalisation"].unparsed_value
      end

      it { should include(session_date: session.date.strftime("%A %-d %B")) }

      it do
        expect(personalisation).to include(
          close_consent_date: session.close_consent_at.strftime("%A %-d %B")
        )
      end

      it do
        expect(personalisation).to include(
          close_consent_short_date: session.close_consent_at.strftime("%-d %B")
        )
      end

      it { should include(location_name: session.location.name) }
      it { should include(team_email: session.team.email) }
      it { should include(team_phone: session.team.phone) }

      it "uses the consent url for the session" do
        expect(personalisation).to include(
          consent_link:
            start_session_parent_interface_consent_forms_url(session)
        )
      end
    end
  end
end
