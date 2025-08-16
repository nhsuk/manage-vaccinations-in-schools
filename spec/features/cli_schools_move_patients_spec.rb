# frozen_string_literal: true

describe "schools move-patients" do
  subject(:command) do
    Dry::CLI.new(MavisCLI).call(
      arguments: ["schools", "move-patients", source_urn, target_urn]
    )
  end

  let(:team) { create(:team) }
  let(:subteam) { create(:subteam, team:) }
  let(:other_subteam) { create(:subteam, team:) }
  let(:source_school) { create(:school, team: team, subteam:) }
  let(:target_school) { create(:school, team: team) }
  let(:programmes) { [create(:programme, :hpv)] }
  let!(:patient) { create(:patient, school: source_school) }
  let!(:session) { create(:session, location: source_school, programmes:) }
  let!(:school_move) do
    create(:school_move, patient: patient, school: source_school)
  end
  let!(:consent_form) do
    create(
      :consent_form,
      school: source_school,
      location: source_school,
      session:
    )
  end
  let(:other_org_school) { create(:school, subteam: other_subteam) }

  let(:source_urn) { source_school.urn.to_s }
  let(:target_urn) { target_school.urn.to_s }

  it "transfers associated records from source to target school" do
    expect { command }.to change { patient.reload.school }.from(
      source_school
    ).to(target_school).and change { consent_form.reload.school }.from(
            source_school
          ).to(target_school).and change { consent_form.reload.location }.from(
                  source_school
                ).to(target_school).and change { session.reload.location }.from(
                        source_school
                      ).to(target_school).and change {
                              school_move.reload.school
                            }.from(source_school).to(target_school)

    expect(patient.school).to eq(target_school)
    expect(consent_form.school).to eq(target_school)
    expect(consent_form.location).to eq(target_school)
    expect(session.location).to eq(target_school)
    expect(school_move.school).to eq(target_school)
  end

  context "when some patient sessions are not safe to destroy" do
    let!(:patient_session) { create(:patient_session, patient:, session:) } # rubocop:disable RSpec/LetSetup

    before do
      # rubocop:disable RSpec/AnyInstance
      allow_any_instance_of(PatientSession).to receive(
        :safe_to_destroy?
      ).and_return(false)
      # rubocop:enable RSpec/AnyInstance
    end

    it "raises an error and does not transfer records" do
      expect { command }.to raise_error(
        RuntimeError,
        /Some patient sessions at #{source_school.urn} are not safe to destroy/
      )

      expect(patient.reload.school).to eq(source_school)
      expect(consent_form.reload.school).to eq(source_school)
      expect(consent_form.reload.location).to eq(source_school)
      expect(session.reload.location).to eq(source_school)
      expect(school_move.reload.school).to eq(source_school)
    end
  end

  context "when source school ID is invalid" do
    let(:source_urn) { "999999" }

    it "raises an error" do
      expect { command }.to output(
        /Could not find one or both schools./
      ).to_stderr
    end
  end

  context "when target school ID is invalid" do
    let(:target_urn) { "999999" }

    it "raises an error" do
      expect { command }.to output(
        /Could not find one or both schools./
      ).to_stderr
    end
  end
end
