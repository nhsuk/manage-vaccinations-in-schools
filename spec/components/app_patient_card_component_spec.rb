# frozen_string_literal: true

describe AppPatientCardComponent do
  subject { render_inline(component) }

  let(:component) do
    described_class.new(
      Patient.includes(parent_relationships: :parent).find(patient.id),
      current_team: team
    )
  end

  let(:programmes) { [Programme.hpv] }
  let(:team) { create(:team, programmes:) }
  let(:session) { create(:session, team:, programmes:) }
  let(:school) { create(:school, team:) }

  let(:patient) { create(:patient, school:, year_group: 8) }

  it { should have_content("Child") }

  it { should have_content("Full name") }
  it { should have_content("Date of birth") }
  it { should have_content("Year group") }
  it { should have_content("Address") }

  context "with a deceased patient" do
    let(:patient) { create(:patient, :deceased, session:) }

    it { should have_content("Record updated with child’s date of death") }
  end

  context "with an invalidated patient" do
    let(:patient) { create(:patient, :invalidated, session:) }

    it { should have_content("Record flagged as invalid") }
  end

  context "with a restricted patient" do
    let(:patient) { create(:patient, :restricted, session:) }

    it { should have_content("Record flagged as sensitive") }

    context "with parents" do
      let(:parent) { create(:parent, full_name: "Jenny Smith") }

      before { create(:parent_relationship, :mother, patient:, parent:) }

      it { should_not have_content("Jenny Smith") }
      it { should_not have_content("Mum") }
    end
  end

  context "with parents" do
    let(:parent) { create(:parent, full_name: "Jenny Smith") }

    before { create(:parent_relationship, :mother, patient:, parent:) }

    it { should have_content("Jenny Smith") }
    it { should have_content("Mum") }
  end

  context "when patient is too old for any programmes" do
    let(:patient) { create(:patient, year_group: 13) }

    it { should_not have_content("Year group") }
  end
end
