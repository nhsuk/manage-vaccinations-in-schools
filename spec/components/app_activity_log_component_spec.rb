# frozen_string_literal: true

require "rails_helper"

shared_examples "card" do |params|
  title, date, notes, by = params.values_at(:title, :date, :notes, :by)
  it "renders card '#{title}'" do
    expect(subject).to have_css(".nhsuk-card h3", text: title)

    card = subject.find(".nhsuk-card h3", text: title).ancestor(".nhsuk-card")
    expect(card).to have_css("p", text: date)
    expect(card).to have_css("blockquote", text: notes) if notes
    expect(card).to have_css("p", text: by) if by
  end
end

describe AppActivityLogComponent, type: :component do
  subject { page }

  let(:team) { create(:team) }
  let(:patient_session) do
    create(
      :patient_session,
      patient:,
      session:,
      created_at: Time.zone.parse("2024-05-29 12:00"),
      created_by: user
    )
  end
  let(:component) { described_class.new(patient_session) }
  let(:user) { create(:user, teams: [team], full_name: "Nurse Joy") }
  let(:campaign) { create(:campaign, team:) }
  let(:location) { create(:location, name: "Hogwarts") }
  let(:session) { create(:session, campaign:, location:) }
  let(:patient) { create(:patient, location:) }

  before do
    create(
      :consent,
      :given,
      :from_mum,
      campaign:,
      patient:,
      parent: create(:parent, :mum, name: "Jane Doe"),
      recorded_at: Time.zone.parse("2024-05-30 12:00")
    )
    create(
      :consent,
      :refused,
      :from_dad,
      campaign:,
      patient:,
      parent: create(:parent, :dad, name: "John Doe"),
      recorded_at: Time.zone.parse("2024-05-30 13:00")
    )

    create(
      :triage,
      :needs_follow_up,
      patient_session:,
      created_at: Time.zone.parse("2024-05-30 14:00"),
      notes: "Some notes",
      user:
    )
    create(
      :triage,
      :ready_to_vaccinate,
      patient_session:,
      created_at: Time.zone.parse("2024-05-30 14:30"),
      user:
    )

    create(
      :vaccination_record,
      patient_session:,
      created_at: Time.zone.parse("2024-05-31 12:00"),
      user:,
      notes: "Some notes"
    )
    render_inline(component)
  end

  it "renders headings in correct order" do
    expect(subject).to have_css("h2:nth-of-type(1)", text: "31 May 2024")
    expect(subject).to have_css("h2:nth-of-type(2)", text: "30 May 2024")
    expect(subject).to have_css("h2:nth-of-type(3)", text: "29 May 2024")
  end

  include_examples "card",
                   title: "Vaccinated with Cervarix (HPV)",
                   date: "31 May 2024 at 12:00pm",
                   notes: "Some notes",
                   by: "Nurse Joy"

  include_examples "card",
                   title: "Triaged decision: Safe to vaccinate",
                   date: "30 May 2024 at 2:30pm",
                   by: "Nurse Joy"

  include_examples "card",
                   title: "Triaged decision: Keep in triage",
                   date: "30 May 2024 at 2:00pm",
                   notes: "Some notes",
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
