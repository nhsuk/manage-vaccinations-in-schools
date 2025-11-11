# frozen_string_literal: true

describe Stats::Session do
  describe "#call" do
    subject(:stats) { described_class.call(session, programme:) }

    let(:programme) { CachedProgramme.hpv }
    let(:session) { create(:session, programmes: [programme]) }
    let(:latest_location) { session.location }

    context "with no patients" do
      it "returns zero counts for all stats" do
        expect(stats).to eq(
          eligible_children: 0,
          consent_no_response: 0,
          consent_given_injection: 0,
          consent_refused: 0,
          vaccinated: 0
        )
      end
    end

    context "with patients in various states" do
      before do
        create(:patient, session:, year_group: 9).tap do |patient|
          create(:patient_consent_status, :no_response, patient:, programme:)
        end

        create(:patient, session:, year_group: 9).tap do |patient|
          create(:patient_consent_status, :given, patient:, programme:)
        end

        create(:patient, session:, year_group: 9).tap do |patient|
          create(
            :patient_vaccination_status,
            :vaccinated,
            patient:,
            programme:,
            latest_location:
          )
        end

        create(:patient, session:, year_group: 9).tap do |patient|
          create(:patient_consent_status, :refused, patient:, programme:)
        end

        create(:patient, session:, year_group: 9).tap do |patient|
          create(:patient_consent_status, :conflicts, patient:, programme:)
        end
      end

      it "returns correct counts for each category" do
        expect(stats).to eq(
          eligible_children: 5,
          consent_no_response: 1,
          consent_given_injection: 1,
          consent_refused: 2,
          vaccinated: 1
        )
      end
    end

    context "with a patient not suitable for the programme" do
      let(:hpv_programme) { CachedProgramme.hpv }
      let(:menacwy_programme) { CachedProgramme.menacwy }
      let(:programme) { menacwy_programme }
      let(:session) do
        create(:session, programmes: [hpv_programme, menacwy_programme])
      end

      before do
        create(:patient, session:, year_group: 8).tap do |patient|
          create(:patient_consent_status, :no_response, patient:, programme:)
        end
      end

      it "returns correct counts for each category" do
        expect(stats).to eq(
          eligible_children: 0,
          consent_no_response: 0,
          consent_given_injection: 0,
          consent_refused: 0,
          vaccinated: 0
        )
      end
    end

    context "with flu programme (multiple vaccine methods)" do
      let(:programme) { CachedProgramme.flu }

      before do
        create(:patient, session:, year_group: 9).tap do |patient|
          create(
            :patient_consent_status,
            :given_nasal_only,
            patient:,
            programme:
          )
        end

        create(:patient, session:, year_group: 9).tap do |patient|
          create(
            :patient_consent_status,
            :given_without_gelatine,
            patient:,
            programme:
          )
        end

        create(:patient, session:, year_group: 9).tap do |patient|
          create(
            :patient_consent_status,
            :given_without_gelatine,
            patient:,
            programme:
          )
        end
      end

      it "returns counts broken down by vaccine method" do
        expect(stats).to include(
          eligible_children: 3,
          consent_given_nasal: 1,
          consent_given_injection_without_gelatine: 2
        )
      end
    end

    context "when patient is deceased" do
      let(:patient) { create(:patient, :deceased, session:, year_group: 9) }

      before do
        create(
          :patient_consent_status,
          :given_injection_only,
          patient:,
          programme:
        )
      end

      it "doesn't include them in eligible children" do
        expect(stats).to include(eligible_children: 0)
      end
    end

    context "patient is vaccinated but the location is unknown" do
      before do
        create(:patient, session:, year_group: 9).tap do |patient|
          create(
            :patient_vaccination_status,
            :vaccinated,
            patient:,
            programme:,
            latest_location: nil
          )
        end
      end

      it "doesn't count the vaccination" do
        expect(stats).to include(vaccinated: 0)
      end
    end
  end
end
