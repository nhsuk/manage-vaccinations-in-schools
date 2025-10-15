# frozen_string_literal: true

describe StatusGenerator::Vaccination do
  subject(:generator) do
    described_class.new(
      programme:,
      academic_year: AcademicYear.current,
      patient:,
      patient_locations:
        patient.patient_locations.includes(
          location: :location_programme_year_groups
        ),
      consents: patient.consents,
      triages: patient.triages,
      vaccination_records: patient.vaccination_records
    )
  end

  let(:patient) { create(:patient, date_of_birth: 15.years.ago.to_date) }
  let(:programme) { create(:programme) }

  describe "#status" do
    subject { generator.status }

    context "with no vaccination record" do
      it { should be(:none_yet) }
    end

    context "with a flu programme" do
      let(:programme) { create(:programme, :flu) }

      it { should be(:none_yet) }

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be(:none_yet) }
      end

      context "with an administered vaccination record" do
        before do
          create(:vaccination_record, :administered, patient:, programme:)
        end

        it { should be(:vaccinated) }
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

        it { should be(:vaccinated) }
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

        it { should be(:none_yet) }
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

        it { should be(:none_yet) }
      end
    end

    context "with an HPV programme" do
      let(:programme) { create(:programme, :hpv) }

      it { should be(:none_yet) }

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be(:none_yet) }
      end

      context "with an administered vaccination record" do
        before do
          create(:vaccination_record, :administered, patient:, programme:)
        end

        it { should be(:vaccinated) }
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

        it { should be(:vaccinated) }
      end
    end

    context "with a MenACWY programme" do
      let(:programme) { create(:programme, :menacwy) }

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be(:none_yet) }
      end

      context "with an administered vaccination record" do
        before do
          create(:vaccination_record, :administered, patient:, programme:)
        end

        it { should be(:vaccinated) }
      end

      context "with a second dose administered vaccination record" do
        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 2,
            patient:,
            programme:
          )
        end

        it { should be(:vaccinated) }
      end

      context "with an administered vaccination record when the patient was younger than 10 years old" do
        before do
          create(
            :vaccination_record,
            :administered,
            patient:,
            programme:,
            performed_at: 6.years.ago
          )
        end

        it { should be(:none_yet) }
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

        it { should be(:vaccinated) }
      end
    end

    context "with an Td/IPV programme" do
      let(:programme) { create(:programme, :td_ipv) }

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be(:none_yet) }
      end

      context "with a first dose administered vaccination record" do
        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 1,
            patient:,
            programme:
          )
        end

        it { should be(:none_yet) }
      end

      context "with a first dose administered vaccination record when the patient was younger than 10 years old" do
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

        it { should be(:none_yet) }
      end

      context "with a fifth dose administered vaccination record" do
        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 5,
            patient:,
            programme:
          )
        end

        it { should be(:vaccinated) }
      end

      context "with a fifth dose administered vaccination record when the patient was younger than 10 years old" do
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

        it { should be(:none_yet) }
      end

      context "with an unknown dose administered vaccination record" do
        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: nil,
            patient:,
            programme:
          )
        end

        it { should be(:none_yet) }
      end

      context "with an unknown dose administered vaccination record recorded in a session" do
        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: nil,
            patient:,
            programme:,
            session: create(:session, programmes: [programme])
          )
        end

        it { should be(:vaccinated) }
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

        it { should be(:vaccinated) }
      end
    end

    context "with a consent refused" do
      before { create(:consent, :refused, patient:, programme:) }

      it { should be(:could_not_vaccinate) }
    end

    context "with a conflicting consents" do
      before do
        create(:consent, :given, patient:, programme:)
        create(
          :consent,
          :refused,
          patient:,
          programme:,
          parent: create(:parent)
        )
      end

      it { should be(:could_not_vaccinate) }
    end

    context "with a triage as unsafe to vaccination" do
      before { create(:triage, :do_not_vaccinate, patient:, programme:) }

      it { should be(:could_not_vaccinate) }
    end

    context "with a discarded vaccination administered" do
      before { create(:vaccination_record, :discarded, patient:, programme:) }

      it { should be(:none_yet) }
    end
  end

  describe "#location_id" do
    subject { generator.location_id }

    context "with a flu programme" do
      let(:programme) { create(:programme, :flu) }

      it { should be_nil }

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be_nil }
      end

      context "with an administered vaccination record" do
        let(:location) { create(:school) }

        before do
          create(
            :vaccination_record,
            :administered,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
      end

      context "with an already had vaccination record" do
        let(:location) { create(:school) }

        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
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

        it { should be_nil }
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

        it { should be_nil }
      end
    end

    context "with an HPV programme" do
      let(:programme) { create(:programme, :hpv) }

      it { should be_nil }

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be_nil }
      end

      context "with an administered vaccination record" do
        let(:location) { create(:school) }

        before do
          create(
            :vaccination_record,
            :administered,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
      end

      context "with an already had vaccination record" do
        let(:location) { create(:school) }

        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
      end
    end

    context "with a MenACWY programme" do
      let(:programme) { create(:programme, :menacwy) }

      it { should be_nil }

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be_nil }
      end

      context "with an administered vaccination record" do
        let(:location) { create(:school) }

        before do
          create(
            :vaccination_record,
            :administered,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
      end

      context "with a second dose administered vaccination record" do
        let(:location) { create(:school) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 2,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
      end

      context "with an administered vaccination record when the patient was younger than 10 years old" do
        before do
          create(
            :vaccination_record,
            :administered,
            patient:,
            programme:,
            performed_at: 6.years.ago
          )
        end

        it { should be_nil }
      end

      context "with an already had vaccination record" do
        let(:location) { create(:school) }

        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
      end
    end

    context "with an Td/IPV programme" do
      let(:programme) { create(:programme, :td_ipv) }

      it { should be_nil }

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be_nil }
      end

      context "with a first dose administered vaccination record" do
        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 1,
            patient:,
            programme:
          )
        end

        it { should be_nil }
      end

      context "with a first dose administered vaccination record when the patient was younger than 10 years old" do
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

        it { should be_nil }
      end

      context "with a fifth dose administered vaccination record" do
        let(:location) { create(:school) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: 5,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
      end

      context "with a fifth dose administered vaccination record when the patient was younger than 10 years old" do
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

        it { should be_nil }
      end

      context "with an unknown dose administered vaccination record" do
        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: nil,
            patient:,
            programme:
          )
        end

        it { should be_nil }
      end

      context "with an unknown dose administered vaccination record recorded in a session" do
        let(:location) { create(:school, programmes: [programme]) }

        before do
          create(
            :vaccination_record,
            :administered,
            dose_sequence: nil,
            patient:,
            programme:,
            session: create(:session, location:, programmes: [programme])
          )
        end

        it { should be(location.id) }
      end

      context "with an already had vaccination record" do
        let(:location) { create(:school) }

        before do
          create(
            :vaccination_record,
            :not_administered,
            :already_had,
            patient:,
            programme:,
            location:
          )
        end

        it { should be(location.id) }
      end
    end
  end
end
