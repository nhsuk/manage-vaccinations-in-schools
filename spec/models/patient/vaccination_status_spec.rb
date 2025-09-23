# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_vaccination_statuses
#
#  id                    :bigint           not null, primary key
#  academic_year         :integer          not null
#  latest_session_status :integer          default("none_yet"), not null
#  status                :integer          default("none_yet"), not null
#  status_changed_at     :datetime         not null
#  latest_location_id    :bigint
#  patient_id            :bigint           not null
#  programme_id          :bigint           not null
#
# Indexes
#
#  idx_on_patient_id_programme_id_academic_year_fc0b47b743   (patient_id,programme_id,academic_year) UNIQUE
#  index_patient_vaccination_statuses_on_latest_location_id  (latest_location_id)
#  index_patient_vaccination_statuses_on_status              (status)
#
# Foreign Keys
#
#  fk_rails_...  (latest_location_id => locations.id)
#  fk_rails_...  (patient_id => patients.id) ON DELETE => cascade
#  fk_rails_...  (programme_id => programmes.id)
#
describe Patient::VaccinationStatus do
  subject(:patient_vaccination_status) do
    build(:patient_vaccination_status, patient:, programme:)
  end

  let(:patient) { create(:patient, programmes: [programme]) }
  let(:programme) { create(:programme) }

  it { should belong_to(:patient) }
  it { should belong_to(:programme) }

  it do
    expect(patient_vaccination_status).to define_enum_for(:status).with_values(
      %i[none_yet vaccinated could_not_vaccinate]
    )
  end

  describe "#status" do
    subject { patient_vaccination_status.tap(&:assign_status).status.to_sym }

    before { patient.strict_loading!(false) }

    context "with no vaccination record" do
      it { should be(:none_yet) }
    end

    context "with a vaccination administered" do
      before { create(:vaccination_record, patient:, programme:) }

      it { should be(:vaccinated) }
    end

    context "with a vaccination already had" do
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

    context "with a vaccination not administered" do
      before do
        create(:vaccination_record, :not_administered, patient:, programme:)
      end

      it { should be(:none_yet) }
    end

    context "with a consent refused" do
      before { create(:consent, :refused, patient:, programme:) }

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

  describe "#latest_session_status" do
    subject do
      patient_vaccination_status
        .tap(&:assign_status)
        .latest_session_status
        .to_sym
    end

    before do
      patient.strict_loading!(false)
      create(:patient_location, patient:, session:)
    end

    let(:session) { create(:session, programmes: [programme]) }

    context "with no vaccination record" do
      it { should be(:none_yet) }
    end

    context "with a vaccination administered" do
      before { create(:vaccination_record, patient:, session:, programme:) }

      it { should be(:vaccinated) }
    end

    context "with a vaccination already had" do
      before do
        create(
          :vaccination_record,
          :not_administered,
          :already_had,
          patient:,
          session:,
          programme:
        )
      end

      it { should be(:already_had) }
    end

    context "with a vaccination not administered" do
      before do
        create(
          :vaccination_record,
          :not_administered,
          patient:,
          session:,
          programme:
        )
      end

      it { should be(:unwell) }
    end

    context "with a consent refused" do
      before { create(:consent, :refused, patient:, programme:) }

      it { should be(:refused) }
    end

    context "with a triage as unsafe to vaccination" do
      before { create(:triage, :do_not_vaccinate, patient:, programme:) }

      it { should be(:had_contraindications) }
    end

    context "with a discarded vaccination administered" do
      before do
        create(:vaccination_record, :discarded, patient:, session:, programme:)
      end

      it { should be(:none_yet) }
    end
  end
end
