# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_triage_statuses
#
#  id               :bigint           not null, primary key
#  academic_year    :integer          not null
#  programme_type   :enum             not null
#  status           :integer          default("not_required"), not null
#  vaccine_method   :integer
#  without_gelatine :boolean
#  patient_id       :bigint           not null
#  programme_id     :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_programme_type_academic_year_b66791407e      (patient_id,programme_type,academic_year) UNIQUE
#  index_patient_triage_statuses_on_academic_year_and_patient_id  (academic_year,patient_id)
#  index_patient_triage_statuses_on_status                        (status)
#
# Foreign Keys
#
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
describe Patient::TriageStatus do
  subject(:patient_triage_status) do
    build(:patient_triage_status, patient:, programme:)
  end

  let(:patient) { create(:patient, year_group: 9) }
  let(:programme) { CachedProgramme.sample }

  before { patient.strict_loading!(false) }

  it { should belong_to(:patient) }
  it { should belong_to(:programme) }

  it do
    expect(patient_triage_status).to define_enum_for(:status).with_values(
      %i[
        not_required
        required
        safe_to_vaccinate
        do_not_vaccinate
        delay_vaccination
        invite_to_clinic
      ]
    )
  end

  describe "#status" do
    subject { patient_triage_status.tap(&:assign_status).status.to_sym }

    context "with no triage" do
      it { should be(:not_required) }
    end

    context "with conflicting consent" do
      before do
        create(:consent, :given, patient:, programme:)
        create(
          :consent,
          :refused,
          :needing_triage,
          patient:,
          programme:,
          parent: create(:parent)
        )
      end

      it { should be(:not_required) }
    end

    context "with two given consents with different methods" do
      before do
        create(
          :consent,
          :given,
          :needing_triage,
          patient:,
          programme:,
          vaccine_methods: %w[injection]
        )
        create(
          :consent,
          :given,
          :needing_triage,
          patient:,
          programme:,
          vaccine_methods: %w[nasal],
          parent: create(:parent)
        )
      end

      it { should be(:not_required) }
    end

    context "with a consent that needs triage" do
      before { create(:consent, :needing_triage, patient:, programme:) }

      it { should be(:required) }
    end

    context "with a historical vaccination that needs triage" do
      let(:programme) { CachedProgramme.td_ipv }

      before do
        create(:vaccination_record, patient:, programme:, dose_sequence: 1)
      end

      it { should be(:not_required) }

      context "when consent is given" do
        before { create(:consent, :given, patient:, programme:) }

        it { should be(:required) }
      end

      context "when consent is refused" do
        before { create(:consent, :refused, patient:, programme:) }

        it { should be(:not_required) }
      end
    end

    context "with a safe to vaccinate triage" do
      before { create(:triage, :safe_to_vaccinate, patient:, programme:) }

      it { should be(:safe_to_vaccinate) }
    end

    context "with a do not vaccinate triage" do
      before { create(:triage, :do_not_vaccinate, patient:, programme:) }

      it { should be(:do_not_vaccinate) }
    end

    context "with a needs follow up triage" do
      before { create(:triage, :keep_in_triage, patient:, programme:) }

      it { should be(:required) }
    end

    context "with a delay vaccination triage" do
      before { create(:triage, :delay_vaccination, patient:, programme:) }

      it { should be(:delay_vaccination) }
    end

    context "with an invalidated safe to vaccinate triage" do
      before do
        create(:triage, :safe_to_vaccinate, :invalidated, patient:, programme:)
      end

      it { should be(:not_required) }
    end

    context "when the patient is already vaccinated" do
      shared_examples "a vaccinated patient with any triage status" do
        before do
          create(:triage, triage_trait, patient:, programme:) if triage_trait
        end

        let(:programme) { CachedProgramme.hpv }

        it { should be(:not_required) }
      end

      before do
        create(:vaccination_record, patient:, programme:)
        create(:patient_vaccination_status, :vaccinated, patient:, programme:)
      end

      context "with a safe to vaccinate triage" do
        it_behaves_like "a vaccinated patient with any triage status" do
          let(:triage_trait) { :safe_to_vaccinate }
        end
      end

      context "with a do not vaccinate triage" do
        it_behaves_like "a vaccinated patient with any triage status" do
          let(:triage_trait) { :do_not_vaccinate }
        end
      end

      context "with a needs follow up triage" do
        it_behaves_like "a vaccinated patient with any triage status" do
          let(:triage_trait) { :keep_in_triage }
        end
      end

      context "with a delay vaccination triage" do
        it_behaves_like "a vaccinated patient with any triage status" do
          let(:triage_trait) { :delay_vaccination }
        end
      end
    end
  end

  describe "#vaccine_method" do
    subject { patient_triage_status.tap(&:assign_status).vaccine_method }

    context "with no triage" do
      it { should be_nil }
    end

    context "with a consent that needs triage" do
      before { create(:consent, :needing_triage, patient:, programme:) }

      it { should be_nil }
    end

    context "with a historical vaccination that needs triage" do
      let(:programme) { CachedProgramme.td_ipv }

      before do
        create(:vaccination_record, patient:, programme:, dose_sequence: 1)
      end

      it { should be_nil }

      context "when consent is given" do
        before { create(:consent, :given, patient:, programme:) }

        it { should be_nil }
      end

      context "when consent is refused" do
        before { create(:consent, :refused, patient:, programme:) }

        it { should be_nil }
      end
    end

    context "with a safe to vaccinate triage" do
      before { create(:triage, :safe_to_vaccinate, patient:, programme:) }

      it { should eq("injection") }
    end

    context "with a safe to vaccinate triage and vaccinated" do
      before do
        create(:triage, :safe_to_vaccinate, patient:, programme:)
        create(:vaccination_record, patient:, programme:)
      end

      let(:programme) { CachedProgramme.hpv }

      it { should be_nil }
    end

    context "with a do not vaccinate triage" do
      before { create(:triage, :do_not_vaccinate, patient:, programme:) }

      it { should be_nil }
    end

    context "with a needs follow up triage" do
      before { create(:triage, :keep_in_triage, patient:, programme:) }

      it { should be_nil }
    end

    context "with a delay vaccination triage" do
      before { create(:triage, :delay_vaccination, patient:, programme:) }

      it { should be_nil }
    end

    context "with an invalidated safe to vaccinate triage" do
      before do
        create(:triage, :safe_to_vaccinate, :invalidated, patient:, programme:)
      end

      it { should be_nil }
    end
  end

  describe "academic year filtering" do
    let(:current_academic_year) { AcademicYear.current }
    let(:previous_academic_year) { current_academic_year - 1 }
    let(:patient) { create(:patient) }
    let(:programme) { CachedProgramme.sample }

    describe "with triages from different academic years" do
      subject(:status) do
        patient_triage_status.tap(&:assign_status).status.to_sym
      end

      context "with a ready to vaccinate triage from the current academic year" do
        before do
          create(
            :triage,
            :safe_to_vaccinate,
            patient:,
            programme:,
            created_at: Date.new(current_academic_year, 10, 15).in_time_zone
          )
        end

        it { should be(:safe_to_vaccinate) }
      end

      context "with a ready to vaccinate triage from a previous academic year" do
        before do
          create(
            :triage,
            :safe_to_vaccinate,
            patient:,
            programme:,
            created_at: Date.new(previous_academic_year, 10, 15).in_time_zone
          )
        end

        it { should be(:not_required) }
      end

      context "with a ready to vaccinate and a do not vaccinate triage from the current and previous academic years" do
        before do
          create(
            :triage,
            :safe_to_vaccinate,
            patient:,
            programme:,
            created_at: Date.new(current_academic_year, 10, 15).in_time_zone
          )
          create(
            :triage,
            :do_not_vaccinate,
            patient:,
            programme:,
            created_at: Date.new(previous_academic_year, 10, 15).in_time_zone
          )
        end

        it { should be(:safe_to_vaccinate) }
      end

      context "with a do not vaccinate and ready to vaccinate triage from the current and previous academic years" do
        before do
          create(
            :triage,
            :do_not_vaccinate,
            patient:,
            programme:,
            created_at: Date.new(current_academic_year, 10, 15).in_time_zone
          )
          create(
            :triage,
            :safe_to_vaccinate,
            patient:,
            programme:,
            created_at: Date.new(previous_academic_year, 10, 15).in_time_zone
          )
        end

        it { should be(:do_not_vaccinate) }
      end
    end
  end
end
