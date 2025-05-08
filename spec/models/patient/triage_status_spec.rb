# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_triage_statuses
#
#  id           :bigint           not null, primary key
#  status       :integer          default("not_required"), not null
#  patient_id   :bigint           not null
#  programme_id :bigint           not null
#
# Indexes
#
#  index_patient_triage_statuses_on_patient_id_and_programme_id  (patient_id,programme_id) UNIQUE
#  index_patient_triage_statuses_on_status                       (status)
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

  let(:patient) { create(:patient) }
  let(:programme) { create(:programme) }

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
      ]
    )
  end

  describe "#status" do
    subject { patient_triage_status.assign_status }

    before { patient.strict_loading!(false) }

    context "with no triage" do
      it { should be(:not_required) }
    end

    context "with a consent that needs triage" do
      before { create(:consent, :needing_triage, patient:, programme:) }

      it { should be(:required) }
    end

    context "with a historical vaccination that needs triage" do
      let(:programme) { create(:programme, :td_ipv) }

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
      before { create(:triage, :ready_to_vaccinate, patient:, programme:) }

      it { should be(:safe_to_vaccinate) }
    end

    context "with a do not vaccinate triage" do
      before { create(:triage, :do_not_vaccinate, patient:, programme:) }

      it { should be(:do_not_vaccinate) }
    end

    context "with a needs follow up triage" do
      before { create(:triage, :needs_follow_up, patient:, programme:) }

      it { should be(:required) }
    end

    context "with a delay vaccination triage" do
      before { create(:triage, :delay_vaccination, patient:, programme:) }

      it { should be(:delay_vaccination) }
    end

    context "with an invalidated safe to vaccinate triage" do
      before do
        create(:triage, :ready_to_vaccinate, :invalidated, patient:, programme:)
      end

      it { should be(:not_required) }
    end
  end
end
