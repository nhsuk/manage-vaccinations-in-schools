# frozen_string_literal: true

describe SessionMailer do
  describe "#school_reminder" do
    subject(:mail) do
      described_class.with(
        programme:,
        session:,
        patient:,
        parent:
      ).school_reminder
    end

    let(:programme) { create(:programme) }
    let(:parent) { create(:parent) }
    let(:patient) do
      create(:patient, preferred_given_name: "Joey", parents: [parent])
    end
    let(:session) { create(:session, programme:, patients: [patient]) }

    it { should have_attributes(to: [parent.email]) }

    describe "personalisation" do
      subject(:personalisation) do
        mail.message.header["personalisation"].unparsed_value
      end

      it "sets the personalisation" do
        expect(personalisation.keys).to include(
          :full_and_preferred_patient_name,
          :location_name,
          :next_session_date,
          :next_session_dates,
          :next_session_dates_or,
          :short_patient_name,
          :short_patient_name_apos,
          :subsequent_session_dates_offered_message,
          :team_email,
          :team_name,
          :team_phone,
          :vaccination
        )
      end
    end
  end

  describe "#clinic_initial_invitation" do
    subject(:mail) do
      described_class.with(patient_session:, parent:).clinic_initial_invitation
    end

    let(:programme) { create(:programme) }
    let(:organisation) { create(:organisation, programmes: [programme]) }
    let(:team) do
      create(
        :team,
        name: "SAIS organisation",
        email: "sais@example.com",
        phone: "07987 654321",
        organisation:
      )
    end
    let(:parent) { create(:parent) }
    let(:patient) do
      create(
        :patient,
        given_name: "John",
        family_name: "Smith",
        preferred_given_name: "Joey",
        parents: [parent]
      )
    end
    let(:session) { create(:session, organisation:, programme:, team:) }
    let(:patient_session) { create(:patient_session, patient:, session:) }

    it { should have_attributes(to: [parent.email]) }

    describe "personalisation" do
      subject(:personalisation) do
        mail.message.header["personalisation"].unparsed_value
      end

      it do
        expect(personalisation).to include(
          full_and_preferred_patient_name: "John Smith (known as Joey Smith)"
        )
      end

      it { should include(team_name: "SAIS organisation") }
      it { should include(team_email: "sais@example.com") }
      it { should include(team_phone: "07987 654321") }
    end
  end

  describe "#clinic_subsequent_invitation" do
    subject(:mail) do
      described_class.with(
        patient_session:,
        parent:
      ).clinic_subsequent_invitation
    end

    let(:programme) { create(:programme) }
    let(:organisation) { create(:organisation, programmes: [programme]) }
    let(:team) do
      create(
        :team,
        name: "SAIS organisation",
        email: "sais@example.com",
        phone: "07987 654321",
        organisation:
      )
    end
    let(:parent) { create(:parent) }
    let(:patient) do
      create(
        :patient,
        given_name: "John",
        family_name: "Smith",
        preferred_given_name: "Joey",
        parents: [parent]
      )
    end
    let(:session) { create(:session, organisation:, programme:, team:) }
    let(:patient_session) { create(:patient_session, patient:, session:) }

    it { should have_attributes(to: [parent.email]) }

    describe "personalisation" do
      subject(:personalisation) do
        mail.message.header["personalisation"].unparsed_value
      end

      it do
        expect(personalisation).to include(
          full_and_preferred_patient_name: "John Smith (known as Joey Smith)"
        )
      end

      it { should include(team_name: "SAIS organisation") }
      it { should include(team_email: "sais@example.com") }
      it { should include(team_phone: "07987 654321") }
    end
  end
end
