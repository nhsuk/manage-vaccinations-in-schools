# frozen_string_literal: true

describe VaccinationMailer do
  let(:programme) { create(:programme) }
  let(:session) { create(:session, programme:) }
  let(:consent) { patient.consents.last }
  let(:parent) { consent.parent }

  describe "#confirmation_administered" do
    subject(:mail) do
      described_class.with(
        consent:,
        vaccination_record:
      ).confirmation_administered
    end

    let(:patient) do
      create(:patient, :consent_given_triage_not_needed, programme:)
    end
    let(:patient_session) { create(:patient_session, patient:, session:) }
    let(:vaccination_record) do
      create(:vaccination_record, programme:, patient_session:)
    end

    it do
      expect(mail).to have_attributes(
        to: [parent.email],
        template_id:
          GOVUK_NOTIFY_EMAIL_TEMPLATES.fetch(
            :vaccination_confirmation_administered
          )
      )
    end

    describe "personalisation" do
      subject(:personalisation) do
        mail.message.header["personalisation"].unparsed_value
      end

      it "sets the personalisation" do
        expect(personalisation.keys).to include(
          :batch_name,
          :day_month_year_of_vaccination,
          :full_and_preferred_patient_name,
          :location_name,
          :parent_full_name,
          :team_email,
          :team_name,
          :team_phone,
          :today_or_date_of_vaccination
        )
      end

      it "sets the correct batch number" do
        expect(personalisation).to include(
          batch_name: vaccination_record.batch.name
        )
      end

      it "sets the day month and year of vaccination" do
        expect(personalisation).to include(
          day_month_year_of_vaccination:
            vaccination_record.administered_at.strftime("%d/%m/%Y")
        )
      end

      describe "today_or_date_of_vaccination field" do
        subject { personalisation[:today_or_date_of_vaccination] }

        let(:vaccination_record) do
          create(:vaccination_record, programme:, patient_session:, created_at:)
        end

        context "when the vaccination was created today" do
          let(:created_at) { Time.zone.today }

          it { should eq("today") }
        end

        context "when the vaccination was create 2 days ago" do
          let(:created_at) { Date.new(2023, 3, 1) }

          it { should eq("1 March 2023") }
        end
      end
    end
  end

  describe "#confirmation_not_administered" do
    subject(:mail) do
      described_class.with(
        consent:,
        vaccination_record:
      ).confirmation_not_administered
    end

    let(:patient) do
      create(:patient, :consent_given_triage_not_needed, programme:)
    end
    let(:patient_session) { create(:patient_session, session:, patient:) }
    let(:vaccination_record) do
      create(
        :vaccination_record,
        :not_administered,
        programme:,
        patient_session:
      )
    end

    it do
      expect(mail).to have_attributes(
        to: [parent.email],
        template_id:
          GOVUK_NOTIFY_EMAIL_TEMPLATES.fetch(
            :vaccination_confirmation_not_administered
          )
      )
    end

    describe "personalisation" do
      subject(:personalisation) do
        mail.message.header["personalisation"].unparsed_value
      end

      it "sets the personalisation" do
        expect(personalisation.keys).to include(
          :full_and_preferred_patient_name,
          :parent_full_name,
          :reason_did_not_vaccinate,
          :short_patient_name,
          :show_additional_instructions,
          :team_email,
          :team_name,
          :team_phone
        )
      end
    end
  end
end
