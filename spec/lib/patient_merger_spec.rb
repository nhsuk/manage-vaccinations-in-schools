# frozen_string_literal: true

describe PatientMerger do
  describe "#call" do
    subject(:call) do
      described_class.call(
        to_keep: patient_to_keep,
        to_destroy: patient_to_destroy
      )
    end

    let(:programme) { create(:programme) }
    let(:session) { create(:session, programme:) }

    let!(:patient_to_keep) { create(:patient) }
    let!(:patient_to_destroy) { create(:patient) }

    let(:consent) { create(:consent, patient: patient_to_destroy, programme:) }
    let(:gillick_assessment) { create(:gillick_assessment, patient_session:) }
    let(:parent_relationship) do
      create(:parent_relationship, patient: patient_to_destroy)
    end
    let(:patient_session) do
      create(:patient_session, session:, patient: patient_to_destroy)
    end
    let(:triage) { create(:triage, patient: patient_to_destroy, programme:) }
    let(:vaccination_record) do
      create(:vaccination_record, patient_session:, programme:)
    end

    it "destroys one of the patients" do
      expect { call }.to change(Patient, :count).by(-1)
      expect { patient_to_destroy.reload }.to raise_error(
        ActiveRecord::RecordNotFound
      )
    end

    it "moves consents" do
      expect { call }.to change { consent.reload.patient }.to(patient_to_keep)
    end

    it "moves gillick assessments" do
      expect { call }.to change { gillick_assessment.reload.patient }.to(
        patient_to_keep
      )
    end

    it "moves parent relationships" do
      expect { call }.to change { parent_relationship.reload.patient }.to(
        patient_to_keep
      )
    end

    it "moves patient sessions" do
      expect { call }.to change { patient_session.reload.patient }.to(
        patient_to_keep
      )
    end

    it "moves triages" do
      expect { call }.to change { triage.reload.patient }.to(patient_to_keep)
    end

    it "moves vaccination records" do
      expect { call }.to change { vaccination_record.reload.patient }.to(
        patient_to_keep
      )
    end
  end
end
