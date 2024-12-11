# frozen_string_literal: true

describe AppPatientCardComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(patient) }

  let(:patient) { create(:patient) }

  it { should have_content("Child record") }

  it { should have_content("Full name") }
  it { should have_content("Date of birth") }
  it { should have_content("Address") }

  context "with a deceased patient" do
    let(:patient) { create(:patient, :deceased) }

    context "with feature flag enabled" do
      before { Flipper.enable(:release_1_2) }
      after { Flipper.enable(:release_1_2) }

      it { should have_content("Record updated with child’s date of death") }
    end

    context "without feature flag enabled" do
      it do
        expect(rendered).not_to have_content(
          "Record updated with child’s date of death"
        )
      end
    end
  end

  context "with an invalidated patient" do
    let(:patient) { create(:patient, :invalidated) }

    context "with feature flag enabled" do
      before { Flipper.enable(:release_1_2) }
      after { Flipper.enable(:release_1_2) }

      it { should have_content("Record flagged as invalid") }
    end

    context "without feature flag enabled" do
      it { should_not have_content("Record flagged as invalid") }
    end
  end

  context "with a restricted patient" do
    let(:patient) { create(:patient, :restricted) }

    context "with feature flag enabled" do
      before { Flipper.enable(:release_1_2) }
      after { Flipper.enable(:release_1_2) }

      it { should have_content("Record flagged as sensitive") }
    end

    context "without feature flag enabled" do
      it { should_not have_content("Record flagged as sensitive") }
    end
  end
end
