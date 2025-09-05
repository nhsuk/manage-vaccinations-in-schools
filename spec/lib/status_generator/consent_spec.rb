# frozen_string_literal: true

describe StatusGenerator::Consent do
  subject(:generator) do
    described_class.new(
      programme:,
      academic_year: AcademicYear.current,
      patient:,
      consents: patient.consents,
      vaccination_records: patient.vaccination_records
    )
  end

  let(:patient) { create(:patient) }
  let(:programme) { create(:programme) }

  describe "#status" do
    subject { generator.status }

    context "with no consent" do
      it { should be(:no_response) }
    end

    context "with an invalidated consent" do
      before { create(:consent, :invalidated, patient:, programme:) }

      it { should be(:no_response) }
    end

    context "with a not provided consent" do
      before { create(:consent, :not_provided, patient:, programme:) }

      it { should be(:no_response) }
    end

    context "with both an invalidated and not provided consent" do
      before do
        create(:consent, :invalidated, patient:, programme:)
        create(:consent, :not_provided, patient:, programme:)
      end

      it { should be(:no_response) }
    end

    context "with a refused consent" do
      before { create(:consent, :refused, patient:, programme:) }

      it { should be(:refused) }
    end

    context "with a given consent" do
      before { create(:consent, :given, patient:, programme:) }

      it { should be(:given) }
    end

    context "with conflicting consent" do
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

      it { should be(:conflicts) }
    end

    context "with two given consents with different methods" do
      before do
        create(
          :consent,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[injection]
        )
        create(
          :consent,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[nasal],
          parent: create(:parent)
        )
      end

      it { should be(:conflicts) }
    end

    context "with two given consents, one both and one with injection only" do
      before do
        create(
          :consent,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[injection]
        )
        create(
          :consent,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[nasal injection],
          parent: create(:parent)
        )
      end

      it { should be(:given) }
    end

    context "with an invalidated refused and given consent" do
      before do
        create(:consent, :refused, :invalidated, patient:, programme:)
        create(:consent, :given, patient:, programme:)
      end

      it { should be(:given) }
    end

    context "with a refused and given consent from the same parent at different times" do
      before do
        create(
          :consent,
          :refused,
          patient:,
          programme:,
          academic_year: AcademicYear.current,
          created_at: 1.day.ago,
          submitted_at: 2.days.ago
        )
        create(
          :consent,
          :given,
          patient:,
          programme:,
          academic_year: AcademicYear.current,
          created_at: 2.days.ago,
          submitted_at: 1.day.ago
        )
      end

      it { should be(:given) }
    end

    context "with self-consent" do
      before { create(:consent, :self_consent, :given, patient:, programme:) }

      it { should be(:given) }

      context "and refused parental consent" do
        before { create(:consent, :refused, patient:, programme:) }

        it { should be(:given) }
      end

      context "and conflicting parental consent" do
        before do
          create(:consent, :refused, patient:, programme:)
          create(
            :consent,
            :given,
            patient:,
            programme:,
            parent: create(:parent)
          )
        end

        it { should be(:given) }
      end
    end

    describe "academic year filtering" do
      let(:current_academic_year) { AcademicYear.current }
      let(:previous_academic_year) { current_academic_year - 1 }
      let(:patient) { create(:patient) }
      let(:programme) { create(:programme) }
      let(:parent) { create(:parent) }

      context "with a given consent from the current academic year" do
        before do
          create(
            :consent,
            :given,
            patient: patient,
            programme: programme,
            parent: parent,
            submitted_at: Date.new(current_academic_year, 10, 15).in_time_zone
          )
        end

        it { should be(:given) }
      end

      context "with a given consent from a previous academic year" do
        before do
          create(
            :consent,
            :given,
            patient: patient,
            programme: programme,
            parent: parent,
            submitted_at: Date.new(previous_academic_year, 10, 15).in_time_zone
          )
        end

        it { should be(:no_response) }
      end

      context "with a given and refused consent from current and previous academic years" do
        before do
          create(
            :consent,
            :given,
            patient: patient,
            programme: programme,
            parent: parent,
            submitted_at: Date.new(current_academic_year, 10, 15).in_time_zone
          )
          create(
            :consent,
            :refused,
            patient: patient,
            programme: programme,
            parent: create(:parent),
            submitted_at: Date.new(previous_academic_year, 10, 15).in_time_zone
          )
        end

        it { should be(:given) }
      end

      context "with a refused and given consent from the current and previous academic years" do
        before do
          create(
            :consent,
            :refused,
            patient: patient,
            programme: programme,
            parent: parent,
            submitted_at: Date.new(current_academic_year, 10, 15).in_time_zone
          )
          create(
            :consent,
            :given,
            patient: patient,
            programme: programme,
            parent: create(:parent),
            submitted_at: Date.new(previous_academic_year, 10, 15).in_time_zone
          )
        end

        it { should be(:refused) }
      end
    end
  end

  describe "#vaccine_methods" do
    subject { generator.vaccine_methods }

    context "with no consent" do
      it { should be_empty }
    end

    context "with an invalidated consent" do
      before { create(:consent, :invalidated, patient:, programme:) }

      it { should be_empty }
    end

    context "with a not provided consent" do
      before { create(:consent, :not_provided, patient:, programme:) }

      it { should be_empty }
    end

    context "with both an invalidated and not provided consent" do
      before do
        create(:consent, :invalidated, patient:, programme:)
        create(:consent, :not_provided, patient:, programme:)
      end

      it { should be_empty }
    end

    context "with a refused consent" do
      before { create(:consent, :refused, patient:, programme:) }

      it { should be_empty }
    end

    context "with an injection given consent" do
      before do
        create(
          :consent,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[injection]
        )
      end

      it { should contain_exactly("injection") }
    end

    context "with a nasal given consent" do
      before do
        create(
          :consent,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[nasal]
        )
      end

      it { should contain_exactly("nasal") }
    end

    context "with both nasal and injection given consent" do
      before do
        create(
          :consent,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[nasal injection]
        )
      end

      it { should eq(%w[nasal injection]) }
    end

    context "with one parent nasal and one parent both" do
      before do
        create(
          :consent,
          :given,
          patient:,
          programme:,
          vaccine_methods: %w[nasal]
        )
        create(
          :consent,
          :given,
          patient:,
          programme:,
          parent: create(:parent),
          vaccine_methods: %w[nasal injection]
        )
      end

      it { should contain_exactly("nasal") }
    end

    context "with conflicting consent" do
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

      it { should be_empty }
    end

    context "with an invalidated refused and given consent" do
      before do
        create(:consent, :refused, :invalidated, patient:, programme:)
        create(:consent, :given, patient:, programme:)
      end

      it { should contain_exactly("injection") }
    end

    context "with self-consent" do
      before { create(:consent, :self_consent, :given, patient:, programme:) }

      it { should contain_exactly("injection") }

      context "and refused parental consent" do
        before { create(:consent, :refused, patient:, programme:) }

        it { should contain_exactly("injection") }
      end

      context "and conflicting parental consent" do
        before do
          create(:consent, :refused, patient:, programme:)
          create(
            :consent,
            :given,
            patient:,
            programme:,
            parent: create(:parent)
          )
        end

        it { should contain_exactly("injection") }
      end
    end
  end
end
