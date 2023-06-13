require "rails_helper"

RSpec.describe AppStatusTagComponent, type: :component do
  let(:status) { :no_outcome }
  let(:component) { render_inline(described_class.new(status:)) }

  context "when status is :no_outcome" do
    it "renders no_outcome css class" do
      expect(
        component.css(".app-status-tag.nhsuk-tag.nhsuk-tag--white")
      ).to be_present
    end

    it "renders no status text" do
      expect(component.text).to include("No outcome yet")
    end

    it "does not render svg icon" do
      expect(component.css("svg")).to be_empty
    end
  end

  context "when status is :vaccinated" do
    let(:status) { :vaccinated }

    it "renders vaccinated css class" do
      expect(
        component.css(".app-status-tag.nhsuk-tag.nhsuk-tag--green")
      ).to be_present
    end

    it "renders vaccinated text" do
      expect(component.text).to include("Vaccinated")
    end

    it "renders tick svg icon" do
      expect(component.css(".nhsuk-icon__tick")).to be_present
    end
  end

  context "when status is :no_consent" do
    let(:status) { :no_consent }

    it "renders no_consent css class" do
      expect(
        component.css(".app-status-tag.nhsuk-tag.nhsuk-tag--red")
      ).to be_present
    end

    it "renders no consent text" do
      expect(component.text).to include("No consent")
    end

    it "renders cross svg icon" do
      expect(component.css(".nhsuk-icon__cross")).to be_present
    end
  end

  context "when status is :could_not_vaccinate" do
    let(:status) { :could_not_vaccinate }

    it "renders could_not_vaccinate css class" do
      expect(
        component.css(".app-status-tag.nhsuk-tag.nhsuk-tag--orange")
      ).to be_present
    end

    it "renders could not vaccinate text" do
      expect(component.text).to include("Could not vaccinate")
    end

    it "renders cross svg icon" do
      expect(component.css(".nhsuk-icon__cross")).to be_present
    end
  end

  context "when status is unknown" do
    let(:status) { :unknown }

    it "raises an error" do
      expect { component }.to raise_error(
        RuntimeError,
        "Unknown status: unknown"
      )
    end
  end
end
