# frozen_string_literal: true

describe AppCompareConsentFormAndPatientComponent, type: :component do
  subject { page }

  let(:consent_form) do
    create(
      :consent_form,
      first_name: "John",
      last_name: "Doe",
      date_of_birth: "2000-01-01",
      address_line_1: "1 Main Street",
      address_line_2: "Area",
      address_town: "Some Town",
      address_postcode: "AB1 2CD"
    )
  end
  let(:patient) { create(:patient) }
  let(:component) { described_class.new(heading: "", consent_form:, patient:) }

  before { render_inline(component) }

  describe "when the consent form matches the patient" do
    let(:patient) do
      create(
        :patient,
        first_name: consent_form.first_name,
        last_name: consent_form.last_name,
        date_of_birth: consent_form.date_of_birth,
        address_line_1: consent_form.address_line_1,
        address_line_2: consent_form.address_line_2,
        address_town: consent_form.address_town,
        address_postcode: consent_form.address_postcode
      )
    end

    it "displays the key consent form details without anything being highlighted as unmatched" do
      expect(page).to have_text(["Child’s name", "John Doe", "John Doe"].join)
      expect(page).to have_text(
        ["Date of birth", "1 January 2000", "1 January 2000"].join
      )
      expect(page).to have_text(
        [
          "Address",
          "1 Main Street",
          "Area",
          "Some Town",
          "AB1 2CD",
          "1 Main Street",
          "Area",
          "Some Town",
          "AB1 2CD"
        ].join
      )
    end
  end

  describe "when the consent form does not match the patient" do
    let(:patient) do
      create(
        :patient,
        first_name: "Jane", # different
        last_name: consent_form.last_name,
        date_of_birth: "2000-01-02", #different
        address_line_1: "2 Main Street", # different
        address_line_2: consent_form.address_line_2,
        address_town: consent_form.address_town,
        address_postcode: consent_form.address_postcode
      )
    end

    it "displays the key consent form details with the unmatched details highlighted" do
      expect(page).to have_text(["Child’s name", "John Doe", "Jane Doe"].join)
      expect(page).to have_text(
        ["Date of birth", "1 January 2000", "2 January 2000"].join
      )
      expect(page).to have_text(
        [
          "Address",
          "1 Main Street",
          "Area",
          "Some Town",
          "AB1 2CD",
          "2 Main Street",
          "Area",
          "Some Town",
          "AB1 2CD"
        ].join
      )
    end
  end
end
