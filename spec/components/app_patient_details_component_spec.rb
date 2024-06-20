require "rails_helper"

describe AppPatientDetailsComponent, type: :component do
  before { render_inline(component) }

  subject { page }

  let(:session) { FactoryBot.create(:session) }

  context "with a patient object" do
    let(:patient) do
      FactoryBot.create(
        :patient,
        nhs_number: 1_234_567_890,
        common_name: "Homer"
      )
    end
    let(:school) { FactoryBot.create(:location) }
    let(:component) { described_class.new(patient:, session:, school:) }

    it "should render the patient's full name" do
      expect(page).to(
        have_css(".nhsuk-summary-list__row", text: "Name#{patient.full_name}")
      )
    end

    it "should render the patient's preferred name" do
      expect(page).to(
        have_css(".nhsuk-summary-list__row", text: "Known asHomer")
      )
    end

    it "should render the patient's date of birth" do
      expected_dob =
        "#{patient.date_of_birth.to_fs(:nhsuk_date)} (aged #{patient.age})"
      expect(page).to(
        have_css(
          ".nhsuk-summary-list__row",
          text: "Date of birth#{expected_dob}"
        )
      )
    end

    it "should render the school name" do
      expect(page).to(
        have_css(".nhsuk-summary-list__row", text: "School#{school.name}")
      )
    end

    it "should not render a GP name" do
      expect(page).not_to have_css(".nhsuk-summary-list__row", text: /^GP/)
    end

    it "should not render a GP response" do
      expect(page).not_to(
        have_css(".nhsuk-summary-list__row", text: "Registered with a GP")
      )
    end

    it "should render the patient's NHS number" do
      expect(page).to(
        have_css(".nhsuk-summary-list__row", text: "NHS Number123 456 7890")
      )
    end

    context "without a preferred name" do
      let(:patient) { FactoryBot.create(:patient, common_name: nil) }

      it "should not render known as" do
        expect(page).not_to(
          have_css(".nhsuk-summary-list__row", text: "Known as")
        )
      end
    end
  end

  context "with a consent_form object" do
    let(:consent_form) do
      FactoryBot.create(
        :consent_form,
        common_name: "Homer",
        use_common_name: true
      )
    end
    let(:school) { FactoryBot.create(:location) }
    let(:component) { described_class.new(consent_form:, session:, school:) }

    it "should render the child's full name" do
      expect(page).to(
        have_css(
          ".nhsuk-summary-list__row",
          text: "Name#{consent_form.full_name}"
        )
      )
    end

    it "should render the child's common name" do
      expect(page).to have_css(
        ".nhsuk-summary-list__row",
        text: "Known asHomer"
      )
    end

    it "should render the child's date of birth" do
      formatted_date = consent_form.date_of_birth.to_fs(:nhsuk_date)
      expected_dob = "#{formatted_date} (aged #{consent_form.age})"
      expect(page).to(
        have_css(
          ".nhsuk-summary-list__row",
          text: "Date of birth#{expected_dob}"
        )
      )
    end

    it "should render the child's address" do
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

    it "should render the school name" do
      expect(page).to(
        have_css(".nhsuk-summary-list__row", text: "School#{school.name}")
      )
    end

    it "should render the GP name" do
      expect(page).to(
        have_css(".nhsuk-summary-list__row", text: "GP#{consent_form.gp_name}")
      )
    end

    it "should not render an NHS number" do
      expect(page).not_to(
        have_css(".nhsuk-summary-list__row", text: "NHS Number")
      )
    end

    context "without a common name" do
      let(:consent_form) { FactoryBot.create(:consent_form, common_name: nil) }

      it "should not render known as" do
        expect(page).not_to(
          have_css(".nhsuk-summary-list__row", text: "Known as")
        )
      end
    end

    context "when child does not have a date of birth on record" do
      let(:consent_form) do
        FactoryBot.create(:consent_form, date_of_birth: nil)
      end

      it "should not render the child's date of birth" do
        expect(page).not_to(
          have_css(".nhsuk-summary-list__row", text: "Date of birth")
        )
      end
    end

    context "when child does not have a GP" do
      let(:consent_form) do
        FactoryBot.create(
          :consent_form,
          common_name: "Homer",
          gp_name: nil,
          gp_response: "no"
        )
      end

      it "should not render a GP name" do
        expect(page).not_to(have_css(".nhsuk-summary-list__row", text: /^GP/))
      end

      it "should render GP response" do
        expect(page).to(
          have_css(".nhsuk-summary-list__row", text: "Registered with a GPNo")
        )
      end
    end

    context "when it's unknown whether the child has a GP" do
      let(:consent_form) do
        FactoryBot.create(
          :consent_form,
          common_name: "Homer",
          gp_name: nil,
          gp_response: "dont_know"
        )
      end

      it "should not render a GP name" do
        expect(page).not_to(have_css(".nhsuk-summary-list__row", text: /^GP/))
      end

      it "should render GP response" do
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
