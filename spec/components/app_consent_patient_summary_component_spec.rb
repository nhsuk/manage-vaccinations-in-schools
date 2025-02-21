# frozen_string_literal: true

describe AppConsentPatientSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(consent) }

  let(:programme) { create(:programme) }
  let(:organisation) { create(:organisation, programmes: [programme]) }

  let(:consent) do
    create(:consent, patient:, consent_form:, programme:, organisation:)
  end
  let(:school) { create(:school, name: "Waterloo Road", organisation:) }
  let(:session) do
    create(:session, programme:, organisation:, location: school)
  end
  let(:consent_form) { nil }
  let(:patient) { create(:patient) }

  context "with a consent form" do
    let(:consent_form) do
      create(
        :consent_form,
        address_postcode: "SW1A 1AA",
        date_of_birth: Date.new(2000, 1, 1),
        given_name: "John",
        family_name: "Doe",
        session:
      )
    end

    it { should have_content("Full name") }
    it { should have_content("DOE, John") }

    it { should have_content("Date of birth") }
    it { should have_content("1 January 2000") }

    it { should have_content("Home address") }
    it { should have_content("SW1A 1AA") }

    it { should have_content("School") }
    it { should have_content("Waterloo Road") }
  end

  context "without a consent form" do
    let(:patient) do
      create(
        :patient,
        given_name: "John",
        family_name: "Doe",
        date_of_birth: Date.new(2000, 1, 1),
        address_postcode: "SW1A 1AA",
        school:,
        organisation:
      )
    end

    it { should have_content("Full name") }
    it { should have_content("DOE, John") }

    it { should have_content("Date of birth") }
    it { should have_content("1 January 2000") }

    it { should have_content("Home address") }
    it { should have_content("SW1A 1AA") }

    it { should have_content("School") }
    it { should have_content("Waterloo Road") }
  end

  context "with a restricted patient" do
    let(:patient) { create(:patient, :restricted) }

    it { should_not have_content("Home address") }
  end
end
