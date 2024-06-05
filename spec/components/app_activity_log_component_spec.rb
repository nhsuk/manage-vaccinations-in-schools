require "rails_helper"

shared_examples "card" do |params|
  it "renders card '#{params[:title]}'" do
    expect(page).to have_css(".nhsuk-card h3", text: params[:title])
    expect(page).to have_css(".nhsuk-card p", text: params[:date])
    expect(page).to have_css(".nhsuk-card p", text: params[:by]) if params[:by]
  end
end

describe AppActivityLogComponent, type: :component do
  let(:team) { create(:team) }
  let(:user) { create(:user, teams: [team], full_name: "Nurse Joy") }
  let(:campaign) { create(:campaign, team:) }
  let(:location) { create(:location, team:, name: "Hogwarts") }
  let(:session) { create(:session, campaign:, location:) }
  let(:patient) { create(:patient, location:) }

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

  let!(:triages) do
    [
      create(
        :triage,
        :kept_in_triage,
        patient_session:,
        created_at: Time.zone.parse("2024-05-30 14:00"),
        user:
      ),
      create(
        :triage,
        :vaccinate,
        patient_session:,
        created_at: Time.zone.parse("2024-05-30 14:30"),
        user:
      )
    ]
  end

  let!(:vaccination_records) do
    [
      create(
        :vaccination_record,
        patient_session:,
        created_at: Time.zone.parse("2024-05-31 12:00"),
        user:
      )
    ]
  end

  let(:patient_session) do
    create(
      :patient_session,
      patient:,
      session:,
      created_at: Time.zone.parse("2024-05-29 12:00")
    )
  end
  let(:component) { described_class.new(patient_session) }

  before { render_inline(component) }

  subject { page }

  it "renders headings in correct order" do
    expect(page).to have_css("h2:nth-of-type(1)", text: "31 May 2024")
    expect(page).to have_css("h2:nth-of-type(2)", text: "30 May 2024")
    expect(page).to have_css("h2:nth-of-type(3)", text: "29 May 2024")
  end

  include_examples "card",
                   title: "Vaccinated with Gardasil 9 (HPV)",
                   date: "31 May 2024 at 12:00pm",
                   by: "Nurse Joy"

  include_examples "card",
                   title: "Triaged decision: Safe to vaccinate",
                   date: "30 May 2024 at 2:30pm",
                   by: "Nurse Joy"

  include_examples "card",
                   title: "Triaged decision: Needs triage",
                   date: "30 May 2024 at 2:00pm",
                   by: "Nurse Joy"

  include_examples "card",
                   title: "Consent refused by John Doe (Dad)",
                   date: "30 May 2024 at 1:00pm"

  include_examples "card",
                   title: "Consent given by Jane Doe (Mum)",
                   date: "30 May 2024 at 12:00pm"

  include_examples "card",
                   title: "Invited to session at Hogwarts",
                   date: "29 May 2024 at 12:00pm",
                   by: "Nurse Joy"
end
