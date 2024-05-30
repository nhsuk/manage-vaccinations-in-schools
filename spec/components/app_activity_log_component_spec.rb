require "rails_helper"

shared_examples "card" do |params|
  it "renders card ##{params[:nth]} '#{params[:title]}'" do
    expect(page).to have_css(
      ".nhsuk-card:nth-of-type(#{params[:nth]}) h3",
      text: params[:title]
    )
    expect(page).to have_css(
      ".nhsuk-card:nth-of-type(#{params[:nth]}) p",
      text: params[:date]
    )
  end
end

describe AppActivityLogComponent, type: :component do
  let(:campaign) { create(:campaign) }
  let(:session) { create(:session, campaign:) }
  let(:patient) { create(:patient) }
  let!(:consents) do
    [
      create(
        :consent,
        :given,
        :from_mum,
        campaign:,
        patient:,
        parent_name: "Jane Doe",
        recorded_at: Time.zone.parse("2024-05-30 12:00")
      ),
      create(
        :consent,
        :refused,
        :from_dad,
        campaign:,
        patient:,
        parent_name: "John Doe",
        recorded_at: Time.zone.parse("2024-05-30 13:00")
      )
    ]
  end

  let(:patient_session) { create(:patient_session, patient:, session:) }
  let(:component) { described_class.new(patient_session) }

  before { render_inline(component) }

  subject { page }

  it "renders heading #1 correctly" do
    expect(page).to have_css("h2:nth-of-type(1)", text: "30 May 2024")
  end

  include_examples "card",
                   nth: 1,
                   title: "Consent refused by John Doe (Dad)",
                   date: "30 May 2024 at 1:00pm"

  include_examples "card",
                   nth: 2,
                   title: "Consent given by Jane Doe (Mum)",
                   date: "30 May 2024 at 12:00pm"
end
