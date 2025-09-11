# frozen_string_literal: true

describe PatientArchiver do
  subject(:call) do
    described_class.call(patient:, team:, type:, other_details:)
  end

  let(:patient) { create(:patient) }
  let(:team) { create(:team) }

  let(:type) { "imported_in_error" }
  let(:other_details) { nil }

  it "creates an archive reason" do
    expect { call }.to change(patient.archive_reasons, :count).by(1)

    archive_reason = patient.archive_reasons.last
    expect(archive_reason).to be_imported_in_error
    expect(archive_reason.team_id).to eq(team.id)
  end

  context "when in upcoming sessions" do
    let(:session) { create(:session, :tomorrow, team:) }

    before { create(:patient_session, patient:, session:) }

    it "removes the patient from the sessions" do
      expect(patient.sessions).to include(session)
      call
      expect(patient.reload.sessions).not_to include(session)
    end
  end

  context "with an other type" do
    let(:type) { "other" }
    let(:other_details) { "Details" }

    it "creates an archive reason" do
      expect { call }.to change(patient.archive_reasons, :count).by(1)

      archive_reason = patient.archive_reasons.last
      expect(archive_reason).to be_other
      expect(archive_reason.team_id).to eq(team.id)
      expect(archive_reason.other_details).to eq("Details")
    end
  end
end
