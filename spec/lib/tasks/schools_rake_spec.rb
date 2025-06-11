# frozen_string_literal: true

describe "schools:move_patients" do
  subject(:invoke) do
    Rake::Task["schools:move_patients"].invoke(
      source_urn,
      target_urn,
      change_date
    )
  end

  let(:organisation) { create(:organisation) }
  let(:team) { create(:team, organisation:) }
  let(:other_team) { create(:team, organisation:) }
  let(:source_school) { create(:school, organisation: organisation, team:) }
  let(:target_school) { create(:school, organisation: organisation) }
  let(:programmes) { [create(:programme, :hpv)] }
  let!(:patient) { create(:patient, school: source_school) }
  let!(:session) { create(:session, location: source_school, programmes:) }
  let!(:school_move) do
    create(:school_move, patient: patient, school: source_school)
  end
  let!(:consent_form_before) do
    create(
      :consent_form,
      school: source_school,
      location: source_school,
      session:,
      created_at: "2024-12-31"
    )
  end
  let!(:consent_form_after) do
    create(
      :consent_form,
      school: source_school,
      location: source_school,
      session:,
      created_at: "2025-01-02"
    )
  end
  let(:other_org_school) { create(:school, team: other_team) }

  let(:source_urn) { source_school.urn.to_s }
  let(:target_urn) { target_school.urn.to_s }
  let(:change_date) { "2025-01-01" }

  after { Rake.application["schools:move_patients"].reenable }

  it "transfers associated records from source to target school" do
    expect { invoke }.to change { patient.reload.school }.from(
      source_school
    ).to(target_school).and change { consent_form_after.reload.school }.from(
            source_school
          ).to(target_school).and change {
                  consent_form_after.reload.location
                }.from(source_school).to(target_school).and change {
                        session.reload.location
                      }.from(source_school).to(target_school).and change {
                              school_move.reload.school
                            }.from(source_school).to(target_school)

    expect(patient.school).to eq(target_school)
    expect(consent_form_after.school).to eq(target_school)
    expect(consent_form_after.location).to eq(target_school)
    expect(session.location).to eq(target_school)
    expect(school_move.school).to eq(target_school)
  end

  it "only transfers consent forms after the change date" do
    invoke

    expect(consent_form_before.reload.school).to eq(source_school)
    expect(consent_form_before.reload.location).to eq(source_school)

    expect(consent_form_after.reload.school).to eq(target_school)
    expect(consent_form_after.reload.location).to eq(target_school)
  end

  context "when source school ID is invalid" do
    let(:source_urn) { "999999" }

    it "raises an error" do
      expect { invoke }.to raise_error(
        RuntimeError,
        /Could not find one or both schools./
      )
    end
  end

  context "when target school ID is invalid" do
    let(:target_urn) { "999999" }

    it "raises an error" do
      expect { invoke }.to raise_error(
        RuntimeError,
        /Could not find one or both schools./
      )
    end
  end
end
