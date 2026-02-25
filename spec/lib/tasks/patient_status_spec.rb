# frozen_string_literal: true

describe "patient_status" do
  context "updating all patients" do
    subject(:invoke) { Rake::Task["patient_status:update:all"].invoke }

    before { create(:patient_location) }

    after { Rake.application["patient_status:update:all"].reenable }

    it "doesn't raise an error" do
      expect { invoke }.not_to raise_error
    end

    it "calls the status updater" do
      expect(PatientStatusUpdater).to receive(:call)
      invoke
    end
  end

  context "updating a single patient" do
    subject(:invoke) do
      Rake::Task["patient_status:update:patient"].invoke(patient.id)
    end

    after { Rake.application["patient_status:update:patient"].reenable }

    let(:patient) { create(:patient) }

    before { create(:patient_location, patient:) }

    it "doesn't raise an error" do
      expect { invoke }.not_to raise_error
    end

    it "calls the status updater" do
      expect(PatientStatusUpdater).to receive(:call).with(patient:)
      invoke
    end
  end
end
