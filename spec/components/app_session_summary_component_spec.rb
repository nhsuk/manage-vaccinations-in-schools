# frozen_string_literal: true

describe AppSessionSummaryComponent do
  subject(:rendered) { render_inline(component) }

  let(:component) { described_class.new(session) }

  let(:programmes) { [create(:programme, :hpv)] }
  let(:location) do
    create(
      :school,
      name: "Streeling University",
      urn: 123_456,
      address_postcode: "SW1A 1AA"
    )
  end
  let(:organisation) { create(:organisation, programmes:) }
  let(:session) do
    create(
      :session,
      location:,
      date: Date.new(2024, 1, 1),
      programmes:,
      organisation:
    )
  end

  it { should have_content("Streeling University") }

  it { should have_content("School URN") }
  it { should have_content("123456") }

  it { should have_content("Address") }
  it { should have_content("SW1A 1AA") }

  it { should have_content("Consent forms") }
  it { should have_link("Download the HPV consent form (PDF)") }

  context "when consent is open" do
    let(:session) do
      create(:session, location:, date: 1.week.from_now.to_date, programmes:)
    end

    it do
      expect(rendered).to have_link(
        "View the HPV online consent form (opens in new tab)"
      )
    end
  end
end
