# frozen_string_literal: true

describe AppPatientCardComponent do
  subject { render_inline(component) }

  let(:component) { described_class.new(patient) }

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
  end
end
