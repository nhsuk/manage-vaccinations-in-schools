# frozen_string_literal: true

describe ConsentMailer do
  describe "#confirmation_injection" do
    subject(:mail) do
      described_class.with(consent_form:).confirmation_injection
    end

    let(:programme) { create(:programme, :flu) }
    let(:consent_form) do
      create(
        :consent_form,
        :recorded,
        :refused,
        reason: :contains_gelatine,
        programme:,
        session: create(:session, programme:)
      )
    end

    it "calls template_mail with correct reason_for_refusal" do
      expect(mail.message.header["personalisation"].unparsed_value).to include(
        reason_for_refusal: "of the gelatine in the nasal spray"
      )
    end
  end

  describe "#request" do
    subject(:mail) do
      described_class.with(session:, patient:, parent:, programme:).request
    end

    let(:patient) { create(:patient) }
    let(:parent) { patient.parents.first }
    let(:programme) { create(:programme) }
    let(:date) { Date.current }
    let(:session) { create(:session, date:, patients: [patient], programme:) }

    it { should have_attributes(to: [parent.email]) }

    describe "personalisation" do
      subject(:personalisation) do
        mail.message.header["personalisation"].unparsed_value
      end

      it { should include(next_session_date: date.strftime("%A %-d %B")) }

      it do
        expect(personalisation).to include(
          close_consent_date: session.close_consent_at.strftime("%A %-d %B")
        )
      end

      it { should include(location_name: session.location.name) }
      it { should include(team_email: session.team.email) }
      it { should include(team_phone: session.team.phone) }

      it "uses the consent url for the session" do
        expect(personalisation).to include(
          consent_link:
            start_parent_interface_consent_forms_url(session, programme)
        )
      end
    end
  end

  describe "#reminder" do
    subject(:mail) do
      described_class.with(session:, patient:, parent:, programme:).reminder
    end

    let(:patient) { create(:patient) }
    let(:parent) { patient.parents.first }
    let(:programme) { create(:programme) }
    let(:date) { Date.current }
    let(:session) { create(:session, date:, patients: [patient], programme:) }

    it { should have_attributes(to: [parent.email]) }

    describe "personalisation" do
      subject(:personalisation) do
        mail.message.header["personalisation"].unparsed_value
      end

      it { should include(next_session_date: date.strftime("%A %-d %B")) }

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
            start_parent_interface_consent_forms_url(session, programme)
        )
      end
    end
  end
end
