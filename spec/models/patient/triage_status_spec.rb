# frozen_string_literal: true

# == Schema Information
#
# Table name: patient_triage_statuses
#
#  id             :bigint           not null, primary key
#  status         :integer          default("not_required"), not null
#  vaccine_method :integer
#  patient_id     :bigint           not null
#  programme_id   :bigint           not null
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

  let(:patient) { create(:patient, year_group: 9) }
  let(:programme) { create(:programme) }

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
      ]
    )
  end

  describe "#status" do
    subject { patient_triage_status.tap(&:assign_status).status.to_sym }

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

    context "when the patient is already vaccinated" do
      shared_examples "a vaccinated patient with any triage status" do
        before do
          create(:triage, triage_trait, patient:, programme:) if triage_trait
        end

        it { should be(:not_required) }
      end

      before do
        create(:vaccination_record, patient:, programme:)
        create(:patient_vaccination_status, :vaccinated, patient:, programme:)
      end

      context "with a safe to vaccinate triage" do
        it_behaves_like "a vaccinated patient with any triage status" do
          let(:triage_trait) { :ready_to_vaccinate }
        end
      end

      context "with a do not vaccinate triage" do
        it_behaves_like "a vaccinated patient with any triage status" do
          let(:triage_trait) { :do_not_vaccinate }
        end
      end

      context "with a needs follow up triage" do
        it_behaves_like "a vaccinated patient with any triage status" do
          let(:triage_trait) { :needs_follow_up }
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
      let(:programme) { create(:programme, :td_ipv) }

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
      before { create(:triage, :ready_to_vaccinate, patient:, programme:) }

      it { should eq("injection") }
    end

    context "with a safe to vaccinate triage and vaccinated" do
      before do
        create(:triage, :ready_to_vaccinate, patient:, programme:)
        create(:vaccination_record, patient:, programme:)
      end

      it { should be_nil }
    end

    context "with a do not vaccinate triage" do
      before { create(:triage, :do_not_vaccinate, patient:, programme:) }

      it { should be_nil }
    end

    context "with a needs follow up triage" do
      before { create(:triage, :needs_follow_up, patient:, programme:) }

      it { should be_nil }
    end

    context "with a delay vaccination triage" do
      before { create(:triage, :delay_vaccination, patient:, programme:) }

      it { should be_nil }
    end

    context "with an invalidated safe to vaccinate triage" do
      before do
        create(:triage, :ready_to_vaccinate, :invalidated, patient:, programme:)
      end

      it { should be_nil }
    end
  end
end
