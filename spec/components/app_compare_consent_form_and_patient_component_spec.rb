# frozen_string_literal: true

describe AppCompareConsentFormAndPatientComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(heading: "", consent_form:, patient:) }

  let(:location) { create(:school, name: "Waterloo Road") }
  let(:consent_form) do
    create(
      :consent_form,
      given_name: "John",
      family_name: "Doe",
      date_of_birth: "2000-01-01",
      address_line_1: "1 Main Street",
      address_line_2: "Area",
      address_town: "Some Town",
      address_postcode: "SW11 1AA",
      location:
    )
  end

  describe "when the consent form matches the patient" do
    let(:patient) do
      create(
        :patient,
        given_name: consent_form.given_name,
        family_name: consent_form.family_name,
        date_of_birth: consent_form.date_of_birth,
        address_line_1: consent_form.address_line_1,
        address_line_2: consent_form.address_line_2,
        address_town: consent_form.address_town,
        address_postcode: consent_form.address_postcode,
        school: consent_form.location
      )
    end

    it "displays the key consent form details without anything being highlighted as unmatched" do
      expect(rendered).to have_text("Full name\nDOE, John\nDOE, John")
      expect(rendered).to have_text(
        "Date of birth\n1 January 2000\n1 January 2000"
      )
      expect(rendered).to have_text(
        [
          "Address",
          "1 Main StreetAreaSome TownSW11 1AA",
          "1 Main StreetAreaSome TownSW11 1AA"
        ].join("\n")
      )
      expect(rendered).to have_text("School\nWaterloo Road\nWaterloo Road")
    end
  end

  describe "when the consent form does not match the patient" do
    let(:patient) do
      create(
        :patient,
        given_name: "Jane", # different
        family_name: consent_form.family_name,
        date_of_birth: Date.new(2000, 1, 2), # different
        address_line_1: "2 Main Street", # different
        address_line_2: consent_form.address_line_2,
        address_town: consent_form.address_town,
        address_postcode: consent_form.address_postcode,
        school: create(:school, name: "Hogwarts")
      )
    end

    it "displays the key consent form details with the unmatched details highlighted" do
      expect(rendered).to have_text("Full name\nDOE, John\nDOE, Jane")
      expect(rendered).to have_text(
        "Date of birth\n1 January 2000\n2 January 2000"
      )
      expect(rendered).to have_text(
        [
          "Address",
          "1 Main StreetAreaSome TownSW11 1AA",
          "2 Main StreetAreaSome TownSW11 1AA"
        ].join("\n")
      )
      expect(rendered).to have_text("School\nWaterloo Road\nHogwarts")
    end
  end
end
