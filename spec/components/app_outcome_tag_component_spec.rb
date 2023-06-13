require "rails_helper"

RSpec.describe AppOutcomeTagComponent, type: :component do
  let(:outcome) { :no_outcome }
  let(:component) { render_inline(described_class.new(outcome:)) }

  context "when outcome is :no_outcome" do
    it "renders no_outcome css class" do
      expect(
        component.css(".app-outcome-tag.nhsuk-tag.nhsuk-tag--white")
      ).to be_present
    end

    it "renders no outcome text" do
      expect(component.text).to include("No outcome yet")
    end

    it "does not render svg icon" do
      expect(component.css("svg")).to be_empty
    end
  end

  context "when outcome is :vaccinated" do
    let(:outcome) { :vaccinated }

    it "renders vaccinated css class" do
      expect(
        component.css(".app-outcome-tag.nhsuk-tag.nhsuk-tag--green")
      ).to be_present
    end

    it "renders vaccinated text" do
      expect(component.text).to include("Vaccinated")
    end

    it "renders tick svg icon" do
      expect(component.css(".nhsuk-icon__tick")).to be_present
    end
  end

  context "when outcome is :no_consent" do
    let(:outcome) { :no_consent }

    it "renders no_consent css class" do
      expect(
        component.css(".app-outcome-tag.nhsuk-tag.nhsuk-tag--red")
      ).to be_present
    end

    it "renders no consent text" do
      expect(component.text).to include("No consent")
    end

    it "renders cross svg icon" do
      expect(component.css(".nhsuk-icon__cross")).to be_present
    end
  end

  context "when outcome is :could_not_vaccinate" do
    let(:outcome) { :could_not_vaccinate }

    it "renders could_not_vaccinate css class" do
      expect(
        component.css(".app-outcome-tag.nhsuk-tag.nhsuk-tag--orange")
      ).to be_present
    end

    it "renders could not vaccinate text" do
      expect(component.text).to include("Could not vaccinate")
    end

    it "renders cross svg icon" do
      expect(component.css(".nhsuk-icon__cross")).to be_present
    end
  end

  context "when outcome is unknown" do
    let(:outcome) { :unknown }

    it "raises an error" do
      expect { component }.to raise_error(
        RuntimeError,
        "Unknown outcome: unknown"
      )
    end
  end
end
