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

  describe "#school_request" do
    subject(:mail) do
      described_class.with(
        session:,
        patient:,
        parent:,
        programme:
      ).school_request
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

      let(:consent_deadline) { (date - 1.day).strftime("%A %-d %B") }
      let(:consent_link) do
        start_parent_interface_consent_forms_url(session, programme)
      end

      it { should include(consent_deadline:) }
      it { should include(consent_link:) }
      it { should include(full_and_preferred_patient_name: patient.full_name) }
      it { should include(location_name: session.location.name) }
      it { should include(next_session_date: date.strftime("%A %-d %B")) }
      it { should include(organisation_email: session.organisation.email) }
      it { should include(organisation_phone: session.organisation.phone) }
    end
  end

  describe "#clinic_request" do
    subject(:mail) do
      described_class.with(
        session:,
        patient:,
        parent:,
        programme:
      ).clinic_request
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

      let(:consent_link) do
        start_parent_interface_consent_forms_url(session, programme)
      end

      it { should include(consent_link:) }
      it { should include(full_and_preferred_patient_name: patient.full_name) }
      it { should include(organisation_email: session.organisation.email) }
      it { should include(organisation_phone: session.organisation.phone) }
    end
  end

  describe "#school_initial_reminder" do
    subject(:mail) do
      described_class.with(
        session:,
        patient:,
        parent:,
        programme:
      ).school_initial_reminder
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
      it { should include(location_name: session.location.name) }
      it { should include(organisation_email: session.organisation.email) }
      it { should include(organisation_phone: session.organisation.phone) }

      it "includes consent details" do
        expect(personalisation).to include(
          consent_deadline: (date - 1.day).strftime("%A %-d %B"),
          consent_link:
            start_parent_interface_consent_forms_url(session, programme)
        )
      end
    end
  end

  describe "#school_subsequent_reminder" do
    subject(:mail) do
      described_class.with(
        session:,
        patient:,
        parent:,
        programme:
      ).school_subsequent_reminder
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
      it { should include(location_name: session.location.name) }
      it { should include(organisation_email: session.organisation.email) }
      it { should include(organisation_phone: session.organisation.phone) }

      it "includes consent details" do
        expect(personalisation).to include(
          consent_deadline: (date - 1.day).strftime("%A %-d %B"),
          consent_link:
            start_parent_interface_consent_forms_url(session, programme)
        )
      end
    end
  end
end
