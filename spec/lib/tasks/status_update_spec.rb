# frozen_string_literal: true

describe "status:update" do
  context "with all patients" do
    subject(:invoke) { Rake::Task["status:update:all"].invoke }

    before { create(:patient_location) }

    after { Rake.application["status:update:all"].reenable }

    it "doesn't raise an error" do
      expect { invoke }.not_to raise_error
    end

    it "calls the status updater" do
      expect(StatusUpdater).to receive(:call)
      invoke
    end
  end

  context "with a patient" do
    subject(:invoke) { Rake::Task["status:update:patient"].invoke(patient.id) }

    after { Rake.application["status:update:patient"].reenable }

    let(:patient) { create(:patient) }

    before { create(:patient_location, patient:) }

    it "doesn't raise an error" do
      expect { invoke }.not_to raise_error
    end

    it "calls the status updater" do
      expect(StatusUpdater).to receive(:call).with(patient:)
      invoke
    end
  end

  context "with a session" do
    subject(:invoke) do
      Rake::Task["status:update:session"].invoke(session.slug)
    end

    after { Rake.application["status:update:session"].reenable }

    let(:session) { create(:session) }

    before { create(:patient_location, session:) }

    it "doesn't raise an error" do
      expect { invoke }.not_to raise_error
    end

    it "calls the status updater" do
      expect(StatusUpdater).to receive(:call).with(session:)
      invoke
    end
  end
end
