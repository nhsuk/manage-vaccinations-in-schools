# frozen_string_literal: true

describe AppSessionSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(session) }

  let(:programmes) { [Programme.hpv] }
  let(:location) do
    create(
      :school,
      :secondary,
      name: "Streeling University",
      urn: 123_456,
      address_postcode: "SW1A 1AA",
      programmes:
    )
  end
  let(:team) { create(:team, programmes:) }
  let(:session) { create(:session, location:, programmes:, team:) }

  it { should have_content("ProgrammesHPV") }
  it { should have_content("Year groupsYears 8 to 11") }

  context "when showing the location" do
    let(:component) { described_class.new(session, show_location: true) }

    it { should have_content("Location") }
    it { should have_content("SW1A 1AA") }

    it { should have_content("School URN") }
    it { should have_content("123456") }
  end

  context "when showing the consent forms" do
    let(:component) { described_class.new(session, show_consent_forms: true) }

    it { should have_content("Consent forms") }
    it { should have_link("Download the HPV consent form (PDF)") }

    context "for MMR(V) programme" do
      let(:programmes) { [Programme.mmr] }

      it { should have_link("Download the MMR consent form (PDF)") }
    end

    context "when consent is open" do
      let(:session) do
        create(:session, location:, date: 1.week.from_now.to_date, programmes:)
      end

      it do
        expect(rendered).to have_link(
          "View the HPV online consent form (opens in new tab)"
        )
      end

      context "for MMR(V) programme" do
        let(:programmes) { [Programme.mmr] }

        it { should have_link("View the MMR online consent form") }
      end
    end
  end
end
