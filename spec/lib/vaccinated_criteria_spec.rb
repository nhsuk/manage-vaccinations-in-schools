# frozen_string_literal: true

describe VaccinatedCriteria do
  subject(:vaccinated_criteria) { described_class.new(patients: Patient.all) }

  describe "#vaccinated?" do
    subject { vaccinated_criteria.vaccinated?(patient, programme:) }

    let(:patient) { create(:patient, date_of_birth: 15.years.ago.to_date) }
    let(:vaccination_records) { [] }

    context "with a Flu programme" do
      let(:programme) { create(:programme, :flu) }

      it { should be(false) }

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

    context "with an HPV programme" do
      let(:programme) { create(:programme, :hpv) }

      it { should be(false) }

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
      let(:programme) { create(:programme, :menacwy) }

      it { should be(false) }

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

        it { should be(true) }
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

        it { should be(false) }
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

    context "with an Td/IPV programme" do
      let(:programme) { create(:programme, :td_ipv) }

      it { should be(false) }

      context "with an unadministered vaccination record" do
        before do
          create(:vaccination_record, :not_administered, patient:, programme:)
        end

        it { should be(false) }
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

        it { should be(false) }
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

        it { should be(false) }
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

        it { should be(true) }
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

        it { should be(false) }
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

        it { should be(false) }
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
  end
end
