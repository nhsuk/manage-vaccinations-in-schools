# frozen_string_literal: true

describe VaccinationCriteria do
  subject(:vaccination_criteria) do
    described_class.new(
      programme_type: programme.type,
      academic_year: AcademicYear.current,
      patient:,
      vaccination_records: patient.vaccination_records.order_by_performed_at
    )
  end

  let(:patient) { create(:patient) }
  let(:programme) { Programme.sample }
  let(:session) { create(:session, programmes: [programme]) }

  describe "#vaccinated?" do
    subject { vaccination_criteria.vaccinated? }

    context "with no vaccination record" do
      it { should be(false) }
    end

    context "with a flu programme" do
      let(:programme) { Programme.flu }

      context "when eligible" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) { create(:patient, session:) }

        it { should be(false) }
      end

      context "when eligible and has consent" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        it { should be(false) }
      end

      context "when eligible and safe to vaccinate" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_safe_to_vaccinate, session:)
        end

        it { should be(false) }
      end

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be(false) }
      end

      context "with an administered vaccination record" do
        before do
          create(:vaccination_record, :administered, patient:, programme:)
        end

        it { should be(true) }
      end

      context "with an already had vaccination record" do
        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:
          )
        end

        it { should be(true) }
      end

      context "with an administered vaccination record from last year" do
        before do
          create(
            :vaccination_record,
            :administered,
            patient:,
            programme:,
            performed_at: 1.year.ago
          )
        end

        it { should be(false) }
      end

      context "with an already had vaccination record from last year" do
        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:,
            performed_at: 1.year.ago
          )
        end

        it { should be(false) }
      end
    end

    context "with an HPV programme" do
      let(:programme) { Programme.hpv }

      context "when eligible" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) { create(:patient, session:) }

        it { should be(false) }
      end

      context "when eligible and has consent" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        it { should be(false) }
      end

      context "when eligible and safe to vaccinate" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_safe_to_vaccinate, session:)
        end

        it { should be(false) }
      end

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be(false) }
      end

      context "with an administered vaccination record" do
        before do
          create(:vaccination_record, :administered, patient:, programme:)
        end

        it { should be(true) }
      end

      context "with an already had vaccination record" do
        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:
          )
        end

        it { should be(true) }
      end
    end

    context "with a MenACWY programme" do
      let(:programme) { Programme.menacwy }

      context "when eligible" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) { create(:patient, session:) }

        it { should be(false) }
      end

      context "when eligible and has consent" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        it { should be(false) }
      end

      context "when eligible and safe to vaccinate" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_safe_to_vaccinate, session:)
        end

        it { should be(false) }
      end

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be(false) }
      end

      context "with an administered vaccination record" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(:vaccination_record, :administered, patient:, programme:)
        end

        it { should be(true) }
      end

      context "with a second dose administered vaccination record" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 2,
            patient:,
            programme:
          )
        end

        it { should be(true) }
      end

      context "with an administered vaccination record when the patient was younger than 10 years old" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            patient:,
            programme:,
            performed_at: 6.years.ago
          )
        end

        it { should be(false) }
      end

      context "with an already had vaccination record" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:
          )
        end

        it { should be(true) }
      end
    end

    context "with an MMR programme" do
      let(:programme) { Programme.mmr }

      context "when eligible" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) { create(:patient, session:) }

        it { should be(false) }
      end

      context "when eligible and has consent" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        it { should be(false) }
      end

      context "when first dose is not valid" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        before do
          create(
            :vaccination_record,
            patient:,
            programme:,
            performed_at: patient.date_of_birth + 1.day
          )

          create(
            :vaccination_record,
            patient:,
            programme:,
            performed_at: patient.date_of_birth + 1.year
          )
        end

        it { should be(false) }
      end

      context "with a valid first dose" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        before do
          create(
            :vaccination_record,
            patient:,
            programme:,
            performed_at: patient.date_of_birth + 1.year
          )

          create(:triage, :delay_vaccination, patient:, programme:)
        end

        it { should be(false) }

        context "and then triaged as safe to vaccinate" do
          before { create(:triage, :safe_to_vaccinate, patient:, programme:) }

          it { should be(false) }

          context "and a valid second dose" do
            before do
              create(
                :vaccination_record,
                patient:,
                programme:,
                performed_at:
                  (patient.date_of_birth + 1.year + 3.months).then do
                    # When date is at the end of the month, adding months to it
                    # results in dates that are also at the end of the month,
                    # which can cause test failures. For example if dob is
                    # 2021-01-31, then 1 year + 3 months is 2022-04-30, but when
                    # AgeConcern#age_months calculates age, the result is 14
                    # months, triggering a false negative in our test here.
                    it == it.end_of_month ? it + 1.day : it
                  end
              )
            end

            it { should be(true) }
          end
        end
      end

      context "with two doses with 28 days between each one" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        before do
          create(
            :vaccination_record,
            patient:,
            programme:,
            performed_at: patient.date_of_birth + 2.years
          )
          create(
            :vaccination_record,
            patient:,
            programme:,
            performed_at: patient.date_of_birth + 2.years + 28.days
          )
        end

        it { should be(true) }
      end

      context "with two date-only doses 28 days apart and duplicate records with times" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        let(:first_dose_date) { patient.date_of_birth + 2.years }
        let(:second_dose_date) { first_dose_date + 28.days }

        before do
          # Historical upload records (date only, no time)
          create(
            :vaccination_record,
            patient:,
            programme:,
            performed_at_date: first_dose_date,
            performed_at_time: nil,
            source: "historical_upload"
          )
          create(
            :vaccination_record,
            patient:,
            programme:,
            performed_at_date: second_dose_date,
            performed_at_time: nil,
            source: "historical_upload"
          )
          # NHS Imms API records (same dates but with times)
          create(
            :vaccination_record,
            :sourced_from_nhs_immunisations_api,
            patient:,
            programme:,
            performed_at: Time.zone.parse("#{first_dose_date} 16:09:17")
          )
          create(
            :vaccination_record,
            :sourced_from_nhs_immunisations_api,
            patient:,
            programme:,
            performed_at: Time.zone.parse("#{second_dose_date} 16:37:49")
          )
        end

        it { should be(true) }
      end

      context "with two doses with 27 days between each one" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        before do
          create(
            :vaccination_record,
            patient:,
            programme:,
            performed_at: patient.date_of_birth + 2.years
          )
          create(
            :vaccination_record,
            patient:,
            programme:,
            performed_at: patient.date_of_birth + 2.years + 27.days
          )
        end

        it { should be(false) }
      end

      context "with three doses where the second is too early and the third is 28 days after the first" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        before do
          create(
            :vaccination_record,
            patient:,
            programme:,
            performed_at: patient.date_of_birth + 2.years
          )
          # Invalid dose (too early)
          create(
            :vaccination_record,
            patient:,
            programme:,
            performed_at: patient.date_of_birth + 2.years + 20.days
          )
          create(
            :vaccination_record,
            patient:,
            programme:,
            performed_at: patient.date_of_birth + 2.years + 28.days
          )
        end

        it { should be(false) }
      end
    end

    context "with a Td/IPV programme" do
      let(:programme) { Programme.td_ipv }

      context "when eligible" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) { create(:patient, session:) }

        it { should be(false) }
      end

      context "when eligible and has consent" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_not_needed, session:)
        end

        it { should be(false) }
      end

      context "when eligible and safe to vaccinate" do
        let(:session) { create(:session, programmes: [programme]) }
        let(:patient) do
          create(:patient, :consent_given_triage_safe_to_vaccinate, session:)
        end

        it { should be(false) }
      end

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be(false) }
      end

      context "with a first dose administered vaccination record" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 1,
            patient:,
            programme:
          )
        end

        it { should be(false) }
      end

      context "with a first dose administered vaccination record when the patient was younger than 10 years old" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 1,
            patient:,
            programme:,
            performed_at: 6.years.ago
          )
        end

        it { should be(false) }
      end

      context "with a fifth dose administered vaccination record" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 5,
            patient:,
            programme:
          )
        end

        it { should be(true) }
      end

      context "with a fifth dose administered vaccination record when the patient was younger than 10 years old" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 5,
            patient:,
            programme:,
            performed_at: 6.years.ago
          )
        end

        it { should be(false) }
      end

      context "with an unknown dose administered vaccination record" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: nil,
            patient:,
            programme:
          )
        end

        it { should be(false) }
      end

      context "with a dose 3 administered vaccination record recorded in a session" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 3,
            patient:,
            programme:,
            session: create(:session, programmes: [programme])
          )
        end

        it { should be(true) }
      end

      context "with a dose 5 administered vaccination record recorded in a session" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 5,
            patient:,
            programme:,
            session: create(:session, programmes: [programme])
          )
        end

        it { should be(true) }
      end

      context "with an already had vaccination record" do
        let(:patient) { create(:patient, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:
          )
        end

        it { should be(true) }
      end
    end

    context "with a discarded vaccination administered" do
      before { create(:vaccination_record, :discarded, patient:, programme:) }

      it { should be(false) }
    end
  end
end
