# frozen_string_literal: true

describe AppPatientDetailsComponent do
  subject { page }

  before { render_inline(component) }

  context "with a patient object" do
    let(:parent) { create(:parent) }
    let(:school) { create(:location, :school) }
    let(:patient) do
      create(
        :patient,
        nhs_number: 1_234_567_890,
        common_name: "Homer",
        parents: [parent],
        school:,
      )
    end

    let(:component) { described_class.new(patient:) }

    it "renders the patient's full name" do
      expect(page).to(
        have_css(".nhsuk-summary-list__row", text: "Name#{patient.full_name}")
      )
    end

    it "renders the patient's preferred name" do
      expect(page).to(
        have_css(".nhsuk-summary-list__row", text: "Known asHomer")
      )
    end

    it "renders the patient's date of birth" do
      expected_dob =
        "#{patient.date_of_birth.to_fs(:long)} (aged #{patient.age})"
      expect(page).to(
        have_css(
          ".nhsuk-summary-list__row",
          text: "Date of birth#{expected_dob}"
        )
      )
    end

    it "renders the school name" do
      expect(page).to(
        have_css(".nhsuk-summary-list__row", text: "School#{school.name}")
      )
    end

    it "does not render a GP name" do
      expect(page).not_to have_css(".nhsuk-summary-list__row", text: /^GP/)
    end

    it "does not render a GP response" do
      expect(page).not_to(
        have_css(".nhsuk-summary-list__row", text: "Registered with a GP")
      )
    end

    it "renders the patient's NHS number" do
      expect(page).to(have_css(".nhsuk-summary-list__key", text: "NHS number"))
      expect(page).to(
        have_css(
          ".nhsuk-summary-list__row .app-u-monospace",
          text: "123\u00A0\u200D456\u00A0\u200D7890"
        )
      )
    end

    it "renders the patient's parents" do
      expect(page).to(
        have_css(".nhsuk-summary-list__key", text: "Parent or guardian")
      )
      expect(page).to(have_css(".nhsuk-summary-list__row", text: parent.name))
      expect(page).to(have_css(".nhsuk-summary-list__row", text: parent.phone))
    end

    context "without a preferred name" do
      let(:patient) { create(:patient, common_name: nil) }

      it "does not render known as" do
        expect(page).not_to(
          have_css(".nhsuk-summary-list__row", text: "Known as")
        )
      end
    end
  end

  context "with a consent_form object" do
    let(:consent_form) do
      create(:consent_form, common_name: "Homer", use_common_name: true)
    end
    let(:component) { described_class.new(consent_form:) }

    it "renders the child's full name" do
      expect(page).to(
        have_css(
          ".nhsuk-summary-list__row",
          text: "Name#{consent_form.full_name}"
        )
      )
    end

    it "renders the child's common name" do
      expect(page).to have_css(
        ".nhsuk-summary-list__row",
        text: "Known asHomer"
      )
    end

    it "renders the child's date of birth" do
      formatted_date = consent_form.date_of_birth.to_fs(:long)
      expected_dob = "#{formatted_date} (aged #{consent_form.age})"
      expect(page).to(
        have_css(
          ".nhsuk-summary-list__row",
          text: "Date of birth#{expected_dob}"
        )
      )
    end

    it "renders the child's address" do
      expect(page).to(
        have_css(
          ".nhsuk-summary-list__row",
          text:
            "Address" \
              "#{consent_form.address_line_1}" \
              "#{consent_form.address_line_2}" \
              "#{consent_form.address_town}" \
              "#{consent_form.address_postcode}"
        )
      )
    end

    it "renders the GP name" do
      expect(page).to(
        have_css(".nhsuk-summary-list__row", text: "GP#{consent_form.gp_name}")
      )
    end

    it "renders 'Not provided' for the NHS number" do
      expect(page).to(
        have_css(".nhsuk-summary-list__row", text: "NHS numberNot provided")
      )
    end

    it "renders the parent details" do
      expect(page).to(
        have_css(".nhsuk-summary-list__key", text: "Parent or guardian")
      )
      expect(page).to(
        have_css(".nhsuk-summary-list__row", text: consent_form.parent_name)
      )
      expect(page).to(
        have_css(".nhsuk-summary-list__row", text: consent_form.parent_phone)
      )
    end

    context "without a common name" do
      let(:consent_form) { create(:consent_form, common_name: nil) }

      it "does not render known as" do
        expect(page).not_to(
          have_css(".nhsuk-summary-list__row", text: "Known as")
        )
      end
    end

    context "when child does not have a date of birth on record" do
      let(:consent_form) { create(:consent_form, date_of_birth: nil) }

      it "does not render the child's date of birth" do
        expect(page).not_to(
          have_css(".nhsuk-summary-list__row", text: "Date of birth")
        )
      end
    end

    context "when child does not have a GP" do
      let(:consent_form) do
        create(
          :consent_form,
          common_name: "Homer",
          gp_name: nil,
          gp_response: "no"
        )
      end

      it "does not render a GP name" do
        expect(page).not_to(have_css(".nhsuk-summary-list__row", text: /^GP/))
      end

      it "renders GP response" do
        expect(page).to(
          have_css(".nhsuk-summary-list__row", text: "Registered with a GPNo")
        )
      end
    end

    context "when it's unknown whether the child has a GP" do
      let(:consent_form) do
        create(
          :consent_form,
          common_name: "Homer",
          gp_name: nil,
          gp_response: "dont_know"
        )
      end

      it "does not render a GP name" do
        expect(page).not_to(have_css(".nhsuk-summary-list__row", text: /^GP/))
      end

      it "renders GP response" do
        expect(page).to(
          have_css(
            ".nhsuk-summary-list__row",
            text: "Registered with a GPI don’t know"
          )
        )
      end
    end
  end
end
