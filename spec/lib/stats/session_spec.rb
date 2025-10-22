# frozen_string_literal: true

describe Stats::Session do
  describe ".call" do
    subject(:stats) { described_class.call(session:, programme:) }

    let(:programme) { create(:programme, :hpv) }
    let(:session) { create(:session, programmes: [programme]) }

    context "with no patients" do
      it "returns zero counts for all stats" do
        expect(stats).to eq(
          eligible_children: 0,
          no_response: 0,
          consent_given: 0,
          did_not_consent: 0,
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
          create(:patient_vaccination_status, :vaccinated, patient:, programme:)
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
          no_response: 1,
          consent_given: 1,
          did_not_consent: 2,
          vaccinated: 1
        )
      end
    end

    context "with flu programme (multiple vaccine methods)" do
      let(:programme) { create(:programme, :flu) }
      let(:session) { create(:session, programmes: [programme]) }

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
            :given_injection_only,
            patient:,
            programme:
          )
        end
      end

      it "returns counts broken down by vaccine method" do
        expect(stats).to include(
          eligible_children: 2,
          consent_given_nasal: 1,
          consent_given_injection: 1
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
  end
end
