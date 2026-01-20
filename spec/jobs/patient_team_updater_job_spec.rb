# frozen_string_literal: true

describe PatientTeamUpdaterJob do
  describe "#perform" do
    context "with no arguments" do
      subject(:perform) { described_class.new.perform }

      it "calls the updater with the appropriate scopes" do
        expect(Patient).not_to receive(:all)
        expect(Team).not_to receive(:all)
        expect(PatientTeamUpdater).to receive(:call)

        perform
      end
    end

    context "with a patient" do
      subject(:perform) { described_class.new.perform(patient.id) }

      let(:patient) { create(:patient) }

      it "calls the updater with the appropriate scopes" do
        expect(Patient).to receive(:where).with(id: patient.id)
        expect(Team).not_to receive(:all)
        expect(PatientTeamUpdater).to receive(:call)

        perform
      end
    end

    context "with a team" do
      subject(:perform) { described_class.new.perform(nil, team.id) }

      let(:team) { create(:team) }

      it "calls the updater with the appropriate scopes" do
        expect(Patient).not_to receive(:all)
        expect(Team).to receive(:where).with(id: team.id)
        expect(PatientTeamUpdater).to receive(:call)

        perform
      end
    end

    context "with a patient and a team" do
      subject(:perform) { described_class.new.perform(patient.id, team.id) }

      let(:patient) { create(:patient) }
      let(:team) { create(:team) }

      it "calls the updater with the appropriate scopes" do
        expect(Patient).to receive(:where).with(id: patient.id)
        expect(Team).to receive(:where).with(id: team.id)
        expect(PatientTeamUpdater).to receive(:call)

        perform
      end
    end
  end
end
