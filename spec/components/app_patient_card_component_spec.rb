# frozen_string_literal: true

describe AppPatientCardComponent do
  subject { render_inline(component) }

  let(:component) do
    described_class.new(
      Patient.includes(parent_relationships: :parent).find(patient.id)
    )
  end

  let(:patient) { create(:patient) }

  it { should have_content("Child") }

  it { should have_content("Full name") }
  it { should have_content("Date of birth") }
  it { should have_content("Address") }

  context "with a deceased patient" do
    let(:patient) { create(:patient, :deceased) }

    it { should have_content("Record updated with child’s date of death") }
  end

  context "with an invalidated patient" do
    let(:patient) { create(:patient, :invalidated) }

    it { should have_content("Record flagged as invalid") }
  end

  context "with a restricted patient" do
    let(:patient) { create(:patient, :restricted) }

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
end
